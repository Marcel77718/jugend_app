// Datei: lib/router.dart

import 'package:go_router/go_router.dart';
import 'package:jugend_app/view/home_screen.dart';
import 'package:jugend_app/view/lobby_hub_screen.dart';
import 'package:jugend_app/view/lobby_create_screen.dart';
import 'package:jugend_app/view/lobby_join_screen.dart';
import 'package:jugend_app/view/lobby_screen.dart';
import 'package:jugend_app/model/reconnect_data.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
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
  ],
);
