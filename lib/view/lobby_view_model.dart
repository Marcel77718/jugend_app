// Datei: lib/view/lobby_view_model.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jugend_app/helpers/device_id_helper.dart';
import 'package:jugend_app/helpers/snackbar_helper.dart';
import 'package:jugend_app/services/lobby_service.dart';
import 'package:jugend_app/model/reconnect_data.dart';
import 'package:jugend_app/services/reconnect_service.dart';
import 'package:go_router/go_router.dart';

class LobbyViewModel extends ChangeNotifier with WidgetsBindingObserver {
  late String _lobbyId;
  late String _playerName;
  late bool _isHost;
  late String _gameType;
  late String _deviceId;
  bool _viewModelInitialized = false;
  bool _isReady = false;
  List<Map<String, dynamic>> _players = [];
  String? _hostId;
  bool _isInBackground = false;
  Timer? _activityTimer;

  final _firestore = FirebaseFirestore.instance;
  late final CollectionReference _lobbyRef;
  StreamSubscription? _playerStreamSub;
  final ReconnectService _reconnectService = ReconnectService();

  Future<void> initialize({
    required String lobbyId,
    required String playerName,
    required bool isHost,
    required String gameType,
  }) async {
    // Registriere Lifecycle Observer
    WidgetsBinding.instance.addObserver(this);

    _lobbyId = lobbyId;
    _playerName = playerName;
    _isHost = isHost;
    _gameType = gameType;
    _deviceId = await DeviceIdHelper.getOrCreateDeviceId();
    _lobbyRef = _firestore.collection('lobbies/$_lobbyId/players');

    // Starte regelmäßige Aktivitätsupdates
    _startActivityTimer();

    // Speichere Reconnect-Daten
    await _reconnectService.registerReconnectData(
      ReconnectData(
        lobbyId: _lobbyId,
        playerName: _playerName,
        isHost: _isHost,
        gameType: _gameType,
      ),
    );

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

  void _startActivityTimer() {
    _activityTimer?.cancel();
    _activityTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!_isInBackground) {
        LobbyService.updatePlayerActivity(_lobbyId, _deviceId);
        LobbyService.updateLobbyActivity(_lobbyId);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _isInBackground = true;
        break;
      case AppLifecycleState.resumed:
        _isInBackground = false;
        // Update Aktivität wenn App wieder im Vordergrund ist
        LobbyService.updatePlayerActivity(_lobbyId, _deviceId);
        LobbyService.updateLobbyActivity(_lobbyId);
        break;
      case AppLifecycleState.detached:
        // App wird komplett geschlossen
        leaveLobby();
        break;
      default:
        break;
    }
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

      // Synchronisiere Host-Status
      _isHost = (_hostId == _deviceId);

      // Überprüfe, ob die Lobby leer ist
      if (_players.isEmpty) {
        // Lösche die Lobby, wenn sie leer ist
        await _firestore.collection('lobbies').doc(_lobbyId).delete();
        // Lösche auch die Reconnect-Daten für alle Spieler
        final reconnectSnapshot =
            await _firestore.collection('reconnect').get();
        for (var doc in reconnectSnapshot.docs) {
          final data = doc.data();
          if (data['lobbyId'] == _lobbyId) {
            await doc.reference.delete();
          }
        }
      }

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

  Future<void> confirmHostTransferDialog(
    BuildContext context,
    String newHostId,
    String playerName,
  ) async {
    final shouldTransfer =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Host übertragen'),
                content: Text(
                  'Willst du die Host-Rolle wirklich an "$playerName" übertragen?',
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
    if (shouldTransfer) {
      await transferHost(newHostId);
      if (!context.mounted) return;
    }
  }

  Future<void> transferHost(String newHostId) async {
    if (!_isHost || newHostId == _deviceId) return;
    await _firestore.collection('lobbies').doc(_lobbyId).update({
      'hostId': newHostId,
    });
    await _lobbyRef.doc(_deviceId).update({'isHost': false});
    await _lobbyRef.doc(newHostId).update({'isHost': true});
    _isHost = false;
    notifyListeners();
  }

  Future<void> setLobbyStage(String stage) async {
    await _firestore.collection('lobbies').doc(_lobbyId).update({
      'lobbyStage': stage,
    });
  }

  Future<String> getLobbyStage() async {
    final doc = await _firestore.collection('lobbies').doc(_lobbyId).get();
    final data = doc.data();
    return data?['lobbyStage'] ?? 'lobby';
  }

  // Call this in each screen's initState or after navigation
  Future<void> updateStageForCurrentScreen(String screen) async {
    await setLobbyStage(screen);
  }

  // Reconnect-Helper: Entscheide, wohin der User geleitet werden soll
  Future<void> handleReconnect(BuildContext context, ReconnectData data) async {
    final doc = await _firestore.collection('lobbies').doc(data.lobbyId).get();
    if (!doc.exists) {
      // Lobby existiert nicht mehr, lösche Reconnect-Daten und leite auf Startseite
      await _reconnectService.clearReconnectData(data.lobbyId);
      if (!context.mounted) return;
      GoRouter.of(context).go('/');
      return;
    }
    final lobbyStage = doc.data()?['lobbyStage'] ?? 'lobby';
    if (!context.mounted) return;
    if (lobbyStage == 'lobby') {
      GoRouter.of(context).go('/lobby', extra: data);
    } else if (lobbyStage == 'settings') {
      GoRouter.of(context).go('/game-settings', extra: data);
    } else if (lobbyStage == 'game') {
      GoRouter.of(context).go('/game', extra: data);
    } else {
      GoRouter.of(context).go('/lobby', extra: data);
    }
  }

  Future<void> leaveLobby() async {
    try {
      await _lobbyRef.doc(_deviceId).delete();
      await _reconnectService.clearReconnectData(_deviceId);

      // Host verlässt die Lobby: Rolle zufällig übertragen, aber nur solange settingsStarted nicht true ist
      final doc = await _firestore.collection('lobbies').doc(_lobbyId).get();
      final settingsStarted = doc.data()?['settingsStarted'] == true;
      if (_isHost && !settingsStarted) {
        final remainingPlayers =
            _players.where((p) => p['id'] != _deviceId).toList();
        if (remainingPlayers.isNotEmpty) {
          remainingPlayers.shuffle();
          final newHostId = remainingPlayers.first['id'];
          await _firestore.collection('lobbies').doc(_lobbyId).update({
            'hostId': newHostId,
          });
          await _lobbyRef.doc(newHostId).update({'isHost': true});
        }
      }

      // --- Prüfe, ob noch Spieler übrig sind ---
      final playersSnapshot = await _lobbyRef.get();
      if (playersSnapshot.docs.isEmpty) {
        // Lösche zuerst die Reconnect-Daten für diese Lobby
        final reconnectSnapshot =
            await _firestore.collection('reconnect').get();
        for (var doc in reconnectSnapshot.docs) {
          final data = doc.data();
          if (data['lobbyId'] == _lobbyId) {
            await doc.reference.delete();
          }
        }
        // Dann lösche die Lobby
        await _firestore.collection('lobbies').doc(_lobbyId).delete();
      }
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

    final snapshot = await _lobbyRef.get();
    final allPlayers =
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    final nameExists = allPlayers.any(
      (p) =>
          p['name'].toString().toLowerCase() == newName.toLowerCase() &&
          p['id'] != _deviceId,
    );

    if (nameExists) {
      if (context.mounted) {
        showRedSnackbar(context, 'Name existiert bereits in der Lobby');
      }
      return;
    }

    if (!context.mounted) return;
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

      if (context.mounted) {
        showGreenSnackbar(context, 'Name erfolgreich geändert');
      }
    } catch (e) {
      if (context.mounted) {
        showRedSnackbar(context, 'Fehler: ${e.toString()}');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activityTimer?.cancel();
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

  void startGame(BuildContext context) async {
    // Host setzt gameStarted auf true, Clients lauschen darauf
    final docRef = _firestore.collection('lobbies').doc(_lobbyId);
    if (_isHost) {
      await docRef.update({'gameStarted': true, 'lobbyStage': 'game'});
      if (!context.mounted) return;
      GoRouter.of(context).go('/game');
    } else {
      GoRouter.of(context).go('/game-settings');
    }
  }

  void listenForGameStart(BuildContext context) {
    final docRef = _firestore.collection('lobbies').doc(_lobbyId);
    docRef.snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data != null && data['gameStarted'] == true) {
        if (context.mounted) {
          GoRouter.of(context).go('/game');
        }
      }
    });
  }

  void startSettings(BuildContext context) async {
    // Host setzt settingsStarted auf true, Clients lauschen darauf
    final docRef = _firestore.collection('lobbies').doc(_lobbyId);
    if (_isHost) {
      await docRef.update({'settingsStarted': true, 'lobbyStage': 'settings'});
      final data = ReconnectData(
        lobbyId: _lobbyId,
        playerName: _playerName,
        isHost: _isHost,
        gameType: _gameType,
      );
      if (!context.mounted) return;
      GoRouter.of(context).go('/game-settings', extra: data);
    }
  }

  void listenForSettingsStart(BuildContext context) {
    final docRef = _firestore.collection('lobbies').doc(_lobbyId);
    docRef.snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data != null && data['settingsStarted'] == true) {
        final reconnectData = ReconnectData(
          lobbyId: _lobbyId,
          playerName: _playerName,
          isHost: _isHost,
          gameType: _gameType,
        );
        if (context.mounted) {
          GoRouter.of(context).go('/game-settings', extra: reconnectData);
        }
      }
    });
  }
}
