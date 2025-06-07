import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';
import 'package:jugend_app/core/snackbar_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/data/services/auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordRepeatController = TextEditingController();
  bool _isLogin = true;
  bool _gdprAccepted = false;
  bool _showVerificationNotice = false;
  String? _passwordRepeatError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordRepeatController.dispose();
    super.dispose();
  }

  void _submit(AuthViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isLogin) {
      if (_passwordController.text != _passwordRepeatController.text) {
        setState(() {
          _passwordRepeatError = 'Passwörter stimmen nicht überein';
        });
        return;
      } else {
        setState(() {
          _passwordRepeatError = null;
        });
      }
    }
    final locale = Localizations.localeOf(context).languageCode;
    if (_isLogin) {
      await viewModel.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        locale: locale,
      );
      if (!mounted) return;
    } else {
      await viewModel.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      await viewModel.sendEmailVerification();
      if (!mounted) return;
      setState(() {
        _showVerificationNotice = true;
      });
      SnackbarHelper.success(
        context,
        'Verifizierungs-E-Mail wurde gesendet. Bitte prüfe deine E-Mails.',
      );
    }
  }

  Future<void> _handleGoogle(AuthViewModel viewModel) async {
    if (!_gdprAccepted) {
      await _showGdprDialog();
      if (!_gdprAccepted) return;
    }
    await viewModel.signInWithGoogle();
  }

  Future<void> _showGdprDialog() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Datenschutz & Einwilligung'),
            content: const Text(
              'Für Google-Login werden personenbezogene Daten (z.B. Name, E-Mail) von Google verarbeitet. Mit Fortfahren stimmst du der Übermittlung und Verarbeitung gemäß unserer Datenschutzerklärung zu.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Zustimmen & fortfahren'),
              ),
            ],
          ),
    );
    setState(() {
      _gdprAccepted = accepted == true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final viewModel = ref.read(authViewModelProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState.error != null) {
        if (authState.error == 'success' && !_isLogin) {
          setState(() {
            _showVerificationNotice = true;
          });
          viewModel.clearError();
          return;
        }
        if (authState.error == 'reset_success') {
          SnackbarHelper.success(
            context,
            'Passwort-Reset-E-Mail wurde gesendet.',
          );
          viewModel.clearError();
        } else if (authState.error == 'reset_failed') {
          SnackbarHelper.error(context, 'Fehler beim Senden der Reset-E-Mail.');
          viewModel.clearError();
        } else if (authState.error == 'verify_success') {
          if (!_showVerificationNotice) {
            SnackbarHelper.success(
              context,
              'Verifizierungs-E-Mail wurde gesendet.',
            );
          }
          viewModel.clearError();
        } else if (authState.error == 'verify_failed') {
          if (!_showVerificationNotice) {
            SnackbarHelper.error(
              context,
              'Fehler beim Senden der Verifizierungs-E-Mail.',
            );
          }
          viewModel.clearError();
        } else if (authState.error!.contains('Es gibt keinen Account')) {
          SnackbarHelper.error(context, authState.error!);
          viewModel.setSignedOut();
        } else if (authState.error!.contains('Falsches Passwort')) {
          SnackbarHelper.error(context, authState.error!);
          viewModel.setSignedOut();
        } else if (authState.error!.contains(
          'Diese E-Mail ist bereits registriert.',
        )) {
          SnackbarHelper.error(context, authState.error!);
          viewModel.setSignedOut();
        } else if (authState.error!.contains('Ungültige E-Mail-Adresse.')) {
          SnackbarHelper.error(context, authState.error!);
          viewModel.setSignedOut();
        } else if (authState.error!.contains('Das Passwort ist zu schwach.')) {
          SnackbarHelper.error(context, authState.error!);
          viewModel.setSignedOut();
        } else if (authState.error != null && authState.error != 'success') {
          SnackbarHelper.error(context, authState.error!);
          viewModel.setSignedOut();
        }
      }
      // Weiterleitung ins Hub NUR wenn die E-Mail verifiziert ist
      final isVerified = AuthService().currentUser?.emailVerified ?? false;
      if (authState.status == AuthStatus.signedIn && isVerified) {
        context.go('/');
      } else if (authState.status == AuthStatus.signedIn && !isVerified) {
        setState(() {
          _showVerificationNotice = true;
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Anmelden'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/');
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLogin ? 'Login' : 'Registrieren',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                if (_showVerificationNotice)
                  Column(
                    children: [
                      const Text(
                        'Bitte prüfe deine E-Mails und bestätige deine Adresse.',
                        style: TextStyle(color: Colors.teal),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => viewModel.sendEmailVerification(),
                        child: const Text(
                          'Verifizierungs-E-Mail erneut senden',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText:
                              _isLogin
                                  ? 'E-Mail'
                                  : 'E-Mail (die E-Mail muss gleich verifiziert werden)',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator:
                            (v) =>
                                v != null && v.contains('@')
                                    ? null
                                    : 'Gültige E-Mail eingeben',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Passwort',
                        ),
                        obscureText: true,
                        validator:
                            (v) =>
                                v != null && v.length >= 6
                                    ? null
                                    : 'Mind. 6 Zeichen',
                      ),
                      if (!_isLogin)
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordRepeatController,
                              decoration: const InputDecoration(
                                labelText: 'Passwort wiederholen',
                              ),
                              obscureText: true,
                              validator: (v) {
                                if (_isLogin) return null;
                                if (v == null || v.isEmpty) {
                                  return 'Bitte wiederholen';
                                }
                                if (_passwordRepeatError != null) {
                                  return _passwordRepeatError;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      // Passwort vergessen Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                              authState.status == AuthStatus.loading
                                  ? null
                                  : () async {
                                    final email = await showDialog<String>(
                                      context: context,
                                      builder: (context) {
                                        final controller =
                                            TextEditingController(
                                              text: _emailController.text,
                                            );
                                        return AlertDialog(
                                          title: const Text(
                                            'Passwort zurücksetzen',
                                          ),
                                          content: TextField(
                                            controller: controller,
                                            decoration: const InputDecoration(
                                              labelText: 'E-Mail',
                                            ),
                                            keyboardType:
                                                TextInputType.emailAddress,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              child: const Text('Abbrechen'),
                                            ),
                                            ElevatedButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    controller.text.trim(),
                                                  ),
                                              child: const Text('Zurücksetzen'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (email != null && email.contains('@')) {
                                      await viewModel.sendPasswordResetEmail(
                                        email,
                                      );
                                    }
                                  },
                          child: const Text('Passwort vergessen?'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              authState.status == AuthStatus.loading
                                  ? null
                                  : () => _submit(viewModel),
                          child: Text(_isLogin ? 'Login' : 'Registrieren'),
                        ),
                      ),
                      TextButton(
                        onPressed:
                            () => setState(() {
                              _isLogin = !_isLogin;
                              _showVerificationNotice = false;
                            }),
                        child: Text(
                          _isLogin
                              ? 'Noch kein Konto? Registrieren'
                              : 'Schon registriert? Login',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Oder mit Social Login:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Google Login'),
                    onPressed:
                        authState.status == AuthStatus.loading
                            ? null
                            : () => _handleGoogle(viewModel),
                  ),
                ),
                if (authState.error != null && authState.error != 'success')
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      authState.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
