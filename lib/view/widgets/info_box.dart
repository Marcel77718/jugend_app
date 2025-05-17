// 📁 Datei: lib/view/widgets/info_box.dart

import 'package:flutter/material.dart';

class InfoBox extends StatelessWidget {
  final String text;

  const InfoBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_esports, color: Colors.teal),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
