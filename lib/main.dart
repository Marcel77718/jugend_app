// Datei: lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:jugend_app/router.dart';
import 'firebase_options.dart';
import 'package:jugend_app/core/feedback_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = (FlutterErrorDetails details) {
    FeedbackService.instance.showError(details.exceptionAsString());
    FlutterError.presentError(details);
  };

  runZonedGuarded(
    () {
      runApp(const MyApp());
    },
    (error, stack) {
      FeedbackService.instance.showError(error.toString());
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GatherUp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('de'), Locale('en')],
      locale: const Locale('de'),
      builder: (context, child) {
        return FeedbackListener(child: child!);
      },
    );
  }
}

class FeedbackListener extends StatefulWidget {
  final Widget child;
  const FeedbackListener({super.key, required this.child});

  @override
  State<FeedbackListener> createState() => _FeedbackListenerState();
}

class _FeedbackListenerState extends State<FeedbackListener> {
  StreamSubscription<String>? _snackbarSub;
  StreamSubscription<String>? _errorSub;

  @override
  void initState() {
    super.initState();
    _snackbarSub = FeedbackService.instance.snackbarStream.listen((msg) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    });
    _errorSub = FeedbackService.instance.errorStream.listen((msg) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Fehler'),
                content: Text(msg),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    });
  }

  @override
  void dispose() {
    _snackbarSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
