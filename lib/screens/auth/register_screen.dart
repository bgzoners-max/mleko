import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../models/app_error.dart';
import '../../providers/app_state.dart';
import '../../widgets/error_dialog.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registracija')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: Breakpoints.isTabletOrLarger(context) ? 520 : double.infinity),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Breakpoints.horizontalPadding(context)),
            child: _RegisterForm(),
          ),
        ),
      ),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();

  bool _obscure = true;
  bool _termsAccepted = false;
  bool _isSeller = false;

  // inline field errors
  String? _emailError;
  String? _phoneError;
  bool _checkingEmail = false;
  bool _checkingPhone = false;

  // form-level submit error
  String? _submitError;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onEmailFocusChange);
    _phoneFocus.addListener(_onPhoneFocusChange);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _emailFocus
      ..removeListener(_onEmailFocusChange)
      ..dispose();
    _phoneFocus
      ..removeListener(_onPhoneFocusChange)
      ..dispose();
    super.dispose();
  }

  Future<void> _onEmailFocusChange() async {
    if (_emailFocus.hasFocus) return;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Unesite ispravnu email adresu.');
      return;
    }
    setState(() { _checkingEmail = true; _emailError = null; });
    try {
      final exists = await context.read<AppState>().authService.checkEmailExists(email);
      if (mounted) {
        setState(() => _emailError = exists
            ? 'Ova email adresa je već registrovana.'
            : null);
      }
    } catch (_) {
      // silent — server check failed, submit will catch it
    } finally {
      if (mounted) setState(() => _checkingEmail = false);
    }
  }

  Future<void> _onPhoneFocusChange() async {
    if (_phoneFocus.hasFocus) return;
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    setState(() { _checkingPhone = true; _phoneError = null; });
    try {
      final exists = await context.read<AppState>().authService.checkPhoneExists(phone);
      if (mounted) {
        setState(() => _phoneError = exists
            ? 'Ovaj broj telefona je već registrovan.'
            : null);
      }
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _checkingPhone = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitError = null);

    if (!_termsAccepted) {
      setState(() => _submitError = 'Morate prihvatiti Uslove korišćenja.');
      return;
    }
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.length < 6) {
      setState(() => _submitError = 'Email i lozinka (min 6 znakova) su obavezni.');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _submitError = 'Unesite ispravnu email adresu.');
      return;
    }
    if (_emailError != null || _phoneError != null) return;
    if (_isSeller &&
        (_phoneCtrl.text.trim().isEmpty ||
            _cityCtrl.text.trim().isEmpty ||
            _nameCtrl.text.trim().isEmpty)) {
      setState(() =>
          _submitError = 'Za prodavca su obavezni ime, telefon i mesto/gazdinstvo.');
      return;
    }

    context.read<AppState>().setLoading(true);
    try {
      await context.read<AppState>().authService.registerWithEmail(
            email,
            password,
            displayName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
            city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
            isSeller: _isSeller,
            farmName: _isSeller ? _nameCtrl.text.trim() : null,
            location: _isSeller ? _cityCtrl.text.trim() : null,
          );
      if (mounted) {
        context.read<AppState>().markPendingEmailVerification();
        context.go('/verify-email', extra: email);
      }
    } on Exception catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        setState(() => _submitError = msg);
        final error = AppError.from(e,
            stackTrace: StackTrace.current,
            userMessage: 'Greška pri registraciji.');
        await ErrorDialog.show(context, error: error, onRetry: _submit);
      }
    } finally {
      if (mounted) context.read<AppState>().setLoading(false);
    }
  }

  Widget _fieldError(String msg, {bool isEmailTaken = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: Colors.red),
          const SizedBox(width: 4),
          Expanded(
            child: isEmailTaken
                ? RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      children: [
                        const TextSpan(text: 'Ova email adresa je već registrovana. '),
                        TextSpan(
                          text: 'Prijavite se?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                            fontSize: 12,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.go('/login'),
                        ),
                      ],
                    ),
                  )
                : Text(msg,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _checkingIndicator() => const Padding(
        padding: EdgeInsets.only(top: 4, left: 4),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            SizedBox(width: 6),
            Text('Provera...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isEmailTaken = _emailError == 'Ova email adresa je već registrovana.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text('Tip naloga', style: Theme.of(context).textTheme.labelLarge),
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

        // Email
        TextField(
          controller: _emailCtrl,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email *',
            errorText: null,
            suffixIcon: _checkingEmail
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _emailError != null
                    ? const Icon(Icons.error, color: Colors.red)
                    : null,
          ),
        ),
        if (_checkingEmail) _checkingIndicator(),
        if (!_checkingEmail && _emailError != null)
          _fieldError(_emailError!, isEmailTaken: isEmailTaken),
        const SizedBox(height: 12),

        // Password
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Lozinka * (min 6)',
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Name
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: _isSeller ? 'Ime / Naziv gazdinstva *' : 'Ime (opciono)',
          ),
        ),
        const SizedBox(height: 12),

        // Phone
        TextField(
          controller: _phoneCtrl,
          focusNode: _phoneFocus,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: _isSeller ? 'Telefon *' : 'Telefon (opciono)',
            suffixIcon: _checkingPhone
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _phoneError != null
                    ? const Icon(Icons.error, color: Colors.red)
                    : null,
          ),
        ),
        if (_checkingPhone) _checkingIndicator(),
        if (!_checkingPhone && _phoneError != null)
          _fieldError(_phoneError!),
        const SizedBox(height: 12),

        // City
        TextField(
          controller: _cityCtrl,
          decoration: InputDecoration(
            labelText: _isSeller ? 'Mesto / Region *' : 'Grad (opciono)',
          ),
        ),
        const SizedBox(height: 16),

        // Terms checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _termsAccepted,
              onChanged: (v) => setState(() => _termsAccepted = v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      const TextSpan(text: 'Prihvatam '),
                      TextSpan(
                        text: 'Uslove korišćenja',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.push('/terms'),
                      ),
                      const TextSpan(
                        text:
                            ' i potvrđujem da su moji proizvodi u skladu sa važećim zakonima i zdravstveno ispravni.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        if (_submitError != null) ...[
          const SizedBox(height: 12),
          Text(_submitError!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _submit, child: const Text('Registruj se')),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Već imaš nalog? Prijavi se'),
        ),
      ],
    );
  }
}
