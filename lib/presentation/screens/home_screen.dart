// Datei: lib/view/home_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
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
                    onTap: () => _showComingSoon(context),
                  ),
                  _HubTile(
                    label: l10n.labelPlayers,
                    icon: Icons.group,
                    onTap: () => context.go('/lobbies'),
                  ),
                  _HubTile(
                    label: 'Freunde',
                    icon: Icons.people_outline,
                    onTap: () => _showComingSoon(context),
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

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Noch nicht verfügbar'),
            content: const Text(
              'Dieses Feature wird in einem zukünftigen Update verfügbar sein.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
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
              Icon(icon, size: 48),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
