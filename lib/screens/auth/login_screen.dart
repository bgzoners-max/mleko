import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/web_seo.dart';
import '../../models/app_error.dart';
import '../../providers/app_state.dart';
import '../../widgets/error_dialog.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 850;

    setPageMetadata(
      title: 'Prijava | Domaći market',
      description:
          'Prijavite se na Domaći market i povežite se sa lokalnim proizvođačima.',
      path: '/login',
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Left Side: Marketing Content
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF083313), // Deep forest green
                      Color(0xFF0F5A22), // Warm nature green
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                    child: MarketingContent(isDesktop: true),
                  ),
                ),
              ),
            ),
            // Right Side: Login Form
            Expanded(
              flex: 5,
              child: Container(
                color: theme.scaffoldBackgroundColor,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Dobrodošli nazad',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Prijavite se na svoj nalog',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          _LoginForm(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile/Tablet Layout
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const _MobileHeroSection(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _LoginForm(),
              ),
            ),
            const _TrustSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class MarketingContent extends StatelessWidget {
  final bool isDesktop;
  const MarketingContent({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/header_logo.png',
              height: 48,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Text(
              'Domaći market',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 64),
        Text(
          'Domaće, baš kako treba!',
          style: theme.textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Povežite se sa proverenim proizvođačima, otkrijte lokalnu ponudu i kupujte direktno od ljudi koji stoje iza svojih proizvoda.',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white.withAlpha(230), // 0.9 * 255
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 48),
        const AnimatedBenefit(
          delay: 200,
          child: BenefitItem(
            icon: Icons.verified_user_outlined,
            title: 'Provereni proizvođači',
            subtitle: 'Direktna saradnja sa lokalnim domaćinstvima.',
          ),
        ),
        const SizedBox(height: 24),
        const AnimatedBenefit(
          delay: 400,
          child: BenefitItem(
            icon: Icons.local_shipping_outlined,
            title: 'Direktna dostava',
            subtitle: 'Sveže namirnice direktno do vaših vrata.',
          ),
        ),
        const SizedBox(height: 24),
        const AnimatedBenefit(
          delay: 600,
          child: BenefitItem(
            icon: Icons.favorite_border,
            title: 'Podrška lokalu',
            subtitle: 'Kupovinom podržavate razvoj malih proizvođača.',
          ),
        ),
      ],
    );
  }
}

class AnimatedBenefit extends StatelessWidget {
  final int delay;
  final Widget child;

  const AnimatedBenefit({super.key, required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding:
            EdgeInsets.only(top: delay / 1000 * 20), // Fake delay via offset
        child: child,
      ),
    );
  }
}

class BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const BenefitItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(26), // 0.1 * 255
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha(179), // 0.7 * 255
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileHeroSection extends StatelessWidget {
  const _MobileHeroSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: const Color(0xFF0E521E),
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 48),
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 120,
          ),
          const SizedBox(height: 32),
          Text(
            'Domaće, baš kako treba!',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Otkrijte lokalne ukuse i povežite se sa proizvođačima.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(204), // 0.8 * 255
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustSection extends StatelessWidget {
  const _TrustSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 24),
          Text(
            'Domaći market okuplja:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          const _CheckItem('Proverene proizvođače'),
          const _CheckItem('Direktnu kupovinu bez preprodavaca'),
          const _CheckItem('Autentične domaće proizvode'),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String text;
  const _CheckItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
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
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login') ||
        msg.contains('invalid') ||
        msg.contains('wrong') ||
        msg.contains('credentials') ||
        msg.contains('email not confirmed') ||
        msg.contains('user not found')) {
      return 'Pogrešan email ili lozinka.';
    }
    if (msg.contains('email already') || msg.contains('already registered')) {
      return 'Nalog sa ovim email-om već postoji.';
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
    return 'Prijava nije uspela. Pokušaj ponovo.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _password,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Lozinka',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
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
                    content: Text('Link za reset je poslat na email')),
              );
            },
            child: const Text('Zaboravljena lozinka?'),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Prijavi se',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('ili',
                  style: TextStyle(
                      color:
                          theme.colorScheme.onSurfaceVariant.withAlpha(128))),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: _guestLoading ? null : _guest,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _guestLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Nastavi kao gost'),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Nemaš nalog?',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text('Registruj se',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.left,
          text: TextSpan(
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            children: [
              const TextSpan(text: 'Nastavkom prijave prihvatate naše '),
              TextSpan(
                text: 'Uslove korišćenja',
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => context.push('/uslovi-koriscenja'),
              ),
              const TextSpan(text: ' i '),
              TextSpan(
                text: 'Politiku privatnosti',
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => context.push('/politika-privatnosti'),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ],
    );
  }
}
