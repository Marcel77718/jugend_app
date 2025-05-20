import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jugend_app/domain/viewmodels/lobby_view_model.dart';

class GameSettingsScreen extends StatelessWidget {
  const GameSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LobbyViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isHost) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            viewModel.updateStageForCurrentScreen('settings');
          });
          // Host sieht Einstellungen (Platzhalter)
          return Scaffold(
            appBar: AppBar(title: const Text('Spieleinstellungen')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Hier kommen später die Spieleinstellungen!'),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Signalisiere allen Clients, dass das Spiel startet
                      viewModel.startGame(context);
                    },
                    child: const Text('Spielen'),
                  ),
                ],
              ),
            ),
          );
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            viewModel.updateStageForCurrentScreen('settings');
          });
          // Clients sehen eine Warteanimation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            viewModel.listenForGameStart(context);
          });
          return Scaffold(
            appBar: AppBar(title: const Text('Warten auf Host...')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text('Bitte warten, der Host wählt die Einstellungen...'),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
