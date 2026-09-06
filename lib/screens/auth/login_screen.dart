import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/web_seo.dart';
import '../../models/app_error.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/app_state.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/home/market_mode_switcher.dart';

Future<void> _enterAsGuestWithMode(
    BuildContext context, MarketMode mode) async {
  final appState = context.read<AppState>();
  context.read<AppSettingsProvider>().setMarketMode(mode);
  if (appState.user != null) {
    context.go('/');
    return;
  }
  try {
    await appState.authService
        .signInAsGuest()
        .timeout(const Duration(seconds: 8));
    if (context.mounted) context.go('/');
  } catch (_) {
    if (context.mounted) context.go('/');
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 850;

    setPageMetadata(
      title: 'Prijava | Pijaca hrane & Mali oglasi | Domaći Market',
      description:
          'Prijavite se na Domaći Market – berzu domaće hrane sa gazdinstava i oglasnik za sve i svašta (tehnika, vozila, nekretnine, alati).',
      path: '/login',
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Levi panel: Prezentacija dve celine (Pijaca hrane + Mali oglasi)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF06230C), // Duboka tamnozelena
                      Color(0xFF0F5A22), // Topla šumska zelena
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
            // Desni panel: Forma za prijavu
            Expanded(
              flex: 5,
              child: Container(
                color: theme.scaffoldBackgroundColor,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 24),
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

    // Mobilni i tablet prikaz
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const _MobileHeroSection(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
        // Zaglavlje brenda
        Row(
          children: [
            Image.asset(
              'assets/images/header_logo.png',
              height: 48,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Domaći market',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Pijaca domaće hrane & Mali oglasi',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withAlpha(204),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 36),

        // Glavni naslov
        Text(
          'Dve celine na\njednom mestu',
          style: theme.textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Kupujte autentičnu domaću hranu direktno sa gazdinstava ili pretražujte i oglašavajte sve i svašta — od tehnike, telefona i automobila, do nekretnina i alata.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withAlpha(225),
            height: 1.45,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 32),

        // Celina 1: Pijaca domaće hrane
        _PillarCard(
          icon: Icons.cottage_rounded,
          badgeText: '100% DOMAĆE',
          badgeColor: const Color(0xFF2E7D32),
          title: 'Pijaca domaće hrane',
          subtitle: 'Sveže sa seoskih poljoprivrednih gazdinstava',
          bullets: const [
            'Domaći sir, kajmak, mleko, med i suhomesnato',
            'Sezonsko voće, povrće, zimnica i prirodni sokovi',
            'Direktna kupovina od seljaka bez posrednika',
          ],
          actionLabel: 'Istraži Pijacu hrane →',
          onAction: () => _enterAsGuestWithMode(context, MarketMode.foodMarket),
        ),
        const SizedBox(height: 20),

        // Celina 2: Mali oglasi
        _PillarCard(
          icon: Icons.campaign_rounded,
          badgeText: 'SVE NA JEDNOM MESTU',
          badgeColor: const Color(0xFFE65100),
          title: 'Mali oglasi',
          subtitle: 'Kupujte i prodajte sve i svašta',
          bullets: const [
            'Mobilni telefoni, računari, tehnika i bela tehnika',
            'Automobili, motori, auto-delovi i oprema',
            'Nekretnine, nameštaj, mašine, alati, odeća i usluge',
          ],
          actionLabel: 'Pregledaj Male oglase →',
          onAction: () => _enterAsGuestWithMode(context, MarketMode.classifieds),
        ),
        const SizedBox(height: 28),

        // Bedževi poverenja na dnu
        const Row(
          children: [
            _MiniTrustChip(
                icon: Icons.verified_outlined, label: 'Bez posrednika'),
            SizedBox(width: 14),
            _MiniTrustChip(
                icon: Icons.add_circle_outline, label: 'Besplatni oglasi'),
            SizedBox(width: 14),
            _MiniTrustChip(
                icon: Icons.handshake_outlined, label: 'Direktan kontakt'),
          ],
        ),
      ],
    );
  }
}

class _PillarCard extends StatelessWidget {
  final IconData icon;
  final String badgeText;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final String actionLabel;
  final VoidCallback onAction;

  const _PillarCard({
    required this.icon,
    required this.badgeText,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(22), // 0.08 * 255
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withAlpha(46), // 0.18 * 255
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(36),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withAlpha(190),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(80),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withAlpha(60),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF81C784),
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(
                        color: Colors.white.withAlpha(220),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withAlpha(30),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTrustChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniTrustChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withAlpha(200), size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(210),
            fontSize: 12,
            fontWeight: FontWeight.w500,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF06230C),
            Color(0xFF0E521E),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/header_logo.png',
                height: 40,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Text(
                'Domaći market',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Pijaca domaće hrane &\nMali oglasi',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Domaća hrana sa gazdinstava i oglasnik za sve i svašta.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(204),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _QuickMobilePill(
                  icon: Icons.cottage_rounded,
                  title: 'Pijaca hrane',
                  subtitle: 'Sa sela',
                  badgeColor: const Color(0xFF2E7D32),
                  onTap: () =>
                      _enterAsGuestWithMode(context, MarketMode.foodMarket),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickMobilePill(
                  icon: Icons.campaign_rounded,
                  title: 'Mali oglasi',
                  subtitle: 'Sve i svašta',
                  badgeColor: const Color(0xFFE65100),
                  onTap: () =>
                      _enterAsGuestWithMode(context, MarketMode.classifieds),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickMobilePill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color badgeColor;
  final VoidCallback onTap;

  const _QuickMobilePill({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(28),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withAlpha(48),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: badgeColor.withAlpha(90),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 12),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 20),
          Text(
            'Domaći market okuplja dve celine',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          // Blok 1: Pijaca hrane
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cottage_rounded,
                        color: Color(0xFF1B5E20), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Pijaca domaće hrane',
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const _CheckItem(
                    'Direktna saradnja sa lokalnim seoskim domaćinstvima'),
                const _CheckItem(
                    'Sir, kajmak, med, suvo meso, voće, povrće i zimnica'),
                const _CheckItem('100% domaći ukusi bez trgovačkih marži'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Blok 2: Mali oglasi
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.campaign_rounded,
                        color: Color(0xFFE65100), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Mali oglasi za sve i svašta',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const _CheckItem(
                    'Mobilni telefoni, računari, tehnika i bela tehnika'),
                const _CheckItem(
                    'Automobili, motori, nekretnine, alati i nameštaj'),
                const _CheckItem('Besplatno i jednostavno postavljanje oglasa'),
              ],
            ),
          ),
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
          const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
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

  Future<void> _guestWithMode(MarketMode mode) async {
    context.read<AppSettingsProvider>().setMarketMode(mode);
    await _guest();
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
              child: Text('ili istraži bez prijave',
                  style: TextStyle(
                      fontSize: 13,
                      color:
                          theme.colorScheme.onSurfaceVariant.withAlpha(150))),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _guestLoading ? null : _guest,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
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
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _guestLoading
                    ? null
                    : () => _guestWithMode(MarketMode.foodMarket),
                icon: const Icon(Icons.cottage_outlined, size: 16),
                label: const Text(
                  'Pijaca hrane',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton.icon(
                onPressed: _guestLoading
                    ? null
                    : () => _guestWithMode(MarketMode.classifieds),
                icon: const Icon(Icons.campaign_outlined, size: 16),
                label: const Text(
                  'Mali oglasi',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
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
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(179),
                fontSize: 11,
              ),
              children: [
                const TextSpan(
                    text: 'Nastavkom prijave prihvatate naše '),
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
    );
  }
}
