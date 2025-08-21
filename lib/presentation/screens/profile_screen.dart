import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authViewModelProvider);
    final viewModel = ref.read(authViewModelProvider.notifier);
    final profile = state.profile;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showSignOutDialog(context, viewModel),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _pickImage(context, viewModel),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                            ? NetworkImage(profile.photoUrl!)
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
              profile.displayName ?? '',
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
              onTap: () => _showNameDialog(context, viewModel),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Account löschen'),
              onTap: () => _showDeleteAccountDialog(context, viewModel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, AuthViewModel viewModel) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        await viewModel.updateProfile(photoUrl: pickedFile.path);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  void _showNameDialog(BuildContext context, AuthViewModel viewModel) {
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
                    await viewModel.updateProfile(displayName: controller.text);
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

  void _showSignOutDialog(BuildContext context, AuthViewModel viewModel) {
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

  void _showDeleteAccountDialog(BuildContext context, AuthViewModel viewModel) {
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
                    await viewModel.deleteAccountAndData();
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
