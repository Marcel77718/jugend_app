import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/data/models/user_profile.dart';
import 'package:jugend_app/services/image_service.dart';

final userProfileProvider = StreamProvider<UserProfile>((ref) {
  final authState = ref.watch(authViewModelProvider);
  if (authState.profile == null) {
    return Stream.value(
      UserProfile(uid: '', createdAt: DateTime.now(), tag: '0000'),
    );
  }
  return FirebaseFirestore.instance
      .collection('users')
      .doc(authState.profile!.uid)
      .snapshots()
      .map((doc) => UserProfile.fromFirestore(doc));
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController.text =
        ref.read(authViewModelProvider).profile?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog(String uid) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Profilbild ändern'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                child: const ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Aus Galerie wählen'),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                child: const ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Foto aufnehmen'),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, null),
                child: const ListTile(
                  leading: Icon(Icons.cancel),
                  title: Text('Abbrechen'),
                ),
              ),
            ],
          ),
    );
    if (!mounted) return;
    if (source != null) {
      await _pickAndUploadAvatar(uid, source);
    }
  }

  Future<void> _pickAndUploadAvatar(String uid, ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null) return;
      if (!mounted) return;
      setState(() => _isUploadingImage = true);
      try {
        final file = File(picked.path);
        final refStorage = FirebaseStorage.instance.ref().child(
          'avatars/$uid.jpg',
        );

        // Lösche altes Bild aus dem Cache
        try {
          await ImageService.instance.clearCache();
        } catch (e) {
          // Bild existiert nicht – kein Problem
        }

        try {
          await refStorage.delete();
        } catch (e) {
          // Bild existiert nicht – kein Problem
        }

        try {
          await refStorage.putFile(
            file,
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {'compressed': 'true'},
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Hochladen (putFile): $e')),
          );
          setState(() => _isUploadingImage = false);
          return;
        }

        String url;
        try {
          url = await refStorage.getDownloadURL();
          // Vorladen des neuen Bildes
          await ImageService.instance.preloadImage(url);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Abrufen der Download-URL: $e')),
          );
          setState(() => _isUploadingImage = false);
          return;
        }

        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'photoUrl': url,
          });
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Speichern des Profilbild-Links: $e'),
            ),
          );
          setState(() => _isUploadingImage = false);
          return;
        }

        if (!mounted) return;
        setState(() {}); // Soft-Refresh
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Hochladen: $e')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Auswählen des Bildes: $e')),
      );
    }
    if (!mounted) return;
    setState(() => _isUploadingImage = false);
  }

  Future<void> _updateName(String uid, String newName) async {
    if (newName.isEmpty) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'displayName': newName,
    });
    if (!mounted) return;
    setState(() {}); // Soft-Refresh
  }

  Future<void> _onLogout() async {
    try {
      await ref.read(authViewModelProvider.notifier).signOut();
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Abmelden'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onDeleteAccount() async {
    try {
      await ref.read(authViewModelProvider.notifier).deleteAccountAndData();
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Löschen des Kontos'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider);
    if (user.status == AuthStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user.status == AuthStatus.signedOut) {
      return const Scaffold(body: Center(child: Text('Bitte melde dich an')));
    }

    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, stack) =>
              Scaffold(body: Center(child: Text('Fehler: $error'))),
      data:
          (profile) => Scaffold(
            appBar: AppBar(
              title: const Text('Profil'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _showImageSourceDialog(profile.uid),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              profile.photoUrl != null
                                  ? NetworkImage(profile.photoUrl!)
                                  : null,
                          child:
                              profile.photoUrl == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                        ),
                        if (_isUploadingImage)
                          const Positioned.fill(
                            child: CircularProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    profile.displayName ?? 'Kein Name',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '#${profile.tag}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Namen ändern'),
                    onTap: () => _showNameChangeDialog(context, profile),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Passwort ändern'),
                    onTap: () => _showPasswordChangeDialog(context),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _onLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Abmelden'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Konto löschen',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Konto löschen'),
                              content: const Text(
                                'Bist du sicher, dass du dein Konto löschen möchtest? Diese Aktion kann nicht rückgängig gemacht werden.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Abbrechen'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _onDeleteAccount();
                                  },
                                  child: const Text(
                                    'Löschen',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _showNameChangeDialog(
    BuildContext context,
    UserProfile profile,
  ) async {
    final controller = TextEditingController(text: profile.displayName);
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Namen ändern'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Neuer Name',
                  hintText: 'Gib deinen neuen Namen ein',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte gib einen Namen ein';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    await _updateName(profile.uid, controller.text);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  }
                },
                child: const Text('Speichern'),
              ),
            ],
          ),
    );
  }

  Future<void> _showPasswordChangeDialog(BuildContext context) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Passwort ändern'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Aktuelles Passwort',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte gib dein aktuelles Passwort ein';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Neues Passwort',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte gib ein neues Passwort ein';
                      }
                      if (value.length < 6) {
                        return 'Das Passwort muss mindestens 6 Zeichen lang sein';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Neues Passwort bestätigen',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value != newPasswordController.text) {
                        return 'Die Passwörter stimmen nicht überein';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Erst prüfen, ob das Formular okay ist
                  if (!(formKey.currentState?.validate() ?? false)) return;

                  // ► Kontext-abhängige Objekte VOR dem await zwischenspeichern
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final errorColor = Theme.of(context).colorScheme.error;

                  try {
                    // Async-Operation
                    await ref
                        .read(authViewModelProvider.notifier)
                        .changePassword(
                          currentPasswordController.text,
                          newPasswordController.text,
                        );

                    if (!context.mounted) return;

                    navigator.pop(); // kein BuildContext mehr nötig
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Passwort erfolgreich geändert'),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Fehler beim Ändern des Passworts: $e'),
                        backgroundColor: errorColor,
                      ),
                    );
                  }
                },
                child: const Text('Speichern'),
              ),
            ],
          ),
    );
  }
}
