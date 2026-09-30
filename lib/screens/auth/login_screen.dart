import '../../widgets/auth/marketing_content.dart';
import '../../widgets/auth/mobile_marketing_content.dart';
import '../../widgets/auth/login_form.dart';
import 'package:flutter/material.dart';
import '../../core/web_seo.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/beta_announcement_banner.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final isDark = theme.brightness == Brightness.dark;

    setPageMetadata(
      title: 'Prijava | Pijaca hrane & Mali oglasi | Domaći Market',
      description:
          'Prijavite se na Domaći Market – berzu domaće hrane sa gazdinstava i besplatni oglasnik za sve i svašta (tehnika, vozila, nekretnine, alati). 100% besplatno postavljanje i obnavljanje oglasa.',
      path: '/login',
    );

    if (isDesktop) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/'),
          title: const Text('Prijava'),
          actions: const [AppHomeButton()],
        ),
        body: Column(
          children: [
            const BetaAnnouncementBanner(),
            Expanded(
              child: Row(
                children: [
                  // Levi panel: Prezentacija platforme (Glassmorphism Showcase)
                  Expanded(
                    flex: 7,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF021B0B), // Najdublja smaragdna
                            Color(0xFF072C15), // Šumska zelena
                            Color(0xFF0E4521), // Topla priroda
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Ambijentalni sjaj 1 (gornji levi)
                          Positioned(
                            top: -90,
                            left: -90,
                            child: Container(
                              width: 380,
                              height: 380,
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
                          // Ambijentalni sjaj 2 (donji desni)
                          Positioned(
                            bottom: 20,
                            right: -70,
                            child: Container(
                              width: 400,
                              height: 400,
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
                          // Sadržaj
                          const Center(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 36, vertical: 28),
                              child: MarketingContent(isDesktop: true),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Desni panel: Forma za prijavu u fokusiranoj kartici
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
                                horizontal: 24, vertical: 24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 32),
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
                                        .withAlpha(isDark ? 55 : 14),
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
                                    'Dobrodošli nazad',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.onSurface,
                                      letterSpacing: -0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Prijavite se na svoj nalog',
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 26),
                                  const LoginForm(),
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

    // Mobilni i tablet prikaz (Mobile First)
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/'),
        title: const Text('Prijava'),
        actions: const [AppHomeButton()],
      ),
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF9F6F0),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const BetaAnnouncementBanner(),
              const MobileHeroSection(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isDark ? Colors.white12 : const Color(0xFFE2EBE2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 45 : 12),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Dobrodošli nazad',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.4,
                            fontSize: 21,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Prijavite se na svoj nalog',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),
                        const LoginForm(),
                      ],
                    ),
                  ),
                ),
              ),
              const MobileShowcaseSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

