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
import 'package:jugend_app/data/repositories/lobby_repository.dart';
import 'package:flutter/material.dart';
import 'package:jugend_app/presentation/screens/feedback_screen.dart';
import 'package:jugend_app/presentation/screens/games_catalog_screen.dart';
import 'package:jugend_app/presentation/screens/game_detail_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/reconnect',
  routes: [
    GoRoute(
      path: '/reconnect',
      pageBuilder:
          (context, state) => _fadeTransitionPage(const ReconnectScreen()),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _fadeTransitionPage(const HomeScreen()),
    ),
    GoRoute(
      path: '/lobbies',
      pageBuilder:
          (context, state) => _fadeTransitionPage(const LobbyHubScreen()),
    ),
    GoRoute(
      path: '/lobbies/create',
      pageBuilder:
          (context, state) => _fadeTransitionPage(const LobbyCreateScreen()),
    ),
    GoRoute(
      path: '/lobbies/join',
      pageBuilder:
          (context, state) => _fadeTransitionPage(const LobbyJoinScreen()),
    ),
    GoRoute(
      path: '/lobby',
      pageBuilder: (context, state) {
        final data = state.extra as ReconnectData;
        return _fadeTransitionPage(
          ChangeNotifierProvider(
            create:
                (_) =>
                    LobbyViewModel(lobbyRepository: LobbyRepository())
                      ..initialize(
                        lobbyId: data.lobbyId,
                        playerName: data.playerName,
                        isHost: data.isHost,
                        gameType: data.gameType,
                      ),
            child: LobbyScreen(
              lobbyId: data.lobbyId,
              playerName: data.playerName,
              isHost: data.isHost,
              gameType: data.gameType,
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: '/game',
      pageBuilder: (context, state) {
        final data = state.extra;
        if (data is! ReconnectData) {
          // Fallback: Weiterleitung auf Startseite
          return _fadeTransitionPage(const HomeScreen());
        }
        return _fadeTransitionPage(
          ChangeNotifierProvider(
            create:
                (_) =>
                    LobbyViewModel(lobbyRepository: LobbyRepository())
                      ..initialize(
                        lobbyId: data.lobbyId,
                        playerName: data.playerName,
                        isHost: data.isHost,
                        gameType: data.gameType,
                      ),
            child: const GameScreen(),
          ),
        );
      },
    ),
    GoRoute(
      path: '/game-settings',
      pageBuilder: (context, state) {
        final data = state.extra;
        if (data is! ReconnectData) {
          return _fadeTransitionPage(const HomeScreen());
        }
        return _fadeTransitionPage(
          ChangeNotifierProvider(
            create:
                (_) =>
                    LobbyViewModel(lobbyRepository: LobbyRepository())
                      ..initialize(
                        lobbyId: data.lobbyId,
                        playerName: data.playerName,
                        isHost: data.isHost,
                        gameType: data.gameType,
                      ),
            child: const GameSettingsScreen(),
          ),
        );
      },
    ),
    GoRoute(
      path: '/feedback',
      pageBuilder:
          (context, state) => _fadeTransitionPage(const FeedbackScreen()),
    ),
    GoRoute(
      path: '/games',
      pageBuilder:
          (context, state) => _fadeTransitionPage(const GamesCatalogScreen()),
    ),
    GoRoute(
      path: '/games/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'];
        if (id == null) {
          return _fadeTransitionPage(const GamesCatalogScreen());
        }
        return _fadeTransitionPage(GameDetailScreen(gameId: id));
      },
    ),
  ],
);

CustomTransitionPage _fadeTransitionPage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
