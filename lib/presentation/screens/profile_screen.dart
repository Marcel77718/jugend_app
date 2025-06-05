import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jugend_app/main.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isUploading = false;
  String? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _selectedLocale = 'de';
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(source: source, imageQuality: 70);
      if (picked == null) return;
      setState(() => _isUploading = true);
      try {
        final file = File(picked.path);
        final refStorage = FirebaseStorage.instance.ref().child(
          'avatars/$uid.jpg',
        );
        try {
          await refStorage.delete();
        } catch (e) {
          // Bild existiert nicht – kein Problem
        }
        try {
          await refStorage.putFile(file);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Fehler beim Hochladen (putFile): $e')),
            );
          }
          setState(() => _isUploading = false);
          return;
        }
        String url;
        try {
          url = await refStorage.getDownloadURL();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fehler beim Abrufen der Download-URL: $e'),
              ),
            );
          }
          setState(() => _isUploading = false);
          return;
        }
        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'photoUrl': url,
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fehler beim Speichern des Profilbild-Links: $e'),
              ),
            );
          }
          setState(() => _isUploading = false);
          return;
        }
        if (mounted) {
          setState(() {}); // Soft-Refresh
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Fehler beim Hochladen: $e')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Auswählen des Bildes: $e')),
        );
      }
    }
    if (mounted) setState(() => _isUploading = false);
  }

  Future<void> _updateName(String uid, String newName) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'displayName': newName,
    });
    if (!mounted) return;
    setState(() {}); // Soft-Refresh
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Account löschen'),
            content: const Text(
              'Bist du sicher? Dieser Vorgang kann nicht rückgängig gemacht werden!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Löschen'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      try {
        await ref.read(authViewModelProvider.notifier).deleteAccountAndData();
        if (mounted) _showAccountDeletedSnackbar();
      } catch (e) {
        if (mounted) _showDeleteErrorSnackbar(e);
      }
    }
  }

  void _changeLocale(String? locale) {
    setState(() => _selectedLocale = locale);
    if (locale != null) {
      ref.read(localeProvider.notifier).state = Locale(locale);
    }
  }

  void _showAccountDeletedSnackbar() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Account gelöscht.')));
  }

  void _showDeleteErrorSnackbar(Object e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Fehler beim Löschen: $e')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final viewModel = ref.read(authViewModelProvider.notifier);
    final user = auth.profile;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _nameController.text = user.displayName ?? '';
    return StreamBuilder(
      stream: viewModel.userProfileStream(user.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? user;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.go('/');
              },
            ),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage:
                            (profile.photoUrl != null &&
                                    profile.photoUrl!.isNotEmpty)
                                ? NetworkImage(profile.photoUrl!)
                                : const NetworkImage(
                                  'https://ui-avatars.com/api/?name=User',
                                ),
                        child: null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon:
                              _isUploading
                                  ? const CircularProgressIndicator()
                                  : const Icon(Icons.edit),
                          onPressed:
                              _isUploading
                                  ? null
                                  : () async {
                                    await _showImageSourceDialog(profile.uid);
                                    if (!mounted) return;
                                  },
                          tooltip: 'Avatar ändern',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _isEditingName
                      ? Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () async {
                              await _updateName(
                                profile.uid,
                                _nameController.text.trim(),
                              );
                              if (!mounted) return;
                              setState(() => _isEditingName = false);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed:
                                () => setState(() => _isEditingName = false),
                          ),
                        ],
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            (profile.displayName ?? 'Kein Name') +
                                (profile.tag.isNotEmpty
                                    ? '#${profile.tag}'
                                    : ''),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            tooltip: 'Name#Tag kopieren',
                            onPressed: () {
                              final text =
                                  (profile.displayName ?? 'Kein Name') +
                                  (profile.tag.isNotEmpty
                                      ? '#${profile.tag}'
                                      : '');
                              Clipboard.setData(ClipboardData(text: text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Name#Tag kopiert!'),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed:
                                () => setState(() => _isEditingName = true),
                          ),
                        ],
                      ),
                  const SizedBox(height: 16),
                  Text(
                    profile.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    onPressed: () => viewModel.signOut(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Account löschen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => _deleteAccount(context),
                  ),
                  const SizedBox(height: 16),
                  if ((profile.provider ?? '').contains('password'))
                    ElevatedButton.icon(
                      icon: const Icon(Icons.lock),
                      label: const Text('Passwort ändern'),
                      onPressed: () async {
                        final controller = TextEditingController();
                        final result = await showDialog<String>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Passwort ändern'),
                                content: TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    labelText: 'Neues Passwort',
                                  ),
                                  obscureText: true,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Abbrechen'),
                                  ),
                                  ElevatedButton(
                                    onPressed:
                                        () => Navigator.pop(
                                          context,
                                          controller.text.trim(),
                                        ),
                                    child: const Text('Ändern'),
                                  ),
                                ],
                              ),
                        );
                        if (!mounted) return;
                        if (result != null && result.length >= 6) {
                          if (!context.mounted) return;
                          final messenger = ScaffoldMessenger.of(context);
                          await ref
                              .read(authViewModelProvider.notifier)
                              .changePassword(result);
                          final authState = ref.read(authViewModelProvider);
                          if (authState.error == 'pwchange_success') {
                            messenger.clearSnackBars();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Passwort geändert.'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            ref
                                .read(authViewModelProvider.notifier)
                                .clearError();
                          } else if (authState.error == 'pwchange_failed') {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Fehler beim Ändern des Passworts.',
                                ),
                              ),
                            );
                            ref
                                .read(authViewModelProvider.notifier)
                                .clearError();
                          }
                        }
                      },
                    ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.language),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedLocale,
                        items: const [
                          DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                          DropdownMenuItem(value: 'en', child: Text('English')),
                        ],
                        onChanged: _changeLocale,
                      ),
                      const SizedBox(width: 8),
                      const Text('Sprache'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
