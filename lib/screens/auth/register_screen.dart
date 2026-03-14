import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/app_error.dart';
import '../../providers/app_state.dart';
import '../../widgets/error_dialog.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registracija')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _RegisterForm(),
      ),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  bool _obscure = true;
  String? _error;
  // false = kupac, true = prodavac
  bool _isSeller = false;

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_email.text.trim().isEmpty || _password.text.length < 6) {
      setState(() => _error = 'Email i lozinka (min 6 znakova) su obavezni.');
      return;
    }
    if (_isSeller &&
        (_phone.text.trim().isEmpty ||
            _city.text.trim().isEmpty ||
            _name.text.trim().isEmpty)) {
      setState(() =>
          _error = 'Za prodavca su obavezni ime, telefon i mesto/gazdinstvo.');
      return;
    }
    context.read<AppState>().setLoading(true);
    try {
      await context.read<AppState>().authService.registerWithEmail(
            _email.text.trim(),
            _password.text,
            displayName: _name.text.trim().isEmpty ? null : _name.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            city: _city.text.trim().isEmpty ? null : _city.text.trim(),
            isSeller: _isSeller,
            farmName: _isSeller ? _name.text.trim() : null,
            location: _isSeller ? _city.text.trim() : null,
          );
      if (mounted) context.go('/');
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
        final error = AppError.from(e,
            stackTrace: StackTrace.current,
            userMessage: 'Greška pri registraciji.');
        await ErrorDialog.show(context, error: error, onRetry: _submit);
      }
    } finally {
      if (mounted) context.read<AppState>().setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          'Tip naloga',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Kupac')),
            ButtonSegment(value: true, label: Text('Prodavac')),
          ],
          selected: {_isSeller},
          onSelectionChanged: (s) => setState(() => _isSeller = s.first),
        ),
        const SizedBox(height: 16),
        TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email *')),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Lozinka * (min 6)',
            suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: _isSeller ? 'Ime / Naziv gazdinstva *' : 'Ime (opciono)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: _isSeller ? 'Telefon *' : 'Telefon (opciono)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _city,
          decoration: InputDecoration(
            labelText: _isSeller ? 'Mesto / Region *' : 'Grad (opciono)',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _submit, child: const Text('Registruj se')),
        const SizedBox(height: 12),
        TextButton(
            onPressed: () => context.pop(),
            child: const Text('Već imaš nalog? Prijavi se')),
      ],
    );
  }
}
