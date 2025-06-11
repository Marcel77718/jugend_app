// Datei: lib/view/home_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';
import 'package:jugend_app/data/models/user_profile.dart';
import 'package:jugend_app/core/performance_monitor.dart';
import 'package:jugend_app/core/widget_optimizer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return riverpod.Consumer(
      builder: (context, ref, _) {
        final auth = ref.watch(authViewModelProvider);
        ref.read(authViewModelProvider.notifier);
        final profile = ref.watch(userProfileProvider(auth.profile?.uid));

        return _buildScaffold(
          context,
          l10n,
          auth,
          profile.value ?? auth.profile,
          ref,
        );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          if (auth.status == AuthStatus.signedIn)
            PerformanceWidget(
              name: 'ProfileButton',
              child: IconButton(
                icon:
                    profile?.photoUrl != null
                        ? CircleAvatar(
                          backgroundImage: NetworkImage(profile!.photoUrl!),
                          radius: 16,
                        )
                        : const Icon(Icons.account_circle),
                tooltip: 'Profil',
                onPressed: () => context.go('/profile'),
              ),
            ),
        ],
      ),
      body: PerformanceWidget(
        name: 'HomeContent',
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 2;
            if (constraints.maxWidth < 500) {
              crossAxisCount = 1;
            } else if (constraints.maxWidth > 900) {
              crossAxisCount = 3;
            }
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: WidgetOptimizer.optimizedGridView(
                name: 'HomeMenu',
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
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
                ],
              ),
            );
          },
        ),
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
          (context) => PerformanceWidget(
            name: 'LoginRequiredDialog',
            child: AlertDialog(
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

  const _HubTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PerformanceWidget(
      name: 'HubTile_$label',
      child: InkWell(
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
                  children: [Icon(icon, size: 48)],
                ),
                const SizedBox(height: 8),
                Text(label, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
