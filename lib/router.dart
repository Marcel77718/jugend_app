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
import 'package:jugend_app/domain/viewmodels/lobby_view_model.dart';
import 'package:jugend_app/data/repositories/lobby_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as p;
import 'package:jugend_app/presentation/screens/feedback_screen.dart';
import 'package:jugend_app/presentation/screens/games_catalog_screen.dart';
import 'package:jugend_app/presentation/screens/game_detail_screen.dart';
import 'package:jugend_app/presentation/screens/auth_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';
import 'package:jugend_app/presentation/screens/profile_screen.dart';
import 'package:jugend_app/presentation/screens/friends_screen.dart';

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
        final viewModel = LobbyViewModel(lobbyRepository: LobbyRepository());
        return _fadeTransitionPage(
          LobbyScreen(
            lobbyId: data.lobbyId,
            playerName: data.playerName,
            isHost: data.isHost,
            gameType: data.gameType,
            viewModel: viewModel,
          ),
        );
      },
    ),
    GoRoute(
      path: '/game',
      pageBuilder: (context, state) {
        final extra = state.extra;
        if (extra is! LobbyViewModel) {
          return _fadeTransitionPage(const HomeScreen());
        }
        return _fadeTransitionPage(
          p.ChangeNotifierProvider.value(
            value: extra,
            child: const GameScreen(),
          ),
        );
      },
    ),
    GoRoute(
      path: '/game-settings',
      pageBuilder: (context, state) {
        final extra = state.extra;
        if (extra is! LobbyViewModel) {
          return _fadeTransitionPage(const HomeScreen());
        }
        return _fadeTransitionPage(
          p.ChangeNotifierProvider.value(
            value: extra,
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
    GoRoute(
      path: '/auth',
      pageBuilder: (context, state) => _fadeTransitionPage(const AuthScreen()),
    ),
    GoRoute(
      path: '/friends',
      pageBuilder:
          (context, state) =>
              _fadeTransitionPage(AuthGuard(child: const FriendsScreen())),
    ),
    GoRoute(
      path: '/profile',
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
