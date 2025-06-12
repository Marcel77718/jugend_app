import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/auth_view_model.dart';

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
    final state = ref.read(authViewModelProvider);

    if (state.isLogin) {
      await viewModel.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      await viewModel.register(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
      );
    }
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
        .resetPassword(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    final viewModel = ref.read(authViewModelProvider.notifier);

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
                if (state.showVerificationNotice)
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
                  validator: viewModel.validateEmail,
                ),
                const SizedBox(height: 16),
                if (!state.isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: viewModel.validateName,
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
                  validator: viewModel.validatePassword,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: state.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      state.isLoading
                          ? const CircularProgressIndicator()
                          : Text(state.isLogin ? 'Einloggen' : 'Registrieren'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: state.isLoading ? null : viewModel.toggleLoginMode,
                  child: Text(
                    state.isLogin
                        ? 'Noch kein Konto? Registrieren'
                        : 'Bereits ein Konto? Einloggen',
                  ),
                ),
                if (state.isLogin) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: state.isLoading ? null : _resetPassword,
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
