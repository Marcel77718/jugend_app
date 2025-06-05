import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/games_catalog_view_model.dart';
import 'package:go_router/go_router.dart';

class GameDetailScreen extends ConsumerWidget {
  final String gameId;
  const GameDetailScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameDetailProvider(gameId));
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spiel Details'),
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
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final content = <Widget>[
                Hero(
                  tag: 'game-icon-${game.id}',
                  child: Image.asset(
                    imagePath,
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (c, o, s) =>
                            const Icon(Icons.videogame_asset, size: 80),
                    semanticLabel: '${game.name} Icon',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  game.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  game.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text('Regeln', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(game.rules, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                Text('Rollen', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      game.roles
                          .map(
                            (role) => Chip(
                              label: Text(role),
                              backgroundColor: colorScheme.secondaryContainer,
                            ),
                          )
                          .toList(),
                ),
              ];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child:
                      isWide
                          ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: content[0]),
                              const SizedBox(width: 32),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: content.sublist(1),
                                ),
                              ),
                            ],
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: content,
                          ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
