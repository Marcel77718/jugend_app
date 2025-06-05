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
import 'package:jugend_app/presentation/screens/auth_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';
import 'package:jugend_app/presentation/screens/profile_screen.dart';
import 'package:jugend_app/presentation/screens/friends_screen.dart';
import 'package:jugend_app/core/app_routes.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return riverpod.Consumer(
      builder: (context, ref, _) {
        final auth = ref.watch(authViewModelProvider);
        if (auth.status == AuthStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.status == AuthStatus.signedOut) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ModalRoute.of(context)?.settings.name != '/auth') {
              GoRouter.of(context).go('/auth');
            }
          });
          return const SizedBox.shrink();
        }
        return child;
      },
    );
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.reconnect,
  routes: [
    GoRoute(
      path: AppRoutes.reconnect,
      pageBuilder:
          (context, state) => _fadeTransitionPage(const ReconnectScreen()),
    ),
    GoRoute(
      path: AppRoutes.home,
      pageBuilder: (context, state) => _fadeTransitionPage(const HomeScreen()),
    ),
    GoRoute(
      path: AppRoutes.lobbies,
      pageBuilder:
          (context, state) => _fadeTransitionPage(const LobbyHubScreen()),
    ),
    GoRoute(
      path: AppRoutes.lobbyCreate,
      pageBuilder:
          (context, state) => _fadeTransitionPage(const LobbyCreateScreen()),
    ),
    GoRoute(
      path: AppRoutes.lobbyJoin,
      pageBuilder:
          (context, state) => _fadeTransitionPage(const LobbyJoinScreen()),
    ),
    GoRoute(
      path: AppRoutes.lobby,
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
                        context: context,
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
      path: AppRoutes.game,
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
                        context: context,
                      ),
            child: const GameScreen(),
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.gameSettings,
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
                        context: context,
                      ),
            child: const GameSettingsScreen(),
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.feedback,
      pageBuilder:
          (context, state) => _fadeTransitionPage(const FeedbackScreen()),
    ),
    GoRoute(
      path: AppRoutes.games,
      pageBuilder:
          (context, state) => _fadeTransitionPage(const GamesCatalogScreen()),
    ),
    GoRoute(
      path: '${AppRoutes.games}/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'];
        if (id == null) {
          return _fadeTransitionPage(const GamesCatalogScreen());
        }
        return _fadeTransitionPage(GameDetailScreen(gameId: id));
      },
    ),
    GoRoute(
      path: AppRoutes.auth,
      pageBuilder: (context, state) => _fadeTransitionPage(const AuthScreen()),
    ),
    GoRoute(
      path: AppRoutes.friends,
      pageBuilder:
          (context, state) =>
              _fadeTransitionPage(AuthGuard(child: const FriendsScreen())),
    ),
    GoRoute(
      path: AppRoutes.profile,
      pageBuilder:
          (context, state) =>
              _fadeTransitionPage(AuthGuard(child: const ProfileScreen())),
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
