// Datei: lib/view/reconnect_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/services/reconnect_service.dart';
import 'package:jugend_app/helpers/device_id_helper.dart';
import 'package:jugend_app/view/widgets/reconnect_dialog.dart';
import 'package:jugend_app/model/reconnect_data.dart';

class ReconnectScreen extends StatefulWidget {
  const ReconnectScreen({super.key});

  @override
  State<ReconnectScreen> createState() => _ReconnectScreenState();
}

class _ReconnectScreenState extends State<ReconnectScreen> {
  final ReconnectService _reconnectService = ReconnectService();

  @override
  void initState() {
    super.initState();
    _checkReconnect();
  }

  Future<void> _checkReconnect() async {
    final deviceId = await DeviceIdHelper.getSafeDeviceId();
    final reconnectData = await _reconnectService.getReconnectData(deviceId);

    if (!mounted) return;

    if (reconnectData != null) {
      _showReconnectDialog(reconnectData);
    } else {
      context.go('/game-selection');
    }
  }

  void _showReconnectDialog(ReconnectData data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => ReconnectDialog(
            onRejoin: () {
              Navigator.of(context).pop();
              context.go('/lobby', extra: data);
            },
            onCancel: () {
              Navigator.of(context).pop();
              context.go('/game-selection');
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
