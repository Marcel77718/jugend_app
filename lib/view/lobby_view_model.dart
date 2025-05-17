// Datei: lib/view/lobby_view_model.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jugend_app/helpers/device_id_helper.dart';

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
    _playerStreamSub = _lobbyRef.snapshots().listen((snapshot) async {
      _players =
          snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

      final lobbyDoc =
          await _firestore.collection('lobbies').doc(_lobbyId).get();
      _hostId = lobbyDoc.data()?['hostId'] ?? _hostId;

      notifyListeners();
    });
  }

  void toggleReadyStatus() async {
    _isReady = !_isReady;
    await _lobbyRef.doc(_deviceId).update({'isReady': _isReady});
    notifyListeners();
  }

  void updateStatusStarted() async {
    await _firestore.collection('lobbies').doc(_lobbyId).update({
      'status': 'started',
    });
  }

  void kickPlayer(String playerId) async {
    await _lobbyRef.doc(playerId).delete();
  }

  void confirmNameChangeDialog(String newName) async {
    _playerName = newName;
    await _lobbyRef.doc(_deviceId).update({'name': newName});
    notifyListeners();
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
