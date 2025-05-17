// Datei: lib/view/game_entry_choice_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GameEntryChoiceScreen extends StatelessWidget {
  const GameEntryChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spiel auswählen')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Impostor'),
            onTap: () => context.go('/impostor-lobby'),
          ),
          ListTile(
            title: const Text('Werwolf'),
            onTap: () => context.go('/werwolf-lobby'),
          ),
          ListTile(
            title: const Text('Palermo'),
            onTap: () => context.go('/palermo-lobby'),
          ),
        ],
      ),
    );
  }
}
