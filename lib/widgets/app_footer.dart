import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/design_system.dart';
import 'contact_options_dialog.dart';
import 'instagram_icon.dart';

/// Vizuelno definisano, profesionalno podnožje (Footer) po svetskim standardima.
/// Sadrži brending, navigaciju, pravne informacije i kontakt/mreže na levoj strani.
class AppFooter extends StatelessWidget {
  final bool showDivider;
  final EdgeInsetsGeometry? padding;

  const AppFooter({
    super.key,
    this.showDivider = true,
    this.padding,
  });

  /// Pomoćni konstruktor za korišćenje unutar CustomScrollView sliver liste.
  static Widget sliver({
    bool showDivider = true,
    EdgeInsetsGeometry? padding,
  }) {
    return SliverToBoxAdapter(
      child: AppFooter(showDivider: showDivider, padding: padding),
    );
  }

  static Future<void> _openEmail(BuildContext context) async {
    await showContactOptionsDialog(context);
  }

  static Future<void> _openInstagram(BuildContext context) async {
    final uri = Uri.parse('https://instagram.com/domacimarket.rs');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nije moguće otvoriti Instagram stranicu.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nije moguće otvoriti Instagram stranicu.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Topla, zanatska paleta boja za definisanje pozadine podnožja
    final footerBg = isDark ? const Color(0xFF141C16) : const Color(0xFFF3EFE6);
    final border = isDark ? const Color(0xFF27382D) : const Color(0xFFE2DDD1);
    final textPrimary =
        isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary;
    final textSecondary =
        isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: footerBg,
        border: Border(
          top: BorderSide(
            color: border,
            width: 1.2,
          ),
        ),
      ),
      padding: padding ?? const EdgeInsets.fromLTRB(20, 36, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  if (width > 860) {
                    return _buildDesktopLayout(
                      context,
                      textPrimary,
                      textSecondary,
                      border,
                      isDark,
                    );
                  } else if (width > 560) {
                    return _buildTabletLayout(
                      context,
                      textPrimary,
                      textSecondary,
                      border,
                      isDark,
                    );
                  } else {
                    return _buildMobileLayout(
                      context,
                      textPrimary,
                      textSecondary,
                      border,
                      isDark,
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
              Divider(
                color: border.withValues(alpha: 0.8),
                height: 1,
                thickness: 0.8,
              ),
              const SizedBox(height: 20),
              _buildBottomBar(context, textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  // --- DESKTOP RASPODELA (4 kolone) ---
  Widget _buildDesktopLayout(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
    Color border,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: _buildBrandSection(context, textPrimary, textSecondary, isDark),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 2,
          child: _buildPlatformColumn(context, textSecondary),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: _buildLegalColumn(context, textSecondary),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: _buildContactSection(context, textSecondary, border, isDark),
        ),
      ],
    );
  }

  // --- TABLET RASPODELA (2x2) ---
  Widget _buildTabletLayout(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
    Color border,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBrandSection(context, textPrimary, textSecondary, isDark),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildPlatformColumn(context, textSecondary)),
            const SizedBox(width: 20),
            Expanded(child: _buildLegalColumn(context, textSecondary)),
            const SizedBox(width: 20),
            Expanded(
              child: _buildContactSection(context, textSecondary, border, isDark),
            ),
          ],
        ),
      ],
    );
  }

  // --- MOBILNA RASPODELA (Jedna pod drugu, čisto i pregledno) ---
  Widget _buildMobileLayout(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
    Color border,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBrandSection(context, textPrimary, textSecondary, isDark),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildPlatformColumn(context, textSecondary)),
            const SizedBox(width: 16),
            Expanded(child: _buildLegalColumn(context, textSecondary)),
          ],
        ),
        const SizedBox(height: 24),
        _buildContactSection(context, textSecondary, border, isDark),
      ],
    );
  }

  // --- BREND SEKCIJA (Levo) ---
  Widget _buildBrandSection(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/domaci_market_logo_v2.png',
              width: 38,
              height: 38,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AmazonColors.amber.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AmazonColors.amber.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AmazonColors.amber,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Domaći Market',
              style: AppFonts.display(
                textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Pijaca domaće hrane direktno sa seoskih gazdinstava i 100% besplatni mali oglasi u Srbiji. Bez provizije i trgovačkih marži.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildBadgeChip(
              context,
              '🌾 Provereno sa sela',
              isDark,
            ),
            _buildBadgeChip(
              context,
              '🤝 Bez posrednika',
              isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadgeChip(BuildContext context, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
        ),
      ),
    );
  }

  // --- KOLONA: PLATFORMA ---
  Widget _buildPlatformColumn(BuildContext context, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColumnHeader('PLATFORMA', textSecondary),
        const SizedBox(height: 8),
        _FooterLink(
          title: 'Početna',
          onTap: () => context.go('/'),
        ),
        _FooterLink(
          title: 'Pijaca hrane',
          onTap: () => context.push('/categories'),
        ),
        _FooterLink(
          title: 'Mali oglasi',
          onTap: () => context.push('/classifieds'),
        ),
        _FooterLink(
          title: 'Kako postaviti proizvode',
          onTap: () => context.push('/vodic-za-proizvodjace'),
        ),
        _FooterLink(
          title: 'Mapa gazdinstava',
          onTap: () => context.push('/sellers-map'),
        ),
      ],
    );
  }

  // --- KOLONA: INFORMACIJE & PRAVNO ---
  Widget _buildLegalColumn(BuildContext context, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColumnHeader('INFORMACIJE', textSecondary),
        const SizedBox(height: 8),
        _FooterLink(
          title: 'O platformi',
          onTap: () => context.push('/about'),
        ),
        _FooterLink(
          title: 'Podrška i pomoć',
          onTap: () => context.push('/support'),
        ),
        _FooterLink(
          title: 'Uslovi korišćenja',
          onTap: () => context.push('/uslovi-koriscenja'),
        ),
        _FooterLink(
          title: 'Politika privatnosti',
          onTap: () => context.push('/politika-privatnosti'),
        ),
      ],
    );
  }

  // --- KOLONA: KONTAKT & POVEŽIMO SE ---
  Widget _buildContactSection(
    BuildContext context,
    Color textSecondary,
    Color border,
    bool isDark,
  ) {
    final linkColor = isDark ? AmazonColors.amberLight : AmazonColors.link;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildColumnHeader('KONTAKT & MREŽE', textSecondary),
        const SizedBox(height: 10),
        _buildContactCard(
          context: context,
          icon: Icon(Icons.email_outlined, size: 18, color: linkColor),
          title: 'Email za kontakt',
          value: 'kontakt@domacimarket.rs',
          onTap: () => _openEmail(context),
          trailing: Tooltip(
            message: 'Kopiraj email adresu',
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => ContactOptionsDialog.copyEmail(context),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.copy_rounded,
                  size: 15,
                  color: linkColor.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
          linkColor: linkColor,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildContactCard(
          context: context,
          icon: const InstagramIcon(size: 18),
          title: 'Instagram profil',
          value: '@domacimarket.rs',
          onTap: () => _openInstagram(context),
          linkColor: linkColor,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required Widget icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    required Color linkColor,
    required bool isDark,
    Widget? trailing,
  }) {
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.07),
              width: 0.9,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AmazonColors.darkTextSecondary
                            : AmazonColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: linkColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnHeader(String title, Color textSecondary) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
        color: textSecondary,
      ),
    );
  }

  // --- SUB-FOOTER (Donja linija) ---
  Widget _buildBottomBar(BuildContext context, Color textSecondary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final copyright = Text(
          '© 2026 Domaći Market · Sva prava zadržana.',
          style: TextStyle(
            fontSize: 12,
            color: textSecondary.withValues(alpha: 0.85),
          ),
        );
        final tag = Text(
          'Direktno od domaćina · 100% domaće 🇷🇸',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textSecondary.withValues(alpha: 0.85),
          ),
        );

        return SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              copyright,
              tag,
            ],
          ),
        );
      },
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _FooterLink({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 3.5),
        minimumSize: const Size(0, 26),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.centerLeft,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
