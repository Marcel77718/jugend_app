// Datei: lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:jugend_app/router.dart';
import 'firebase_options.dart';
import 'package:jugend_app/core/feedback_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:io' show Platform;

final localeProvider = StateProvider<Locale?>((ref) => const Locale('de'));

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      bool firebaseInitError = false;
      String? firebaseInitErrorMsg;

      try {
        if (Firebase.apps.isEmpty) {
          if (kIsWeb) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
          } else if (!Platform.isAndroid && !Platform.isIOS) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
          } else {
            await Firebase.initializeApp();
          }
        }
      } catch (e) {
        firebaseInitError = true;
        firebaseInitErrorMsg = e.toString();
      }

      runApp(
        ProviderScope(
          child: MyApp(
            firebaseInitError: firebaseInitError,
            firebaseInitErrorMsg: firebaseInitErrorMsg,
          ),
        ),
      );
    },
    (error, stack) {
      FeedbackService.instance.showError(error.toString());
    },
  );
}

class MyApp extends ConsumerWidget {
  final bool firebaseInitError;
  final String? firebaseInitErrorMsg;
  const MyApp({
    super.key,
    this.firebaseInitError = false,
    this.firebaseInitErrorMsg,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    if (firebaseInitError) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    'Fehler bei der Verbindung zu Firebase!',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    firebaseInitErrorMsg ?? '',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Bitte prüfe deine Internetverbindung, die Uhrzeit und die Google Play-Dienste auf deinem Gerät.',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
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
      locale: locale,
      builder: (context, child) {
        return FeedbackListener(child: child!);
      },
    );
  }
}

class FeedbackListener extends ConsumerStatefulWidget {
  final Widget child;
  const FeedbackListener({super.key, required this.child});

  @override
  ConsumerState<FeedbackListener> createState() => _FeedbackListenerState();
}

class _FeedbackListenerState extends ConsumerState<FeedbackListener> {
  StreamSubscription<String>? _snackbarSub;
  StreamSubscription<String>? _errorSub;
  // Timer? _activityTimer; // Entfernt

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addObserver(this); // Entfernt
    // _startActivityTimer(); // Entfernt
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
    // WidgetsBinding.instance.removeObserver(this); // Entfernt
    _snackbarSub?.cancel();
    _errorSub?.cancel();
    // _activityTimer?.cancel(); // Entfernt
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
