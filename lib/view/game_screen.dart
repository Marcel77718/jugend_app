import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jugend_app/view/lobby_view_model.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<LobbyViewModel>(context, listen: false);
      viewModel.updateStageForCurrentScreen('game');
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Spiel läuft...')),
      body: const Center(
        child: Text('Hier kommt später das eigentliche Spiel!'),
      ),
    );
  }
}
