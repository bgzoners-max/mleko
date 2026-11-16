import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/app_error.dart';
import '../../providers/app_state.dart';
import '../error_dialog.dart';
import 'google_auth_button.dart';

/// Zajednička forma za registraciju (Google 1-klik registracija + klasična Email registracija).
class RegisterForm extends StatefulWidget {
  final VoidCallback? onSwitchToLogin;

  const RegisterForm({super.key, this.onSwitchToLogin});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();

  bool _obscure = true;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;

  String? _emailError;
  String? _phoneError;
  bool _checkingPhone = false;

  final Map<String, bool> _checkedPhones = {};
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
    // Anti-enumeration: ne proveravamo bazu na focus change da ne izlažemo orakl.
    setState(() => _emailError = null);
  }

  Future<void> _onPhoneFocusChange() async {
    if (_phoneFocus.hasFocus) return;
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 6) return;

    if (_checkedPhones.containsKey(phone)) {
      setState(() => _phoneError = _checkedPhones[phone] == true
          ? 'Ovaj broj telefona je već registrovan.'
          : null);
      return;
    }

    setState(() {
      _checkingPhone = true;
      _phoneError = null;
    });
    try {
      final exists =
          await context.read<AppState>().authService.checkPhoneExists(phone);
      _checkedPhones[phone] = exists;
      if (mounted) {
        setState(() => _phoneError =
            exists ? 'Ovaj broj telefona je već registrovan.' : null);
      }
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _checkingPhone = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitError = null);

    if (!_termsAccepted && !_privacyAccepted) {
      setState(() => _submitError =
          'Morate prihvatiti Uslove korišćenja i Politiku privatnosti.');
      return;
    }
    if (!_termsAccepted) {
      setState(() => _submitError = 'Morate prihvatiti Uslove korišćenja.');
      return;
    }
    if (!_privacyAccepted) {
      setState(() => _submitError = 'Morate prihvatiti Politiku privatnosti.');
      return;
    }
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.length < 6) {
      setState(
          () => _submitError = 'Email i lozinka (min 6 znakova) su obavezni.');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _submitError = 'Unesite ispravnu email adresu.');
      return;
    }
    if (_emailError != null || _phoneError != null) return;
    if (_phoneCtrl.text.trim().isEmpty) {
      setState(() => _submitError = 'Broj telefona je obavezan.');
      return;
    }

    context.read<AppState>().setLoading(true);
    try {
      await context.read<AppState>().authService.registerWithEmail(
            email,
            password,
            displayName:
                _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
            phone:
                _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
            city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
            isSeller: false,
          );
      if (mounted) {
        context.read<AppState>().markPendingEmailVerification();
        context.go('/verify-email', extra: email);
      }
    } on Exception catch (e) {
      if (mounted) {
        final raw = e.toString().toLowerCase();
        String userFriendly = 'Greška pri registraciji.';
        if (raw.contains('already registered') ||
            raw.contains('user already registered') ||
            (raw.contains('23505') && raw.contains('email'))) {
          context.read<AppState>().markPendingEmailVerification();
          context.go('/verify-email', extra: email);
          return;
        } else if (raw.contains('phone') &&
            (raw.contains('23505') || raw.contains('unique'))) {
          userFriendly = 'Korisnik sa ovim brojem telefona već postoji.';
        } else {
          userFriendly = e.toString().replaceFirst('Exception: ', '');
        }

        setState(() => _submitError = userFriendly);
        final error = AppError.from(
          e,
          stackTrace: StackTrace.current,
          userMessage: userFriendly,
        );
        await ErrorDialog.show(context, error: error, onRetry: _submit);
      }
    } finally {
      if (mounted) context.read<AppState>().setLoading(false);
    }
  }

  void _goToLogin() {
    if (widget.onSwitchToLogin != null) {
      widget.onSwitchToLogin!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/login');
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
                        const TextSpan(
                            text: 'Ova email adresa je već registrovana. '),
                        TextSpan(
                          text: 'Prijavite se?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                            fontSize: 12,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = _goToLogin,
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

  InputDecoration _fieldDecoration({
    required bool isDark,
    required String labelText,
    String? hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF1E241F) : const Color(0xFFF6F8F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white24 : const Color(0xFFD6DFD6),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white24 : const Color(0xFFD6DFD6),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF245938), width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAppLoading = context.select((AppState s) => s.isLoading);
    final isEmailTaken = _emailError == 'Ova email adresa je već registrovana.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withAlpha(45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withAlpha(35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.all_inclusive_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Jedinstveni nalog: možete slobodno kupovati hranu, objavljivati male oglase ili u bilo kom trenutku otvoriti profil gazdinstva.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),

        GoogleAuthButton(
          label: 'Registruj se putem Google-a',
          enabled: !isAppLoading,
          onError: (msg) => setState(() => _submitError = msg),
        ),
        const SizedBox(height: 16),

        Stack(
          alignment: Alignment.center,
          children: [
            const Divider(),
            Container(
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'ili klasična registracija',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _emailCtrl,
          focusNode: _emailFocus,
          enabled: !isAppLoading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _fieldDecoration(
            isDark: isDark,
            labelText: 'Email *',
            hintText: 'primer@email.com',
            prefixIcon: Icons.email_outlined,
            suffixIcon: _emailError != null
                ? const Icon(Icons.error, color: Colors.red)
                : null,
          ),
        ),
        if (_emailError != null)
          _fieldError(_emailError!, isEmailTaken: isEmailTaken),
        const SizedBox(height: 12),

        TextField(
          controller: _passwordCtrl,
          enabled: !isAppLoading,
          obscureText: _obscure,
          textInputAction: TextInputAction.next,
          decoration: _fieldDecoration(
            isDark: isDark,
            labelText: 'Lozinka * (min 6)',
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _nameCtrl,
          enabled: !isAppLoading,
          textInputAction: TextInputAction.next,
          decoration: _fieldDecoration(
            isDark: isDark,
            labelText: 'Ime i prezime (opciono)',
            hintText: 'npr. Petar Petrović',
            prefixIcon: Icons.person_outline,
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _phoneCtrl,
          focusNode: _phoneFocus,
          enabled: !isAppLoading,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: _fieldDecoration(
            isDark: isDark,
            labelText: 'Telefon *',
            hintText: 'npr. 064 123 4567',
            prefixIcon: Icons.phone_outlined,
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
        if (!_checkingPhone && _phoneError != null) _fieldError(_phoneError!),
        const SizedBox(height: 12),

        TextField(
          controller: _cityCtrl,
          enabled: !isAppLoading,
          textInputAction: TextInputAction.done,
          decoration: _fieldDecoration(
            isDark: isDark,
            labelText: 'Grad / Mesto (opciono)',
            hintText: 'npr. Čačak, Valjevo...',
            prefixIcon: Icons.location_city_outlined,
          ),
        ),
        const SizedBox(height: 14),

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
                    style: theme.textTheme.bodyMedium,
                    children: [
                      const TextSpan(text: 'Prihvatam '),
                      TextSpan(
                        text: 'Uslove korišćenja',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.push('/uslovi-koriscenja'),
                      ),
                      const TextSpan(
                        text:
                            ' i potvrđujem da su moji podaci tačni i da ću platformu koristiti u skladu sa važećim pravilima i zakonima.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _privacyAccepted,
              onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      const TextSpan(text: 'Prihvatam '),
                      TextSpan(
                        text: 'Politiku privatnosti',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap =
                              () => context.push('/politika-privatnosti'),
                      ),
                      const TextSpan(
                        text:
                            ' i saglasan/na sam da se moji podaci obrađuju na način opisan u tom dokumentu.',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
            ),
            child: Text(
              _submitError!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
        const SizedBox(height: 18),

        ElevatedButton(
          onPressed: isAppLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF245938),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isAppLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Registruj se',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Već imaš nalog?',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              TextButton(
                onPressed: _goToLogin,
                child: const Text(
                  'Prijavi se',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF245938),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
