import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';
import 'package:jugend_app/core/snackbar_helper.dart';
import 'package:jugend_app/core/performance_monitor.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordRepeatController.dispose();
    super.dispose();
  }

  void _submit(AuthViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;
    if (!viewModel.isLogin) {
      if (_passwordController.text != _passwordRepeatController.text) {
        viewModel.setPasswordRepeatError('Passwörter stimmen nicht überein');
        return;
      } else {
        viewModel.setPasswordRepeatError(null);
      }
    }
    final locale = Localizations.localeOf(context).languageCode;
    if (viewModel.isLogin) {
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
      viewModel.setShowVerificationNotice(true);
      SnackbarHelper.success(
        context,
        'Verifizierungs-E-Mail wurde gesendet. Bitte prüfe deine E-Mails.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final viewModel = ref.watch(authViewModelProvider.notifier);

    // Automatische Navigation nach Login
    if (authState.status == AuthStatus.signedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.settings.name != '/') {
          // GoRouter verwenden
          if (mounted) {
            context.go('/');
          }
        }
      });
    }

    return PerformanceWidget(
      name: 'AuthScreen',
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Zurück',
            onPressed: () => context.go('/'),
          ),
          title: const Text('Anmeldung'),
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (viewModel.showVerificationNotice)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Bitte bestätige deine E-Mail-Adresse. Prüfe deine E-Mails und klicke auf den Bestätigungslink.',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-Mail',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte gib deine E-Mail-Adresse ein';
                    }
                    if (!value.contains('@')) {
                      return 'Bitte gib eine gültige E-Mail-Adresse ein';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Passwort',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte gib dein Passwort ein';
                    }
                    if (!viewModel.isLogin && value.length < 6) {
                      return 'Das Passwort muss mindestens 6 Zeichen lang sein';
                    }
                    return null;
                  },
                ),
                if (!viewModel.isLogin) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordRepeatController,
                    decoration: InputDecoration(
                      labelText: 'Passwort wiederholen',
                      border: const OutlineInputBorder(),
                      errorText: viewModel.passwordRepeatError,
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte wiederhole dein Passwort';
                      }
                      return null;
                    },
                  ),
                ],
                if (viewModel.isLogin) ...[
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
                                    final controller = TextEditingController(
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
                                          border: OutlineInputBorder(),
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
                                                controller.text,
                                              ),
                                          child: const Text('Senden'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (email != null && email.contains('@')) {
                                  await viewModel.sendPasswordResetEmail(email);
                                }
                              },
                      child: const Text('Passwort vergessen?'),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        authState.status == AuthStatus.loading
                            ? null
                            : () => _submit(viewModel),
                    child: Text(viewModel.isLogin ? 'Login' : 'Registrieren'),
                  ),
                ),
                const SizedBox(height: 16),
                // Google Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    onPressed:
                        authState.status == AuthStatus.loading
                            ? null
                            : () async {
                              await ref
                                  .read(authViewModelProvider.notifier)
                                  .signInWithGoogle();
                            },
                    label: const Text('Mit Google anmelden'),
                  ),
                ),
                if (authState.status == AuthStatus.loading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (authState.error != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      authState.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextButton(
                  onPressed: () => viewModel.toggleLoginMode(),
                  child: Text(
                    viewModel.isLogin
                        ? 'Noch kein Konto? Registrieren'
                        : 'Schon registriert? Login',
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
