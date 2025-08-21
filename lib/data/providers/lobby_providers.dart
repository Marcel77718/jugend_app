import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/data/repositories/lobby_repository.dart';

final lobbyRepositoryProvider = Provider<ILobbyRepository>((ref) {
  return LobbyRepository();
});
