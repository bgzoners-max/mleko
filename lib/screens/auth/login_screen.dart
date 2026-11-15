import 'package:flutter/material.dart';

import '../../core/web_seo.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/auth/login_form.dart';
import '../../widgets/auth/marketing_content.dart';
import '../../widgets/auth/mobile_marketing_content.dart';
import '../../widgets/auth/register_form.dart';
import '../../widgets/beta_announcement_banner.dart';

enum AuthTab { register, login }

class LoginScreen extends StatefulWidget {
  final AuthTab initialTab;

  const LoginScreen({super.key, this.initialTab = AuthTab.login});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late AuthTab _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _activeTab = widget.initialTab;
    }
  }

  void _setTab(AuthTab tab) {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final isDark = theme.brightness == Brightness.dark;
    final isRegister = _activeTab == AuthTab.register;

    setPageMetadata(
      title: isRegister
          ? 'Registracija | Pijaca hrane & Mali oglasi | Domaći Market'
          : 'Prijava | Pijaca hrane & Mali oglasi | Domaći Market',
      description:
          'Registrujte se ili prijavite na Domaći Market – berzu domaće hrane sa gazdinstava i besplatni oglasnik za sve i svašta (tehnika, vozila, nekretnine, alati). 100% besplatno postavljanje i obnavljanje oglasa.',
      path: isRegister ? '/login?tab=register' : '/login',
    );

    if (isDesktop) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/'),
          title: Text(isRegister ? 'Registracija' : 'Prijava'),
          actions: const [AppHomeButton()],
        ),
        body: Column(
          children: [
            const BetaAnnouncementBanner(),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF021B0B),
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
                  Expanded(
                    flex: 5,
                    child: Container(
                      color: isDark
                          ? theme.scaffoldBackgroundColor
                          : const Color(0xFFF7FAF7),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 28),
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
                              child: _AuthCardBody(
                                activeTab: _activeTab,
                                isDesktop: true,
                                onTabChanged: _setTab,
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
        leading: const AppBackButton(fallbackRoute: '/'),
        title: Text(isRegister ? 'Registracija' : 'Prijava'),
        actions: const [AppHomeButton()],
      ),
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF9F6F0),
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
                  constraints: const BoxConstraints(maxWidth: 460),
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
                    child: _AuthCardBody(
                      activeTab: _activeTab,
                      isDesktop: false,
                      onTabChanged: _setTab,
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

class _AuthCardBody extends StatelessWidget {
  final AuthTab activeTab;
  final bool isDesktop;
  final ValueChanged<AuthTab> onTabChanged;

  const _AuthCardBody({
    required this.activeTab,
    required this.isDesktop,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRegister = activeTab == AuthTab.register;
    final titleStyle = (isDesktop
            ? theme.textTheme.headlineMedium
            : theme.textTheme.titleLarge)
        ?.copyWith(
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSurface,
      letterSpacing: isDesktop ? -0.5 : -0.4,
      fontSize: isDesktop ? null : 21,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuthTabSwitcher(
          activeTab: activeTab,
          onChanged: onTabChanged,
        ),
        SizedBox(height: isDesktop ? 22 : 18),
        Text(
          isRegister ? 'Kreirajte nalog' : 'Dobrodošli nazad',
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isDesktop ? 6 : 4),
        Text(
          isRegister
              ? 'Registrujte se putem Google-a ili klasične forme'
              : 'Prijavite se na svoj nalog',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: isDesktop ? null : 13,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isDesktop ? 22 : 18),
        if (isRegister)
          RegisterForm(onSwitchToLogin: () => onTabChanged(AuthTab.login))
        else
          LoginForm(onSwitchToRegister: () => onTabChanged(AuthTab.register)),
      ],
    );
  }
}

class _AuthTabSwitcher extends StatelessWidget {
  final AuthTab activeTab;
  final ValueChanged<AuthTab> onChanged;

  const _AuthTabSwitcher({
    required this.activeTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final containerBg =
        isDark ? const Color(0xFF1A221C) : const Color(0xFFEEF4EE);
    final borderColor =
        isDark ? Colors.white12 : const Color(0xFFD3E2D4);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AuthTabSegment(
              label: 'Registruj se',
              icon: Icons.person_add_alt_1_rounded,
              selected: activeTab == AuthTab.register,
              isDark: isDark,
              onTap: () => onChanged(AuthTab.register),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _AuthTabSegment(
              label: 'Prijava',
              icon: Icons.login_rounded,
              selected: activeTab == AuthTab.login,
              isDark: isDark,
              onTap: () => onChanged(AuthTab.login),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTabSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _AuthTabSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : (isDark ? Colors.white70 : const Color(0xFF245938));

    return Material(
      color: selected ? const Color(0xFF245938) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: fg),
                const SizedBox(width: 6),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
