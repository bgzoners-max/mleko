import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mleko/core/responsive.dart';
import 'package:mleko/core/web_seo.dart';
import '../models/app_error.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _emailCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _waitlistKey = GlobalKey();
  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  void _scrollToWaitlist() {
    final ctx = _waitlistKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _error = 'Unesite ispravnu email adresu.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.from('waitlist').insert({'email': email});
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        final appError = AppError.from(e);
        setState(() => _error = appError.type == ErrorType.conflict
            ? 'Ova adresa je već na listi. Hvala!'
            : appError.getUserMessage());
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    setPageMetadata(
      title: 'Domaće, baš kako treba! | domaćimarket.rs',
      description:
          'Domaće, baš kako treba! Povežite se sa proverenim proizvođačima i otkrijte lokalnu ponudu na domaćimarket.rs.',
      path: '/',
    );
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= Breakpoints.tablet;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      body: SingleChildScrollView(
        controller: _scrollCtrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(isWide: isWide),
            _HeroSection(
                isWide: isWide, theme: theme, onWaitlistTap: _scrollToWaitlist),
            const _TrustSection(),
            const _HowItWorksSection(),
            _WaitlistSection(
              key: _waitlistKey,
              emailCtrl: _emailCtrl,
              submitting: _submitting,
              submitted: _submitted,
              error: _error,
              onSubmit: _submit,
              theme: theme,
            ),
            _Footer(theme: theme),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isWide;
  const _Header({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: const Color(0xFF0E521E),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 64 : 24,
        vertical: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/header_logo.png',
                height: isWide ? 52 : 40,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Text(
                'Domaći market',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontSize: isWide ? 20 : 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          if (isWide) ...[
            TextButton(
              onPressed: () => context.push('/about'),
              child: Text('O platformi',
                  style: TextStyle(color: theme.colorScheme.onPrimary)),
            ),
            TextButton(
              onPressed: () => context.push('/support'),
              child: Text('Podrška',
                  style: TextStyle(color: theme.colorScheme.onPrimary)),
            ),
            TextButton(
              onPressed: () => context.push('/uslovi-koriscenja'),
              child: Text('Uslovi korišćenja',
                  style: TextStyle(color: theme.colorScheme.onPrimary)),
            ),
            TextButton(
              onPressed: () => context.push('/politika-privatnosti'),
              child: Text('Politika privatnosti',
                  style: TextStyle(color: theme.colorScheme.onPrimary)),
            ),
            const SizedBox(width: 8),
          ],
          TextButton(
            onPressed: () => context.go('/login'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onPrimary,
              backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Prijava',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool isWide;
  final ThemeData theme;
  final VoidCallback onWaitlistTap;
  const _HeroSection(
      {required this.isWide, required this.theme, required this.onWaitlistTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 64 : 24,
          vertical: isWide ? 80 : 56,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: isWide ? 360 : 280,
              height: isWide ? 360 : 280,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Uskoro dostupno',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Domaće, baš kako treba!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontSize: isWide ? 48 : 32,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Povežite se sa proverenim proizvođačima, otkrijte lokalnu ponudu i kupujte direktno od ljudi koji stoje iza svojih proizvoda.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.92),
                fontSize: isWide ? 18 : 16,
                height: 1.6,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: () => context.go('/register'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.onPrimary,
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  child: const Text('Registrujte se'),
                ),
                OutlinedButton(
                  onPressed: onWaitlistTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onPrimary,
                    side: BorderSide(
                        color: theme.colorScheme.onPrimary, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  child: const Text('Obavestite me kada platforma startuje'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Domaće, baš kako treba!  •  Provereni proizvođači  •  Lokalna ponuda',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.65),
                fontSize: 13,
                letterSpacing: 0.3,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustSection extends StatelessWidget {
  const _TrustSection();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 64 : 24,
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              Text(
                'Domaći market okuplja:',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 24),
              const _CheckItem('Proverene proizvođače i autentične proizvode'),
              const SizedBox(height: 12),
              const _CheckItem('Direktnu kupovinu bez preprodavaca'),
              const SizedBox(height: 12),
              const _CheckItem('Jasno poreklo i direktan kontakt'),
              const SizedBox(height: 28),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Uskoro dostupno u celoj Srbiji',
                  style: TextStyle(
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String text;
  const _CheckItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle,
            color: Theme.of(context).colorScheme.secondary, size: 22),
        const SizedBox(width: 10),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.sizeOf(context).width >= Breakpoints.tablet;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 64 : 24,
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Text(
                'Kako funkcioniše?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Jednostavno, pregledno i direktno.',
                style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 36),
              isWide
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: _StepCard(
                                step: '1',
                                title: 'Pronađite lokalnu ponudu',
                                icon: Icons.search)),
                        SizedBox(width: 16),
                        Expanded(
                            child: _StepCard(
                                step: '2',
                                title: 'Izaberite proizvode',
                                icon: Icons.shopping_basket_outlined)),
                        SizedBox(width: 16),
                        Expanded(
                            child: _StepCard(
                                step: '3',
                                title: 'Dogovorite kupovinu ili preuzimanje',
                                icon: Icons.handshake_outlined)),
                      ],
                    )
                  : const Column(
                      children: [
                        _StepCard(
                            step: '1',
                            title: 'Pronađite lokalnu ponudu',
                            icon: Icons.search),
                        SizedBox(height: 16),
                        _StepCard(
                            step: '2',
                            title: 'Izaberite proizvode',
                            icon: Icons.shopping_basket_outlined),
                        SizedBox(height: 16),
                        _StepCard(
                            step: '3',
                            title: 'Dogovorite kupovinu ili preuzimanje',
                            icon: Icons.handshake_outlined),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final IconData icon;
  const _StepCard(
      {required this.step, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Icon(icon, color: const Color(0xFF2E7D32), size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B1B1B)),
          ),
        ],
      ),
    );
  }
}

class _WaitlistSection extends StatelessWidget {
  final TextEditingController emailCtrl;
  final bool submitting;
  final bool submitted;
  final String? error;
  final VoidCallback onSubmit;
  final ThemeData theme;

  const _WaitlistSection({
    super.key,
    required this.emailCtrl,
    required this.submitting,
    required this.submitted,
    required this.error,
    required this.onSubmit,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.sizeOf(context).width >= Breakpoints.tablet;
    return Container(
      color: theme.colorScheme.primary,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 64 : 24,
        vertical: 56,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            children: [
              const Icon(Icons.mark_email_unread_outlined,
                  color: Colors.white, size: 40), // Keep white for contrast
              const SizedBox(height: 16),
              Text(
                'Prijavite se prvi',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ostavite nam email i bićete među prvima obavešteni kada platforma krene, bilo da želite da kupujete ili da ponudite svoje proizvode.',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.88),
                  fontSize: 16,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (submitted) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.white,
                          size: 24), // Keep white for contrast
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Hvala! Bićete među prvima obavešteni.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Vaša email adresa',
                          hintStyle: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          errorText: error,
                        ),
                        onSubmitted: (_) => onSubmit(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: submitting ? null : onSubmit,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.tertiary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Prijavi se',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final ThemeData theme;
  const _Footer({required this.theme});

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment:
            isWide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isWide ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Image.asset('assets/images/header_logo.png',
                  height: 22,
                  width: 22,
                  fit: BoxFit.contain),
              const SizedBox(width: 8),
              Text(
                'Domaći market',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: isWide ? TextAlign.center : TextAlign.left,
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                  fontSize: 12),
              children: [
                const TextSpan(text: '© 2026 Domaći market · '),
                TextSpan(
                  text: 'Uslovi korišćenja',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => context.push('/uslovi-koriscenja'),
                ),
                const TextSpan(text: ' · '),
                TextSpan(
                  text: 'Politika privatnosti',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => context.push('/politika-privatnosti'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
