import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../models/app_error.dart';
import '../../providers/app_state.dart';
import '../../widgets/error_dialog.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prijava')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _LoginForm(),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _error;
  bool _guestLoading = false;

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Unesite email i lozinku.');
      return;
    }
    context.read<AppState>().setLoading(true);
    try {
      await context.read<AppState>().authService.signInWithEmail(
            _email.text.trim(),
            _password.text,
          );
      if (mounted) context.go('/');
    } on Exception catch (e) {
      if (mounted) {
        final error = AppError.from(e,
            stackTrace: StackTrace.current, userMessage: _formatAuthError(e));
        await ErrorDialog.show(context, error: error, onRetry: _submit);
      }
    } finally {
      if (mounted) context.read<AppState>().setLoading(false);
    }
  }

  Future<void> _guest() async {
    setState(() {
      _error = null;
      _guestLoading = true;
    });
    context.read<AppState>().setLoading(true);
    try {
      await context
          .read<AppState>()
          .authService
          .signInAsGuest()
          .timeout(const Duration(seconds: 10));
      if (mounted) context.go('/');
    } on TimeoutException catch (e) {
      if (mounted) {
        const msg =
            'Prijava kao gost traje predugo. Proveri internet i Supabase konfiguraciju.';
        setState(() {
          _error = msg;
          _guestLoading = false;
        });
        final error =
            AppError.from(e, stackTrace: StackTrace.current, userMessage: msg);
        await ErrorDialog.show(context, error: error, onRetry: _guest);
      }
    } on Exception catch (e) {
      if (mounted) {
        final msg = _formatAuthError(e);
        setState(() {
          _error = msg;
          _guestLoading = false;
        });
        final error =
            AppError.from(e, stackTrace: StackTrace.current, userMessage: msg);
        await ErrorDialog.show(context, error: error, onRetry: _guest);
      }
    } finally {
      if (mounted) {
        context.read<AppState>().setLoading(false);
        setState(() => _guestLoading = false);
      }
    }
  }

  String _formatAuthError(Exception e) {
    final msg = e.toString();
    if (msg.contains('Invalid login') || msg.contains('invalid')) {
      return 'Pogrešan email ili lozinka.';
    }
    if (msg.contains('anonymous') || msg.contains('Anonymous')) {
      return 'Prijava kao gost nije omogućena. Proveri Supabase Auth podešavanja.';
    }
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Greška mreže. Proveri internet i Supabase konfiguraciju.';
    }
    return msg.replaceFirst('Exception: ', '').split('\n').first;
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrLarger = Breakpoints.isTabletOrLarger(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTabletOrLarger ? 420 : double.infinity,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Lozinka',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _submit, child: const Text('Prijavi se')),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text('Nemaš nalog? Registruj se'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _guestLoading ? null : _guest,
              child: _guestLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Nastavi kao gost (samo pregled proizvoda)'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                if (_email.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unesite email za reset lozinke')),
                  );
                  return;
                }
                context
                    .read<AppState>()
                    .authService
                    .sendPasswordReset(_email.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Link za reset je poslat na email')),
                );
              },
              child: const Text('Zaboravljena lozinka'),
            ),
          ],
        ),
      ),
    );
  }
}
