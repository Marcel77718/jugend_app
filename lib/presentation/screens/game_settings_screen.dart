import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/lobby_view_model.dart';
import 'package:jugend_app/data/models/reconnect_data.dart';

class GameSettingsScreen extends ConsumerWidget {
  final ReconnectData data;
  const GameSettingsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(lobbyViewModelProvider(data));
    return Builder(
      builder: (context) {
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
