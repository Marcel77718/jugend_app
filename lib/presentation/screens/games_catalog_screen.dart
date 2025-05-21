import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/games_catalog_view_model.dart';
import 'package:jugend_app/data/repositories/games_repository.dart';
import 'package:go_router/go_router.dart';

class GamesCatalogScreen extends ConsumerWidget {
  const GamesCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(gamesCatalogProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spiele-Katalog'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Zurück zum Hub',
          onPressed: () => context.go('/'),
        ),
      ),
      body: gamesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, _) => Center(
              child: Text(
                'Fehler beim Laden: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
        data: (games) {
          if (games.isEmpty) {
            return const Center(child: Text('Keine Spiele gefunden.'));
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 2;
              if (constraints.maxWidth > 900)
                crossAxisCount = 4;
              else if (constraints.maxWidth > 600)
                crossAxisCount = 3;
              else if (constraints.maxWidth < 400)
                crossAxisCount = 1;
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: games.length,
                itemBuilder: (context, i) {
                  final game = games[i];
                  return _GameCard(game: game, colorScheme: colorScheme);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameInfo game;
  final ColorScheme colorScheme;
  const _GameCard({required this.game, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final imagePath = 'assets/images/games/${game.iconName ?? 'default.png'}';
    return Semantics(
      label: 'Spiel: ${game.name}',
      button: true,
      child: Hero(
        tag: 'game-icon-${game.id}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.go('/games/${game.id}'),
            child: Ink(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (c, o, s) =>
                                const Icon(Icons.videogame_asset, size: 48),
                        semanticLabel: '${game.name} Icon',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      game.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      game.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
