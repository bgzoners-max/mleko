import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/auth/marketing_content.dart';
import '../../widgets/auth/register_form.dart';
import '../../widgets/beta_announcement_banner.dart';

/// Samostalni ekran registracije (/register) koji deli jedinstvenu RegisterForm
/// komponentu (Google registracija + klasična Email registracija).
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
                  Expanded(
                    flex: 6,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF03190B),
                            Color(0xFF072C15),
                            Color(0xFF0E4521),
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
                                    'Pridružite se zajednici domaćih proizvođača i kupaca',
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  const RegisterForm(),
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
                  child: const RegisterForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
