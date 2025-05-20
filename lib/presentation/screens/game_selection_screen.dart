// 📁 Datei: lib/view/game_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/data/models/game_type.dart';

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GatherUp – Spielauswahl')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children:
            GameType.values.map((type) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () => context.push('/entry/${type.label}'),
                  child: Text(type.label),
                ),
              );
            }).toList(),
      ),
    );
  }
}
