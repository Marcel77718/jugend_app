// Datei: lib/view/lobby_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as p;
import 'package:go_router/go_router.dart';
import 'package:jugend_app/core/snackbar_helper.dart';
import 'package:jugend_app/domain/viewmodels/lobby_view_model.dart';
import 'package:jugend_app/presentation/widgets/player_tile.dart';
import 'package:jugend_app/data/repositories/lobby_repository.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/friend_view_model.dart';
import 'package:jugend_app/data/models/friend.dart';
import 'package:jugend_app/core/app_routes.dart';

class LobbyScreen extends StatefulWidget {
  final String lobbyId;
  final String playerName;
  final bool isHost;
  final String gameType;

  const LobbyScreen({
    super.key,
    required this.lobbyId,
    required this.playerName,
    required this.isHost,
    required this.gameType,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  bool hasLeft = false;

  @override
  void initState() {
    super.initState();
    // Callback für Namenskonflikt-Dialog setzen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = p.Provider.of<LobbyViewModel>(context, listen: false);
      viewModel.setOnMustChangeName(() async {
        if (viewModel.mustChangeName && context.mounted) {
          final newName = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              final controller = TextEditingController();
              return AlertDialog(
                title: const Text('Namenskonflikt'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Ein eingeloggter Spieler hat den gleichen Namen. Bitte wähle einen neuen Namen.',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
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
                        () => Navigator.pop(context, controller.text.trim()),
                    child: const Text('Ändern'),
                  ),
                ],
              );
            },
          );
          if (newName != null && newName.isNotEmpty && context.mounted) {
            if (!mounted) return;
            await viewModel.updatePlayerName(context, newName);
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return p.ChangeNotifierProvider(
      create:
          (_) => LobbyViewModel(lobbyRepository: LobbyRepository())..initialize(
            lobbyId: widget.lobbyId,
            playerName: widget.playerName,
            isHost: widget.isHost,
            gameType: widget.gameType,
            context: context,
          ),
      child: p.Consumer<LobbyViewModel>(
        builder: (context, viewModel, _) {
          if (!viewModel.viewModelInitialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Clients hören auf settingsStarted
          if (!viewModel.isHost) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              viewModel.listenForSettingsStart(context);
            });
          }
          final isKicked =
              viewModel.players.isNotEmpty &&
              !viewModel.players.any((p) => p['id'] == viewModel.deviceId);
          if (isKicked && !hasLeft) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              showRedSnackbar(context, 'Du wurdest vom Host gekickt.');
              context.go(AppRoutes.home);
            });
          }
          final sortedPlayers = [
            ...viewModel.players.where((p) => p['id'] == viewModel.deviceId),
            ...viewModel.players.where((p) => p['id'] != viewModel.deviceId),
          ];
          return PopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, result) async {
              if (!didPop) {
                await _handleBackPressed(context, viewModel);
              }
            },
            child: Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _handleBackPressed(context, viewModel),
                ),
                title: Text(l10n.appTitle),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        '${l10n.labelLobbyId}: ${viewModel.lobbyId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, _) {
                            final friendViewModel = ref.watch(
                              friendViewModelProvider,
                            );
                            final friendsStream = friendViewModel.friendsStream;
                            return StreamBuilder<List<Friend>>(
                              stream: friendsStream,
                              builder: (context, snapshot) {
                                final friendList = snapshot.data ?? [];
                                return ListView.builder(
                                  itemCount: sortedPlayers.length,
                                  itemBuilder: (context, index) {
                                    final player = sortedPlayers[index];
                                    final isOwn =
                                        player['id'] == viewModel.deviceId;
                                    final isFriend = friendList.any(
                                      (f) => f.friendUid == player['userUid'],
                                    );
                                    return PlayerTile(
                                      key: ValueKey(player['id']),
                                      player: player,
                                      isOwnPlayer: isOwn,
                                      isHost: viewModel.isHost,
                                      hostId: viewModel.hostId,
                                      onKick:
                                          viewModel.isHost && !isOwn
                                              ? () => _confirmKick(
                                                context,
                                                viewModel,
                                                player['id'],
                                                player['name'],
                                              )
                                              : null,
                                      onNameChange:
                                          isOwn
                                              ? () => viewModel
                                                  .confirmNameChangeDialog(
                                                    context,
                                                    player['name'],
                                                  )
                                              : null,
                                      onHostTransfer:
                                          viewModel.isHost && !isOwn
                                              ? () => viewModel
                                                  .confirmHostTransferDialog(
                                                    context,
                                                    player['id'],
                                                    player['name'],
                                                  )
                                              : null,
                                      showAddFriend: !isOwn && !isFriend,
                                      onAddFriend:
                                          !isOwn && !isFriend
                                              ? () async {
                                                final name =
                                                    player['name'] ?? '';
                                                final tag = player['tag'] ?? '';
                                                final error =
                                                    await friendViewModel
                                                        .sendFriendRequest(
                                                          name,
                                                          tag,
                                                        );
                                                if (error != null &&
                                                    context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(error),
                                                    ),
                                                  );
                                                } else if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Anfrage gesendet!',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                              : null,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => viewModel.toggleReadyStatus(),
                            child: Text(
                              viewModel.isReady
                                  ? l10n.labelNotReady
                                  : l10n.labelReady,
                            ),
                          ),
                          if (viewModel.isHost && viewModel.everyoneReady)
                            ElevatedButton(
                              onPressed: () => viewModel.startSettings(context),
                              child: Text(l10n.labelStartGame),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleBackPressed(
    BuildContext context,
    LobbyViewModel viewModel,
  ) async {
    final shouldLeave =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Lobby verlassen?'),
                content: const Text(
                  'Bist du sicher, dass du die Lobby verlassen möchtest?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Nein'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Ja'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!context.mounted) return;

    if (shouldLeave) {
      hasLeft = true;
      await viewModel.leaveLobby(context: context);
      if (context.mounted) {
        showNeutralSnackbar(context, 'Du hast die Lobby verlassen.');
        context.go(AppRoutes.home);
      }
    }
  }

  Future<void> _confirmKick(
    BuildContext context,
    LobbyViewModel viewModel,
    String playerId,
    String playerName,
  ) async {
    final shouldKick =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Spieler kicken?'),
                content: Text(
                  'Möchtest du $playerName wirklich aus der Lobby entfernen?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Nein'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Ja'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!context.mounted) return;
    if (shouldKick) {
      await viewModel.kickPlayer(playerId);
    }
  }
}
