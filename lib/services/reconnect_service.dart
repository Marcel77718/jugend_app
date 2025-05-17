// Datei: lib/services/reconnect_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jugend_app/helpers/device_id_helper.dart';
import 'package:jugend_app/model/reconnect_data.dart';

class ReconnectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<ReconnectData?> getReconnectData(String deviceId) async {
    final doc = await _firestore.collection('reconnect').doc(deviceId).get();
    if (doc.exists && doc.data() != null) {
      return ReconnectData.fromMap(doc.data()!);
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
