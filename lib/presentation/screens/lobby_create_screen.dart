// Datei: lib/view/lobby_create_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/data/models/reconnect_data.dart';
import 'package:jugend_app/data/services/reconnect_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';

class LobbyCreateScreen extends StatefulWidget {
  const LobbyCreateScreen({super.key});

  @override
  State<LobbyCreateScreen> createState() => _LobbyCreateScreenState();
}

class _LobbyCreateScreenState extends State<LobbyCreateScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createLobby(String name) async {
    final lobbyId = (Random().nextInt(900000) + 100000).toString();
    const gameType = 'Impostor'; // später auswählbar machen

    final reconnectService = ReconnectService();
    final reconnectData = ReconnectData(
      lobbyId: lobbyId,
      playerName: name,
      isHost: true,
      gameType: gameType,
    );

    await reconnectService.registerReconnectData(reconnectData);

    if (!mounted) return;
    context.go('/lobby', extra: reconnectData);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final auth = ref.watch(authViewModelProvider);
        final user = auth.profile;
        final isLoggedIn = auth.status == AuthStatus.signedIn && user != null;
        final defaultName = isLoggedIn ? (user.displayName ?? 'Unbekannt') : '';
        if (isLoggedIn) {
          // Wenn eingeloggt: sofort Lobby erstellen und weiterleiten
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _createLobby(defaultName);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Nicht eingeloggt: Name eingeben und Button anzeigen
        return Scaffold(
          appBar: AppBar(
            title: const Text('Spiel erstellen'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/lobbies'),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Dein Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) return;
                    _createLobby(name);
                  },
                  child: const Text('Lobby erstellen'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
