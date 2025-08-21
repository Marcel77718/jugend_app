import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';
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
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final viewModel = ref.read(authViewModelProvider.notifier);
    if (viewModel.isLogin) {
      await viewModel.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      await viewModel.signUpWithEmail(
        _emailController.text,
        _passwordController.text,
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    final viewModel = ref.read(authViewModelProvider.notifier);
    await viewModel.signInWithGoogle();
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte gib deine E-Mail-Adresse ein'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await ref
        .read(authViewModelProvider.notifier)
        .sendPasswordResetEmail(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.read(authViewModelProvider.notifier);
    final state = ref.watch(authViewModelProvider);

    if (state.status == AuthStatus.signedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          context.go('/');
        }
      });
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Willkommen',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
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
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Bitte gib eine E-Mail-Adresse ein'
                              : null,
                ),
                const SizedBox(height: 16),
                if (!viewModel.isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Bitte gib einen Namen ein'
                                : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Passwort',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Bitte gib ein Passwort ein'
                              : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed:
                      state.status == AuthStatus.loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      state.status == AuthStatus.loading
                          ? const CircularProgressIndicator()
                          : Text(
                            viewModel.isLogin ? 'Einloggen' : 'Registrieren',
                          ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed:
                      state.status == AuthStatus.loading
                          ? null
                          : _signInWithGoogle,
                  icon: Image.network(
                    'https://developers.google.com/identity/images/g-logo.png',
                    height: 24,
                    width: 24,
                  ),
                  label: const Text('Mit Google anmelden'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed:
                      state.status == AuthStatus.loading
                          ? null
                          : viewModel.toggleLoginMode,
                  child: Text(
                    viewModel.isLogin
                        ? 'Noch kein Konto? Registrieren'
                        : 'Bereits ein Konto? Einloggen',
                  ),
                ),
                if (viewModel.isLogin) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed:
                        state.status == AuthStatus.loading
                            ? null
                            : _resetPassword,
                    child: const Text('Passwort vergessen?'),
                  ),
                ],
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      state.error!,
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
