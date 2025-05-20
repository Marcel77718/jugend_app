// 📁 Datei: lib/view/game_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/data/models/game_type.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth < 500 ? double.infinity : 400;
          return Center(
            child: SizedBox(
              width: maxWidth,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: GameType.values.length,
                itemBuilder: (context, index) {
                  final type = GameType.values[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () => context.push('/entry/${type.label}'),
                      child: Text(type.label),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
