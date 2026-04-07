import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
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
    setState(() { _submitting = true; _error = null; });
    try {
      await Supabase.instance.client
          .from('waitlist')
          .insert({'email': email});
      if (mounted) setState(() => _submitted = true);
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() => _error = e.code == '23505'
            ? 'Ova adresa je već na listi. Hvala!'
            : 'Greška. Pokušajte ponovo.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      body: SingleChildScrollView(
        controller: _scrollCtrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(isWide: isWide),
            _HeroSection(isWide: isWide, theme: theme, onWaitlistTap: _scrollToWaitlist),
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
    return Container(
      color: const Color(0xFF1B5E20),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 64 : 24,
        vertical: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.eco, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                'Domaći market',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => context.go('/login'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Prijava', style: TextStyle(fontWeight: FontWeight.w600)),
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
  const _HeroSection({required this.isWide, required this.theme, required this.onWaitlistTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 64 : 24,
        vertical: isWide ? 80 : 56,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: isWide ? 180 : 140,
            height: isWide ? 180 : 140,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
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
            'Direktno sa sela\nna vaš sto',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isWide ? 48 : 32,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Vaša oaza domaće hrane — povežite se sa proverenim proizvođačima i uživajte u pravim ukusima.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: isWide ? 18 : 16,
              height: 1.6,
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
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1B5E20),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                child: const Text('Registrujte se'),
              ),
              OutlinedButton(
                onPressed: onWaitlistTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                child: const Text('Obavestite me kada platforma startuje'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Bez posrednika  •  Provereni proizvođači  •  Domaće i sveže',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              letterSpacing: 0.3,
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
    final isWide = MediaQuery.sizeOf(context).width >= 800;
    return Container(
      color: const Color(0xFFF9F6F0),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 64 : 24,
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              const Text(
                'Domaći market je platforma gde će biti:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1B1B),
                ),
              ),
              const SizedBox(height: 24),
              const _CheckItem('Provereni proizvođači'),
              const SizedBox(height: 12),
              const _CheckItem('Direktna kupovina bez preprodavaca'),
              const SizedBox(height: 12),
              const _CheckItem('Transparentno poreklo proizvoda'),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 22),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 16, color: Color(0xFF37434F)),
        ),
      ],
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;
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
              const Text(
                'Kako funkcioniše?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B1B1B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Jednostavno, bez filozofije.',
                style: TextStyle(fontSize: 14, color: Color(0xFF78909C)),
              ),
              const SizedBox(height: 36),
              isWide
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _StepCard(step: '1', title: 'Pronađite proizvođača', icon: Icons.search)),
                        SizedBox(width: 16),
                        Expanded(child: _StepCard(step: '2', title: 'Izaberite proizvode', icon: Icons.shopping_basket_outlined)),
                        SizedBox(width: 16),
                        Expanded(child: _StepCard(step: '3', title: 'Dogovorite kupovinu ili dostavu', icon: Icons.handshake_outlined)),
                      ],
                    )
                  : const Column(
                      children: [
                        _StepCard(step: '1', title: 'Pronađite proizvođača', icon: Icons.search),
                        SizedBox(height: 16),
                        _StepCard(step: '2', title: 'Izaberite proizvode', icon: Icons.shopping_basket_outlined),
                        SizedBox(height: 16),
                        _StepCard(step: '3', title: 'Dogovorite kupovinu ili dostavu', icon: Icons.handshake_outlined),
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
  const _StepCard({required this.step, required this.title, required this.icon});

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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Icon(icon, color: const Color(0xFF2E7D32), size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1B1B1B)),
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
    final isWide = MediaQuery.sizeOf(context).width >= 800;
    return Container(
      color: const Color(0xFF1B5E20),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 64 : 24,
        vertical: 56,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            children: [
              const Icon(Icons.mark_email_unread_outlined, color: Colors.white, size: 40),
              const SizedBox(height: 16),
              const Text(
                'Prijavite se prvi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ukoliko ste proizvođač, ostavite nam mail i bićete prvi koji će biti obavešten kada sajt krene da radi.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
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
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 24),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Hvala! Bićete među prvima obavešteni.',
                          style: TextStyle(
                            color: Colors.white,
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
                        style: const TextStyle(color: Color(0xFF0A0A0A)),
                        decoration: InputDecoration(
                          hintText: 'Vaša email adresa',
                          hintStyle: const TextStyle(color: Color(0xFF78909C)),
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
                          backgroundColor: const Color(0xFF8BC34A),
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
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco, color: Colors.white54, size: 18),
              SizedBox(width: 8),
              Text(
                'Domaći market',
                style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              children: [
                const TextSpan(text: '© 2026 Domaći market · '),
                TextSpan(
                  text: 'Uslovi korišćenja',
                  style: const TextStyle(
                    color: Colors.white54,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => context.push('/terms'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
