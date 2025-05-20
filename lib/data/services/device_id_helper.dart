// Datei: lib/data/services/device_id_helper.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdHelper {
  static Future<String> getSafeDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('deviceId');
    return existing ?? await getOrCreateDeviceId();
  }

  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('deviceId');
    if (existing != null) return existing;
    final newId = const Uuid().v4();
    await prefs.setString('deviceId', newId);
    return newId;
  }
}
