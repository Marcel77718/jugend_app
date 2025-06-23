// Datei: lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:jugend_app/core/logging_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
// ignore: avoid_web_libraries_in_flutter
import 'dart:io' show Platform;

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jugend_app/generated/app_localizations.dart';
import 'package:jugend_app/router.dart';

final localeProvider = StateProvider<Locale?>((ref) => const Locale('de'));

Future<void> initializeFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      if (kIsWeb) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
      } else if (!Platform.isAndroid && !Platform.isIOS) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        await Firebase.initializeApp();
      }

      // Initialisiere Crashlytics nur auf unterstützten Plattformen
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          !kDebugMode,
        );
      }

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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Jugend App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('de'), Locale('en')],
      routerConfig: appRouter,
    );
  }
}
