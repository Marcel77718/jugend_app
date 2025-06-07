import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/domain/viewmodels/games_catalog_view_model.dart';

class GameDetailScreen extends ConsumerWidget {
  final String gameId;

  const GameDetailScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameDetailProvider(gameId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spiel-Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/games'),
        ),
      ),
      body: gameAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, _) => Center(
              child: Text(
                'Fehler beim Laden: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
        data: (game) {
          if (game == null) {
            return const Center(child: Text('Spiel nicht gefunden.'));
          }

          final imagePath =
              'assets/images/games/${game.iconName ?? 'default.png'}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'game-icon-${game.id}',
                  child: Center(
                    child: Image.asset(
                      imagePath,
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (c, o, s) =>
                              const Icon(Icons.videogame_asset, size: 120),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  game.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  game.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Text('Regeln', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(game.rules, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                Text('Rollen', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      game.roles.map((role) {
                        return Chip(label: Text(role));
                      }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
