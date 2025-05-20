// Datei: lib/view/lobby_join_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/data/models/reconnect_data.dart';
import 'package:jugend_app/data/services/lobby_service.dart';
import 'package:jugend_app/data/services/reconnect_service.dart';
import 'package:jugend_app/core/snackbar_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LobbyJoinScreen extends StatefulWidget {
  const LobbyJoinScreen({super.key});

  @override
  State<LobbyJoinScreen> createState() => _LobbyJoinScreenState();
}

class _LobbyJoinScreenState extends State<LobbyJoinScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lobbyIdController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _lobbyIdController.dispose();
    super.dispose();
  }

  void _joinLobby() async {
    final name = _nameController.text.trim();
    final lobbyId = _lobbyIdController.text.trim();
    if (name.isEmpty || lobbyId.isEmpty) return;

    // Prüfe, ob die Lobby existiert
    final exists = await LobbyService.lobbyExists(lobbyId);
    if (!exists) {
      if (!mounted) return;
      showRedSnackbar(context, AppLocalizations.of(context)!.errorLobbyInvalid);
      return;
    }

    final nameExists = await LobbyService.isNameTaken(lobbyId, name);
    if (nameExists) {
      if (!mounted) return;
      showRedSnackbar(context, AppLocalizations.of(context)!.errorNameTaken);
      return;
    }

    const gameType = 'Impostor'; // später auswählbar machen

    final reconnectService = ReconnectService();
    final reconnectData = ReconnectData(
      lobbyId: lobbyId,
      playerName: name,
      isHost: false,
      gameType: gameType,
    );

    await reconnectService.registerReconnectData(reconnectData);

    if (!mounted) return;
    context.go('/lobby', extra: reconnectData);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleLeaveLobby),
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
              decoration: InputDecoration(
                labelText: l10n.labelYourName,
                border: const OutlineInputBorder(),
                hintText: l10n.hintNameInput,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lobbyIdController,
              decoration: InputDecoration(
                labelText: l10n.labelLobbyId,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _joinLobby, child: Text(l10n.labelSave)),
          ],
        ),
      ),
    );
  }
}
