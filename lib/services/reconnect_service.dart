// Datei: lib/services/reconnect_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jugend_app/helpers/device_id_helper.dart';
import 'package:jugend_app/model/reconnect_data.dart';
import 'package:jugend_app/services/lobby_service.dart';

class ReconnectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<ReconnectData?> getReconnectData(String deviceId) async {
    final doc = await _firestore.collection('reconnect').doc(deviceId).get();
    if (doc.exists && doc.data() != null) {
      final data = ReconnectData.fromMap(doc.data()!);

      // Überprüfe, ob die Lobby noch existiert
      final lobbyExists = await LobbyService.lobbyExists(data.lobbyId);
      if (!lobbyExists) {
        // Lösche Reconnect-Daten, wenn die Lobby nicht mehr existiert
        await clearReconnectData(deviceId);
        return null;
      }

      return data;
    }
    return null;
  }

  Future<void> saveReconnectData(String deviceId, ReconnectData data) async {
    await _firestore.collection('reconnect').doc(deviceId).set(data.toMap());
  }

  Future<void> clearReconnectData(String deviceId) async {
    await _firestore.collection('reconnect').doc(deviceId).delete();
  }

  /// Convenience-Methode, die automatisch die ID holt
  Future<ReconnectData?> loadReconnectDataFromDevice() async {
    final deviceId = await DeviceIdHelper.getSafeDeviceId();
    return getReconnectData(deviceId);
  }

  /// Speichert Daten unter der automatisch ermittelten Device-ID
  Future<void> registerReconnectData(ReconnectData data) async {
    final deviceId = await DeviceIdHelper.getOrCreateDeviceId();
    await saveReconnectData(deviceId, data);
  }
}
