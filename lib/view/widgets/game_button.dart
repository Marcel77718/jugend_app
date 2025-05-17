// 📁 Datei: lib/view/widgets/game_button.dart

import 'package:flutter/material.dart';

class GameButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed; // ← ❗️ jetzt nullbar
  final bool enabled;

  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: enabled ? Colors.teal : Colors.grey,
      ),
      child: Text(label),
    );
  }
}
