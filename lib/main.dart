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
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class _FeedbackListenerState extends ConsumerState<FeedbackListener>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _snackbarSub;
  StreamSubscription<String>? _errorSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _snackbarSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return; // Nur für eingeloggte User

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Keine Statusänderung für diese Zustände. Der Status bleibt wie er ist.
        // Der Timeout in der Freundesliste wird den User irgendwann als offline markieren,
        // wenn die App im Hintergrund keine lastActive Updates mehr sendet (was der Fall sein sollte, wenn detached)
        break;
      case AppLifecycleState.resumed:
        // App kommt wieder in den Vordergrund. Setze Status auf online.
        FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
              'status': 'online',
              'lastActive': FieldValue.serverTimestamp(),
            });
        break;
      case AppLifecycleState.detached:
        // App wird komplett geschlossen
        // Setze Status auf offline und entferne currentLobbyId
        FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
              'status': 'offline',
              'currentLobbyId': FieldValue.delete(),
              'lastActive':
                  FieldValue.serverTimestamp(), // Auch hier zuletzt aktiv setzen
            });
        // Der LobbyViewModel handhabt leaveLobby, wenn der Benutzer in einer Lobby war.
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
