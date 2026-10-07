import 'dart:async';
import 'package:flutter/gestures.dart';
import '../../providers/app_settings_provider.dart';
import '../../services/core/logger_service.dart';
import 'guest_quick_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_error.dart';
import '../../providers/app_state.dart';
import '../error_dialog.dart';
import 'google_icon.dart';
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _error;
  final bool _guestLoading = false;
  bool _googleLoading = false;

  // Zaštita od brute-force pogađanja lozinki
  int _failedAttempts = 0;
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;
  bool get _isLockedOut => _lockoutSeconds > 0;
  static const int _maxFailedAttempts = 5;

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _startLockout(int seconds) {
    _lockoutTimer?.cancel();
    setState(() {
      _lockoutSeconds = seconds;
      _error =
          'Previše neuspešnih pokušaja. Sačekajte $seconds sekundi pre ponovnog pokušaja.';
    });
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_lockoutSeconds <= 1) {
        timer.cancel();
        setState(() {
          _lockoutSeconds = 0;
          _error = null;
        });
      } else {
        setState(() {
          _lockoutSeconds--;
          _error =
              'Previše neuspešnih pokušaja. Sačekajte $_lockoutSeconds sekundi pre ponovnog pokušaja.';
        });
      }
    });
  }

  Future<void> _submit() async {
    if (_isLockedOut) {
      setState(() => _error =
          'Previše neuspešnih pokušaja. Sačekajte $_lockoutSeconds sekundi pre ponovnog pokušaja.');
      return;
    }

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
      _failedAttempts = 0;
      _lockoutTimer?.cancel();
      _lockoutSeconds = 0;
      if (mounted) {
        final returnTo = GoRouterState.of(context).uri.queryParameters['returnTo'];
        context.go(returnTo ?? '/');
      }
    } on Exception catch (e) {
      if (mounted) {
        _failedAttempts++;
        if (_failedAttempts >= _maxFailedAttempts) {
          _startLockout(30);
        }
        final errorMsg = _formatAuthError(e);
        setState(() => _error = errorMsg);
        final error = AppError.from(e,
            stackTrace: StackTrace.current, userMessage: errorMsg);
        await ErrorDialog.show(context,
            error: error, onRetry: _isLockedOut ? null : _submit);
      }
    } finally {
      if (mounted) context.read<AppState>().setLoading(false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLockedOut) return;
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    try {
      await context.read<AppState>().authService.signInWithGoogle();
    } on Exception catch (e) {
      if (mounted) {
        final errorMsg = _formatAuthError(e);
        setState(() => _error = errorMsg);
        final error = AppError.from(e,
            stackTrace: StackTrace.current, userMessage: errorMsg);
        await ErrorDialog.show(context,
            error: error, onRetry: _signInWithGoogle);
      }
    } finally {
      if (mounted) {
        setState(() => _googleLoading = false);
      }
    }
  }

  Future<void> _guestWithMode(MarketMode mode) async {
    unawaited(context.read<AppSettingsProvider>().setMarketMode(mode));
    await _guest();
  }

  Future<void> _guest() async {
    final appState = context.read<AppState>();
    if (appState.authService.currentSupabaseUser?.isAnonymous == true) {
      try {
        await appState.authService.signOut();
      } catch (e) {
        LoggerService.warning('signOut guest failed in _guest', extra: {'error': e.toString()});
      }
    }
    if (mounted) {
      try {
        context.go('/');
      } catch (e) {
        LoggerService.warning('Navigation to / failed in _guest', extra: {'error': e.toString()});
      }
    }
  }

  String _formatAuthError(Exception e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login') ||
        msg.contains('invalid') ||
        msg.contains('wrong') ||
        msg.contains('credentials') ||
        msg.contains('email not confirmed') ||
        msg.contains('user not found') ||
        msg.contains('email already') ||
        msg.contains('already registered')) {
      return 'Pogrešan email ili lozinka.';
    }
    if (msg.contains('network') ||
        msg.contains('socketexception') ||
        msg.contains('connection') ||
        msg.contains('failed to fetch') ||
        msg.contains('xmlhttprequest')) {
      return 'Nema internet veze. Proveri konekciju i pokušaj ponovo.';
    }
    if (msg.contains('too many') || msg.contains('rate limit')) {
      return 'Previše pokušaja. Sačekaj nekoliko minuta i pokušaj ponovo.';
    }
    if (msg.contains('cancel') ||
        msg.contains('aborted') ||
        msg.contains('closed') ||
        msg.contains('interrupted')) {
      return 'Prijava putem Google-a je prekinuta.';
    }
    return 'Prijava nije uspela. Pokušaj ponovo.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAppLoading = context.watch<AppState>().isLoading;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _email,
            enabled: !_isLockedOut && !isAppLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'primer@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF1E241F) : const Color(0xFFF6F8F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFD6DFD6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFD6DFD6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF245938), width: 1.8),
              ),
            ),
            onSubmitted: (_) => _isLockedOut || isAppLoading ? null : _submit(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            enabled: !_isLockedOut && !isAppLoading,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Lozinka',
              prefixIcon: const Icon(Icons.lock_outline),
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF1E241F) : const Color(0xFFF6F8F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFD6DFD6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFD6DFD6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF245938), width: 1.8),
              ),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Prikaži lozinku' : 'Sakrij lozinku',
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: _isLockedOut || isAppLoading
                    ? null
                    : () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _isLockedOut || isAppLoading ? null : _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLockedOut || isAppLoading
                  ? null
                  : () {
                      if (_email.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Unesite email za reset lozinke')),
                        );
                        return;
                      }
                      context
                          .read<AppState>()
                          .authService
                          .sendPasswordReset(_email.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Ukoliko nalog sa ovom adresom postoji, link za reset je poslat na email')),
                      );
                    },
              child: Text(
                'Zaboravljena lozinka?',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: (_isLockedOut || isAppLoading) ? null : _submit,
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
                : Text(
                    _isLockedOut
                        ? 'Pokušajte ponovo za $_lockoutSeconds s'
                        : 'Prijavi se',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: (_isLockedOut || isAppLoading || _googleLoading)
                ? null
                : _signInWithGoogle,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor:
                  isDark ? const Color(0xFF242A25) : Colors.white,
              foregroundColor:
                  isDark ? Colors.white : const Color(0xFF1F2937),
              side: BorderSide(
                color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _googleLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const GoogleLogo(size: 20),
            label: const Text(
              'Nastavi putem Google-a',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ili',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 14),

          // Dva privlačna tastera za izbor režima kao gost
          Row(
            children: [
              Expanded(
                child: GuestQuickCard(
                  icon: Icons.cottage_rounded,
                  title: 'Pijaca hrane',
                  subtitle: 'Domaće sa sela',
                  color: const Color(0xFF2E7D32),
                  isLoading: _guestLoading,
                  onTap: () => _guestWithMode(MarketMode.foodMarket),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GuestQuickCard(
                  icon: Icons.campaign_rounded,
                  title: 'Mali oglasi',
                  subtitle: 'Besplatno',
                  color: const Color(0xFFE65100),
                  isLoading: _guestLoading,
                  onTap: () => _guestWithMode(MarketMode.classifieds),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _guestLoading ? null : _guest,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
              ),
              child: _guestLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text(
                      'Pregledaj sajt bez prijave →',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Nemaš nalog?',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              TextButton(
                onPressed: () => context.push('/register'),
                child: const Text('Registruj se',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF245938))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(179),
                  fontSize: 11,
                ),
                children: [
                  const TextSpan(text: 'Nastavkom prijave prihvatate naše '),
                  TextSpan(
                    text: 'Uslove korišćenja',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => context.push('/uslovi-koriscenja'),
                  ),
                  const TextSpan(text: ' i '),
                  TextSpan(
                    text: 'Politiku privatnosti',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => context.push('/politika-privatnosti'),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

