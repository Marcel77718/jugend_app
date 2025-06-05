// Datei: lib/view/lobby_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/core/app_routes.dart';

class LobbyHubScreen extends StatefulWidget {
  const LobbyHubScreen({super.key});

  @override
  State<LobbyHubScreen> createState() => _LobbyHubScreenState();
}

class _LobbyHubScreenState extends State<LobbyHubScreen> {
  bool _createCooldown = false;

  void _startCreateCooldown() {
    setState(() {
      _createCooldown = true;
    });
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _createCooldown = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => GoRouter.of(context).go(AppRoutes.home),
        ),
        title: const Text('Lobbies'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed:
                  _createCooldown
                      ? null
                      : () {
                        _startCreateCooldown();
                        GoRouter.of(context).go(AppRoutes.lobbyCreate);
                      },
              child:
                  _createCooldown
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Spiel erstellen'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => GoRouter.of(context).go(AppRoutes.lobbyJoin),
              child: const Text('Spiel beitreten'),
            ),
          ],
        ),
      ),
    );
  }
}
