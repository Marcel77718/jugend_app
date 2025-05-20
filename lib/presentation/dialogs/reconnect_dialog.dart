// Datei: lib/presentation/dialogs/reconnect_dialog.dart

import 'package:flutter/material.dart';

class ReconnectDialog extends StatelessWidget {
  final VoidCallback onRejoin;
  final VoidCallback onCancel;

  const ReconnectDialog({
    super.key,
    required this.onRejoin,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lobby wiederherstellen?'),
      content: const Text('Du befindest dich in einer laufenden Lobby.'),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Zurück zur Startseite'),
        ),
        ElevatedButton(
          onPressed: onRejoin,
          child: const Text('Wieder verbinden'),
        ),
      ],
    );
  }
}
