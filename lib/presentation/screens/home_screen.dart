// Datei: lib/view/home_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';
import 'package:jugend_app/data/models/user_profile.dart';
import 'package:jugend_app/domain/viewmodels/friend_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return riverpod.Consumer(
      builder: (context, ref, _) {
        final auth = ref.watch(authViewModelProvider);
        final viewModel = ref.read(authViewModelProvider.notifier);
        if (auth.status == AuthStatus.signedIn && auth.profile != null) {
          return StreamBuilder(
            stream: viewModel.userProfileStream(auth.profile!.uid),
            builder: (context, snapshot) {
              final profile = snapshot.data ?? auth.profile!;
              return _buildScaffold(context, l10n, auth, profile, ref);
            },
          );
        } else {
          return _buildScaffold(context, l10n, auth, null, ref);
        }
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    AppLocalizations l10n,
    AuthState auth,
    UserProfile? profile,
    riverpod.WidgetRef ref,
  ) {
    final friendViewModel = ref.watch(friendViewModelProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          if (auth.status == AuthStatus.signedIn)
            IconButton(
              icon:
                  (profile?.photoUrl != null && profile!.photoUrl!.isNotEmpty)
                      ? CircleAvatar(
                        backgroundImage: NetworkImage(profile.photoUrl!),
                        radius: 16,
                      )
                      : const Icon(Icons.account_circle),
              tooltip: 'Profil',
              onPressed: () => context.go('/profile'),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 2;
          if (constraints.maxWidth < 500) {
            crossAxisCount = 1;
          } else if (constraints.maxWidth > 900) {
            crossAxisCount = 3;
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final tiles = [
                  _HubTile(
                    label: 'Games',
                    icon: Icons.videogame_asset,
                    onTap: () => context.go('/games'),
                  ),
                  _HubTile(
                    label: l10n.labelPlayers,
                    icon: Icons.group,
                    onTap: () => context.go('/lobbies'),
                  ),
                  _HubTile(
                    label: 'Freunde',
                    icon: Icons.people_outline,
                    onTap: () => _onFriendsTap(context, auth),
                  ),
                  _HubTile(
                    label: 'Feedback',
                    icon: Icons.feedback_outlined,
                    onTap: () => context.go('/feedback'),
                  ),
                ];
                return tiles[index];
              },
            ),
          );
        },
      ),
    );
  }

  void _onFriendsTap(BuildContext context, AuthState auth) async {
    if (auth.status == AuthStatus.signedIn) {
      context.go('/friends');
      return;
    }
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Login erforderlich'),
            content: const Text(
              'Dieses Feature funktioniert nur, wenn du eingeloggt bist. Jetzt einloggen?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Nein'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ja, einloggen'),
              ),
            ],
          ),
    );
    if (result == true) {
      if (!context.mounted) return;
      context.go('/auth');
    }
  }
}

class _HubTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int notificationCount;

  const _HubTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 48),
                  if (notificationCount > 0)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
