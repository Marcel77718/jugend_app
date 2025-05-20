// Datei: lib/router.dart

import 'package:go_router/go_router.dart';
import 'package:jugend_app/presentation/screens/home_screen.dart';
import 'package:jugend_app/presentation/screens/lobby_hub_screen.dart';
import 'package:jugend_app/presentation/screens/lobby_create_screen.dart';
import 'package:jugend_app/presentation/screens/lobby_join_screen.dart';
import 'package:jugend_app/presentation/screens/lobby_screen.dart';
import 'package:jugend_app/data/models/reconnect_data.dart';
import 'package:jugend_app/presentation/screens/reconnect_screen.dart';
import 'package:jugend_app/presentation/screens/game_screen.dart';
import 'package:jugend_app/presentation/screens/game_settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:jugend_app/domain/viewmodels/lobby_view_model.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/reconnect',
  routes: [
    GoRoute(
      path: '/reconnect',
      builder: (context, state) => const ReconnectScreen(),
    ),
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/lobbies',
      builder: (context, state) => const LobbyHubScreen(),
    ),
    GoRoute(
      path: '/lobbies/create',
      builder: (context, state) => const LobbyCreateScreen(),
    ),
    GoRoute(
      path: '/lobbies/join',
      builder: (context, state) => const LobbyJoinScreen(),
    ),
    GoRoute(
      path: '/lobby',
      builder: (context, state) {
        final data = state.extra as ReconnectData;
        return LobbyScreen(
          lobbyId: data.lobbyId,
          playerName: data.playerName,
          isHost: data.isHost,
          gameType: data.gameType,
        );
      },
    ),
    GoRoute(path: '/game', builder: (context, state) => const GameScreen()),
    GoRoute(
      path: '/game-settings',
      builder: (context, state) {
        final data = state.extra as ReconnectData;
        return ChangeNotifierProvider(
          create:
              (_) =>
                  LobbyViewModel()..initialize(
                    lobbyId: data.lobbyId,
                    playerName: data.playerName,
                    isHost: data.isHost,
                    gameType: data.gameType,
                  ),
          child: const GameSettingsScreen(),
        );
      },
    ),
  ],
);
