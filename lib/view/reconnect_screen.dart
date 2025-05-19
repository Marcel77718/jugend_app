// Datei: lib/view/reconnect_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/services/reconnect_service.dart';
import 'package:jugend_app/helpers/device_id_helper.dart';
import 'package:jugend_app/view/lobby_view_model.dart';

class ReconnectScreen extends StatefulWidget {
  const ReconnectScreen({super.key});

  @override
  State<ReconnectScreen> createState() => _ReconnectScreenState();
}

class _ReconnectScreenState extends State<ReconnectScreen> {
  final ReconnectService _reconnectService = ReconnectService();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkReconnect();
  }

  Future<void> _checkReconnect() async {
    try {
      final deviceId = await DeviceIdHelper.getSafeDeviceId();
      final reconnectData = await _reconnectService.getReconnectData(deviceId);

      if (!mounted) return;

      if (reconnectData != null) {
        final viewModel = LobbyViewModel();
        await viewModel.handleReconnect(context, reconnectData);
      } else {
        if (!mounted) return;
        context.go('/');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Fehler beim Verbinden: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:
            _isLoading
                ? const CircularProgressIndicator()
                : _error != null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/game-selection'),
                      child: const Text('Zurück zur Spielauswahl'),
                    ),
                  ],
                )
                : const CircularProgressIndicator(),
      ),
    );
  }
}
