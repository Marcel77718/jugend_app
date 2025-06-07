import 'package:flutter/material.dart';

class GameScreen extends StatelessWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spiel')),
      body: Center(child: Text('Spiel ID: $gameId')),
    );
  }
}
