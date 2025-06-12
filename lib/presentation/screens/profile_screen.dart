import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/profile_view_model.dart';
import 'dart:io';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: const ProfileScreenContent(),
    );
  }
}

class ProfileScreenContent extends StatelessWidget {
  const ProfileScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showSignOutDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<ProfileData>(
        stream: viewModel.profileStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Fehler: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _pickImage(context),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            profile.photoUrl.isNotEmpty
                                ? NetworkImage(profile.photoUrl)
                                : const NetworkImage(
                                  'https://ui-avatars.com/api/?name=User',
                                ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '@${profile.tag}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 40),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Name ändern'),
                  onTap: () => _showNameDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Account löschen'),
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final viewModel = context.read<ProfileViewModel>();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        await viewModel.updateProfilePicture(File(pickedFile.path));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  void _showNameDialog(BuildContext context) {
    final viewModel = context.read<ProfileViewModel>();
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Name ändern'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Neuer Name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await viewModel.updateName(controller.text);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                child: const Text('Speichern'),
              ),
            ],
          ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    final viewModel = context.read<ProfileViewModel>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ausloggen'),
            content: const Text('Möchtest du dich wirklich ausloggen?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () async {
                  await viewModel.signOut();
                  if (context.mounted) {
                    Navigator.pop(context);
                    context.go('/auth');
                  }
                },
                child: const Text('Ausloggen'),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final viewModel = context.read<ProfileViewModel>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Account löschen'),
            content: const Text(
              'Möchtest du deinen Account wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await viewModel.deleteAccount();
                    if (context.mounted) {
                      Navigator.pop(context);
                      context.go('/auth');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                child: const Text(
                  'Löschen',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
