import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system.dart';
import '../../core/responsive.dart';
import '../guest_auth_prompt.dart';

/// Razrešava najčešću zabunu korisnika: „Postavi oglas" vs. izlaganje
/// domaće hrane na Pijaci. Proizvođač hrane (sir, med, meso, zimnica...)
/// bira Pijacu, a sve ostalo (traktori, vozila, alati...) je mali oglas.
///
/// Desktop prikazuje dijalog, mobilni uređaji bottom-sheet — isti obrazac
/// kao `showGuestAuthPrompt`.
Future<void> showPublishChooserDialog(
  BuildContext context, {
  required bool isGuest,
  required bool isSeller,
}) {
  final isDesktop = Breakpoints.isDesktop(context);
  final content = PublishChooserContent(isGuest: isGuest, isSeller: isSeller);

  if (isDesktop) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusL),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.spaceXL),
            child: content,
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDesign.radiusL)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesign.spaceL,
        AppDesign.spaceS,
        AppDesign.spaceL,
        AppDesign.spaceL,
      ),
      child: content,
    ),
  );
}


class PublishChooserContent extends StatelessWidget {
  final bool isGuest;
  final bool isSeller;

  const PublishChooserContent({
    super.key,
    required this.isGuest,
    required this.isSeller,
  });

  void _chooseFood(BuildContext context) {
    Navigator.of(context).pop();
    if (isGuest) {
      showGuestAuthPrompt(
        context,
        title: 'Otvaranje online tezge',
        message:
            'Registrujte se ili prijavite da biste postavili svoje domaće proizvode i započeli prodaju direktno kupcima.',
        icon: Icons.storefront_rounded,
      );
    } else if (isSeller) {
      context.push('/add-product');
    } else {
      context.push('/becoming-seller');
    }
  }

  void _chooseClassified(BuildContext context) {
    Navigator.of(context).pop();
    if (isGuest) {
      showGuestAuthPrompt(
        context,
        title: 'Postavljanje oglasa',
        message:
            'Prijavite se ili se besplatno registrujte da biste besplatno postavili oglas ili ponudili domaće proizvode.',
        icon: Icons.campaign_rounded,
      );
    } else {
      context.go('/profile?section=new-classified');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Šta želite da objavite?',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDesign.spaceS),
        Text(
          'Domaći Market ima dva dela — Pijacu domaće hrane i besplatne Male oglase. Izaberite šta objavljujete:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDesign.spaceL),
        _ChooserOption(
          icon: Icons.agriculture_rounded,
          accentColor: const Color(0xFF245938),
          title: 'Domaća hrana sa gazdinstva',
          description:
              'Sir, kajmak, mleko, med, meso, zimnica, jaja, rakija... — izlaže se na Pijaci kroz vaš prodavnički profil, sa cenom i porudžbinama.',
          badge: 'PIJACA',
          onTap: () => _chooseFood(context),
        ),
        const SizedBox(height: AppDesign.spaceM),
        _ChooserOption(
          icon: Icons.campaign_rounded,
          accentColor: const Color(0xFFD97724),
          title: 'Sve ostalo — besplatan mali oglas',
          description:
              'Traktori, mašine, vozila, alati, tehnika, nekretnine, stvari za dom i decu... — 100% besplatan oglas sa direktnim kontaktom.',
          badge: 'MALI OGLASI',
          onTap: () => _chooseClassified(context),
        ),
        const SizedBox(height: AppDesign.spaceM),
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/vodic-za-proizvodjace');
          },
          icon: const Icon(Icons.menu_book_outlined, size: 16),
          label: const Text(
            'Ne znate gde šta ide? Pročitajte kratki vodič',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

/// Jedna opcija u izborniku — istaknuta kartica sa ikonicom i opisom.
class _ChooserOption extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final String badge;
  final VoidCallback onTap;

  const _ChooserOption({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 20, color: accentColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
