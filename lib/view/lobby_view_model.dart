// Datei: lib/view/lobby_view_model.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jugend_app/helpers/device_id_helper.dart';
import 'package:jugend_app/helpers/snackbar_helper.dart';
import 'package:jugend_app/services/lobby_service.dart';

class LobbyViewModel extends ChangeNotifier {
  late String _lobbyId;
  late String _playerName;
  late bool _isHost;
  late String _gameType;
  late String _deviceId;
  bool _viewModelInitialized = false;
  bool _isReady = false;
  List<Map<String, dynamic>> _players = [];
  String? _hostId;

  final _firestore = FirebaseFirestore.instance;
  late final CollectionReference _lobbyRef;
  StreamSubscription? _playerStreamSub;

  Future<void> initialize({
    required String lobbyId,
    required String playerName,
    required bool isHost,
    required String gameType,
  }) async {
    _lobbyId = lobbyId;
    _playerName = playerName;
    _isHost = isHost;
    _gameType = gameType;
    _deviceId = await DeviceIdHelper.getOrCreateDeviceId();
    _lobbyRef = _firestore.collection('lobbies/$_lobbyId/players');

    await _lobbyRef.doc(_deviceId).set({
      'id': _deviceId,
      'name': _playerName,
      'isReady': false,
    });

    if (isHost) {
      await _firestore.collection('lobbies').doc(_lobbyId).set({
        'hostId': _deviceId,
        'gameType': _gameType,
      });
    }

    _listenToPlayers();
    _viewModelInitialized = true;
    notifyListeners();
  }

  void _listenToPlayers() {
    _playerStreamSub?.cancel();
    _playerStreamSub = _lobbyRef.snapshots().listen((snapshot) async {
      _players =
          snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

      final lobbyDoc =
          await _firestore.collection('lobbies').doc(_lobbyId).get();
      _hostId = lobbyDoc.data()?['hostId'] ?? _hostId;

      _checkIfKicked();
      notifyListeners();
    });
  }

  void _checkIfKicked() {
    if (_players.isNotEmpty && !_players.any((p) => p['id'] == _deviceId)) {
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> toggleReadyStatus() async {
    _isReady = !_isReady;
    await _lobbyRef.doc(_deviceId).update({'isReady': _isReady});
    notifyListeners();
  }

  Future<void> updateStatusStarted() async {
    await _firestore.collection('lobbies').doc(_lobbyId).update({
      'status': 'started',
    });
  }

  Future<void> kickPlayer(String playerId) async {
    await _lobbyRef.doc(playerId).delete();
  }

  Future<void> confirmKickDialog(BuildContext context, String playerId) async {
    final shouldKick =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Spieler kicken'),
                content: const Text(
                  'Möchtest du diesen Spieler wirklich aus der Lobby entfernen?',
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
      await kickPlayer(playerId);
    }
  }

  Future<void> leaveLobby() async {
    try {
      await _lobbyRef.doc(_deviceId).delete();
    } catch (_) {}
  }

  Future<void> confirmNameChangeDialog(
    BuildContext context,
    String currentName,
  ) async {
    final TextEditingController controller = TextEditingController(text: '');

    final newName = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Name ändern'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Neuer Name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Ändern'),
              ),
            ],
          ),
    );

    if (!context.mounted ||
        newName == null ||
        newName.isEmpty ||
        newName == currentName) {
      return;
    }

    final nameExists = players.any(
      (p) =>
          p['name'].toString().toLowerCase() == newName.toLowerCase() &&
          p['id'] != deviceId,
    );
    if (nameExists) {
      showRedSnackbar(context, 'Name existiert bereits in der Lobby');
      return;
    }

    await updatePlayerName(context, newName);
  }

  Future<void> updatePlayerName(BuildContext context, String newName) async {
    try {
      await LobbyService.updatePlayerName(_lobbyId, _deviceId, newName);
      _playerName = newName;

      final updatedDoc = await _lobbyRef.doc(_deviceId).get();
      final updatedPlayer = updatedDoc.data() as Map<String, dynamic>;
      _players.removeWhere((p) => p['id'] == _deviceId);
      _players.add(updatedPlayer);
      notifyListeners();

      if (!context.mounted) return;
      showGreenSnackbar(context, 'Name erfolgreich geändert');
    } catch (e) {
      if (!context.mounted) return;
      showRedSnackbar(context, 'Fehler: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _playerStreamSub?.cancel();
    super.dispose();
  }

  // Getter
  bool get viewModelInitialized => _viewModelInitialized;
  String get lobbyId => _lobbyId;
  String get playerName => _playerName;
  bool get isHost => _isHost;
  String get gameType => _gameType;
  String get deviceId => _deviceId;
  bool get isReady => _isReady;
  List<Map<String, dynamic>> get players => _players;
  String? get hostId => _hostId;
  bool get everyoneReady =>
      _players.isNotEmpty && _players.every((p) => p['isReady'] == true);
}
