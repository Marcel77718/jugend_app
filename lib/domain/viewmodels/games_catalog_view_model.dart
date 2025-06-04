import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/data/repositories/games_repository.dart';

final gamesCatalogProvider = FutureProvider<List<GameInfo>>((ref) async {
  final repo = ref.watch(gamesRepositoryProvider);
  return await repo.loadGames();
});

final gameDetailProvider = FutureProvider.family<GameInfo?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(gamesRepositoryProvider);
  return await repo.getGameById(id);
});
