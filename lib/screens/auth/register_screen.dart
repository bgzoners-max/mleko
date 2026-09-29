import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../models/app_error.dart';
import '../../providers/app_state.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/beta_announcement_banner.dart';
import 'login_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 850;

    if (isDesktop) {
      final isDark = theme.brightness == Brightness.dark;
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/login'),
          title: const Text('Registracija'),
          actions: const [AppHomeButton()],
        ),
        body: Column(
          children: [
            const BetaAnnouncementBanner(),
            Expanded(
              child: Row(
                children: [
                  // Left Side: Marketing Content
                  Expanded(
                    flex: 6,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF03190B), // Najdublja smaragdno-crna
                            Color(0xFF072C15), // Duboka šumska zelena
                            Color(0xFF0E4521), // Topla priroda
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -80,
                            left: -80,
                            child: Container(
                              width: 360,
                              height: 360,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF2E7D32).withAlpha(85),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 30,
                            right: -60,
                            child: Container(
                              width: 380,
                              height: 380,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFFFB300).withAlpha(45),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Center(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 48, vertical: 36),
                              child: MarketingContent(isDesktop: true),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Right Side: Register Form
                  Expanded(
                    flex: 5,
                    child: Container(
                      color: isDark
                          ? theme.scaffoldBackgroundColor
                          : const Color(0xFFF7FAF7),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 32),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 36),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white12
                                      : const Color(0xFFE2EBE2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withAlpha(isDark ? 55 : 16),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Kreirajte nalog',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.onSurface,
                                      letterSpacing: -0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Pridružite se zajednici domaćih proizvođača i kupaca',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 28),
                                  _RegisterForm(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/login'),
        title: const Text('Registracija'),
        actions: const [AppHomeButton()],
      ),
      body: Column(
        children: [
          const BetaAnnouncementBanner(),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
            maxWidth: Breakpoints.authContentWidth(
              context,
              tabletWidth: 520,
              desktopWidth: 520,
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              Breakpoints.horizontalPadding(context),
              Breakpoints.adaptiveDouble(
                context,
                phone: 16,
                largeTabletValue: 24,
                desktop: 24,
              ),
              Breakpoints.horizontalPadding(context),
              Breakpoints.adaptiveDouble(
                context,
                phone: 24,
                largeTabletValue: 32,
                desktop: 32,
              ),
            ),
            child: _RegisterForm(),
          ),
        ),
      ),
    ),
  ],
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
  bool _privacyAccepted = false;

  // inline field errors
  String? _emailError;
  String? _phoneError;
  bool _checkingEmail = false;
  bool _checkingPhone = false;

  // Klijentski keš za proverene emailove i telefone (sprečava suvišne RPC pozive pri kretanju kroz formu)
  final Map<String, bool> _checkedEmails = {};
  final Map<String, bool> _checkedPhones = {};

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

    if (_checkedEmails.containsKey(email)) {
      setState(() => _emailError =
          _checkedEmails[email] == true ? 'Ova email adresa je već registrovana.' : null);
      return;
    }

    setState(() {
      _checkingEmail = true;
      _emailError = null;
    });
    try {
      final exists =
          await context.read<AppState>().authService.checkEmailExists(email);
      _checkedEmails[email] = exists;
      if (mounted) {
        setState(() => _emailError =
            exists ? 'Ova email adresa je već registrovana.' : null);
      }
    } catch (_) {
      // silent — server check failed ili rate-limited, submit će proveriti
    } finally {
      if (mounted) setState(() => _checkingEmail = false);
    }
  }

  Future<void> _onPhoneFocusChange() async {
    if (_phoneFocus.hasFocus) return;
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 6) return;

    if (_checkedPhones.containsKey(phone)) {
      setState(() => _phoneError =
          _checkedPhones[phone] == true ? 'Ovaj broj telefona je već registrovan.' : null);
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
          userFriendly =
              'Korisnik sa ovom email adresom već postoji. Prijavite se na svoj nalog.';
        } else if (raw.contains('phone') &&
            (raw.contains('23505') || raw.contains('unique'))) {
          userFriendly = 'Korisnik sa ovim brojem telefona već postoji.';
        } else {
          userFriendly = e.toString().replaceFirst('Exception: ', '');
        }

        setState(() => _submitError = userFriendly);
        final error = AppError.from(e,
            stackTrace: StackTrace.current,
            userMessage: userFriendly);
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
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withAlpha(45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha(35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.all_inclusive_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Jedinstveni nalog: možete slobodno kupovati hranu, objavljivati male oglase ili u bilo kom trenutku otvoriti profil gazdinstva.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ),
            ],
          ),
        ),

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
          decoration: const InputDecoration(
            labelText: 'Ime i prezime (opciono)',
            hintText: 'npr. Petar Petrović',
          ),
        ),
        const SizedBox(height: 12),

        // Phone
        TextField(
          controller: _phoneCtrl,
          focusNode: _phoneFocus,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Telefon *',
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

        // City
        TextField(
          controller: _cityCtrl,
          decoration: const InputDecoration(
            labelText: 'Grad / Mesto (opciono)',
            hintText: 'npr. Čačak, Valjevo...',
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
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      const TextSpan(text: 'Prihvatam '),
                      TextSpan(
                        text: 'Politiku privatnosti',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.push('/politika-privatnosti'),
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
          Text(_submitError!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _submit, child: const Text('Registruj se')),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/login');
            }
          },
          child: const Text('Već imaš nalog? Prijavi se'),
        ),
      ],
    );
  }
}
