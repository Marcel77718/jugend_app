// Datei: lib/view/lobby_join_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/data/models/reconnect_data.dart';
import 'package:jugend_app/data/providers/lobby_providers.dart';
import 'package:jugend_app/data/services/reconnect_service.dart';
import 'package:jugend_app/core/snackbar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';
import 'package:jugend_app/core/app_routes.dart';
import 'package:jugend_app/generated/app_localizations.dart';

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

  void _joinLobby(String name, WidgetRef ref) async {
    final lobbyId = _lobbyIdController.text.trim();
    if (lobbyId.isEmpty) return;

    // Prüfe, ob die Lobby existiert
    final lobbyRepo = ref.read(lobbyRepositoryProvider);
    final exists = await lobbyRepo.lobbyExists(lobbyId);
    if (!mounted) return;
    if (!exists) {
      SnackbarHelper.error(
        context,
        AppLocalizations.of(context)!.errorLobbyInvalid,
      );
      return;
    }

    // Prüfe Namen belegt
    final nameExists = await lobbyRepo.isNameTaken(lobbyId, name);

    // Prüfe, ob eingeloggter Nutzer und Namenskonflikt mit anderem eingeloggten Nutzer
    final auth = ref.read(authViewModelProvider);
    final user = auth.profile;
    final isLoggedIn = auth.status == AuthStatus.signedIn && user != null;
    if (isLoggedIn && nameExists) {
      final conflictPlayer = await lobbyRepo.getPlayerByName(lobbyId, name);
      final isOtherLoggedIn =
          conflictPlayer != null &&
          conflictPlayer['deviceId'] != null &&
          conflictPlayer['deviceId'].toString().isNotEmpty;

      if (isOtherLoggedIn) {
        // Dialog für neuen Namen
        final tempNameController = TextEditingController(text: name);
        if (!mounted) return;
        final newName = await showDialog<String>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Name bereits vergeben'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'In der Lobby gibt es schon einen $name. Welchen Namen willst du für die Lobby?',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tempNameController,
                      decoration: const InputDecoration(hintText: 'Neuer Name'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                  TextButton(
                    onPressed:
                        () => Navigator.pop(
                          context,
                          tempNameController.text.trim(),
                        ),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
        if (!mounted || newName == null || newName.isEmpty) return;
        final nameTaken = await lobbyRepo.isNameTaken(lobbyId, newName);
        if (nameTaken) {
          SnackbarHelper.error(context, 'Name existiert bereits in der Lobby');
          return;
        }
        return _joinLobby(newName, ref);
      }
      // Wenn der Konfliktspieler NICHT eingeloggt ist, darf der eingeloggte Spieler joinen!
    }
    // Für nicht eingeloggte Joiner weiterhin blockieren, wenn Name existiert
    if (!isLoggedIn && nameExists) {
      if (!mounted) return;
      SnackbarHelper.error(
        context,
        AppLocalizations.of(context)!.errorNameTaken,
      );
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
    context.go(AppRoutes.lobby, extra: reconnectData);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer(
      builder: (context, ref, _) {
        final auth = ref.watch(authViewModelProvider);
        final user = auth.profile;
        final isLoggedIn = auth.status == AuthStatus.signedIn && user != null;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.titleLeaveLobby),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(AppRoutes.lobbies),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _lobbyIdController,
                  decoration: InputDecoration(
                    labelText: l10n.labelLobbyId,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                if (!isLoggedIn) ...[
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.labelYourName,
                      border: const OutlineInputBorder(),
                      hintText: l10n.hintNameInput,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;
                      _joinLobby(name, ref);
                    },
                    child: Text(l10n.labelSave),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () async {
                      final currentName = user.displayName ?? 'Unbekannt';
                      _joinLobby(currentName, ref);
                    },
                    child: Text(l10n.labelSave),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
