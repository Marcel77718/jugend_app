// Datei: lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jugend_app/router.dart';
import 'firebase_options.dart';
import 'package:jugend_app/core/feedback_service.dart';
import 'package:jugend_app/core/logging_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
// ignore: avoid_web_libraries_in_flutter
import 'dart:io' show Platform;
import 'package:jugend_app/core/performance_monitor.dart';
import 'package:jugend_app/core/asset_optimizer.dart';
import 'package:jugend_app/core/build_optimizer.dart';
import 'package:jugend_app/core/firebase_optimizer.dart';
import 'package:jugend_app/core/memory_optimizer.dart';
import 'package:jugend_app/core/network_optimizer.dart';

final localeProvider = StateProvider<Locale?>((ref) => const Locale('de'));

Future<void> initializeFirebase() async {
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

      // Initialisiere Crashlytics
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );

      // Setze Benutzer-ID für Crashlytics, falls verfügbar
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
      }

      LoggingService.instance.log(
        'Firebase erfolgreich initialisiert',
        level: LogLevel.info,
      );
    }
  } catch (e, stackTrace) {
    LoggingService.instance.log(
      'Fehler bei der Firebase-Initialisierung',
      level: LogLevel.error,
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisiere Optimizer
  await BuildOptimizer.instance.initialize();
  await MemoryOptimizer.instance.initialize();
  await NetworkOptimizer.instance.initialize();
  await FirebaseOptimizer.initializeAndGetInstance();
  await AssetOptimizer.instance.preloadAssets([
    // Füge hier wichtige Assets hinzu, die vorab geladen werden sollen
  ]);

  LoggingService.instance.log(
    'Alle Optimizer initialisiert',
    level: LogLevel.info,
  );

  runZonedGuarded(
    () async {
      // Starte Performance-Monitoring
      PerformanceMonitor.instance.startMonitoring();

      try {
        await initializeFirebase();
        runApp(const ProviderScope(child: MyApp()));
      } catch (e, stackTrace) {
        LoggingService.instance.log(
          'Kritischer Fehler beim App-Start',
          level: LogLevel.fatal,
          error: e,
          stackTrace: stackTrace,
        );
        runApp(
          ProviderScope(
            child: MyApp(
              firebaseInitError: true,
              firebaseInitErrorMsg: e.toString(),
            ),
          ),
        );
      }
    },
    (error, stack) {
      LoggingService.instance.log(
        'Unbehandelter Fehler',
        level: LogLevel.fatal,
        error: error,
        stackTrace: stack,
      );
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
