// Datei: lib/view/lobby_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LobbyHubScreen extends StatelessWidget {
  const LobbyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: const Text('Lobbies'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/lobbies/create'),
              child: const Text('Spiel erstellen'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/lobbies/join'),
              child: const Text('Spiel beitreten'),
            ),
          ],
        ),
      ),
    );
  }
}
