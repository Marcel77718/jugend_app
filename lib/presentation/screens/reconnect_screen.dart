// Datei: lib/view/reconnect_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/data/services/reconnect_service.dart';
import 'package:jugend_app/data/services/device_id_helper.dart';
import 'package:jugend_app/domain/viewmodels/lobby_view_model.dart';
import 'package:jugend_app/presentation/dialogs/reconnect_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    // Kein _checkReconnect(ref) hier, da ref nur im Consumer verfügbar ist
  }

  Future<void> _checkReconnect(WidgetRef ref) async {
    try {
      final deviceId = await DeviceIdHelper.getSafeDeviceId();
      final reconnectData = await _reconnectService.getReconnectData(deviceId);

      if (!mounted) return;

      if (reconnectData != null) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => ReconnectDialog(
                onRejoin: () => Navigator.of(context).pop(true),
                onCancel: () => Navigator.of(context).pop(false),
              ),
        );
        if (!mounted) return;
        if (result == true) {
          final viewModel = LobbyViewModel(ref: ref);
          await viewModel.handleReconnect(context, reconnectData);
        } else {
          await _reconnectService.clearReconnectData(deviceId);
          if (!mounted) return;
          context.go('/');
        }
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
    return Consumer(
      builder: (context, ref, _) {
        if (_isLoading) {
          // Starte den Reconnect-Check nur einmal
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_isLoading) _checkReconnect(ref);
          });
        }
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
      },
    );
  }
}
