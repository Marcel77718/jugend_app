import 'package:flutter/material.dart';
import 'package:jugend_app/core/performance_monitor.dart';

class GameScreen extends StatelessWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spiel')),
      body: Center(
        child: PerformanceWidget(
          name: 'GameContent',
          child: Text('Spiel ID: $gameId'),
        ),
      ),
    );
  }
}
