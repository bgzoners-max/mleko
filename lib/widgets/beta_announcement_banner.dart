import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/design_system.dart';
import '../core/responsive.dart';
import '../providers/app_settings_provider.dart';

/// Prikazuje diskretnu gornju traku koja obaveštava korisnike da je platforma
/// u fazi aktivnog testiranja i izrade, uz mogućnost zatvaranja i pregleda detalja.
class BetaAnnouncementBanner extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const BetaAnnouncementBanner({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    final dismissed = context.select<AppSettingsProvider, bool>(
      (s) => s.betaNoticeDismissed,
    );

    if (dismissed) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = Breakpoints.isDesktop(context);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.8)
            : colorScheme.primaryContainer.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppDesign.spaceL : AppDesign.spaceM,
        vertical: isDesktop ? AppDesign.spaceS : 6.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              // Raketica / ikonica
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  size: 15,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppDesign.spaceM),
              // Tekst poruke
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12.5,
                      height: 1.3,
                      color: colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: 'Domaći Market je u fazi testiranja i izrade. ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: isDesktop
                            ? 'Registracija i prijava su otvorene za sve posetioce. '
                            : 'Registracija je otvorena. ',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppDesign.spaceS),
              // Akcija: Saznaj više
              InkWell(
                onTap: () => showBetaInfoDialog(context),
                borderRadius: BorderRadius.circular(AppDesign.radiusS),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Saznaj više',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Dugme za zatvaranje
              IconButton(
                icon: const Icon(Icons.close_rounded),
                iconSize: 17,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                tooltip: 'Zatvori obaveštenje',
                color: colorScheme.onSurfaceVariant,
                onPressed: () {
                  context.read<AppSettingsProvider>().dismissBetaNotice();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mali stilizovani bedž 'BETA' koji se prikazuje pored logotipa
/// i otvara informativni modal na dodir/klik.
class BetaBadge extends StatelessWidget {
  final bool showInfoIcon;

  const BetaBadge({super.key, this.showInfoIcon = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'Sajt je u fazi testiranja i izrade – kliknite za detalje',
      child: InkWell(
        onTap: () => showBetaInfoDialog(context),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BETA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: colorScheme.primary,
                ),
              ),
              if (showInfoIcon) ...[
                const SizedBox(width: 3),
                Icon(
                  Icons.info_outline_rounded,
                  size: 11,
                  color: colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Prikazuje detaljan informativni modal o statusu platforme
void showBetaInfoDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const BetaInfoDialog(),
  );
}

/// Detaljan informativni modal o trenutnoj fazi platforme
class BetaInfoDialog extends StatelessWidget {
  const BetaInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.radiusXL),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.spaceXL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Zaglavlje
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppDesign.radiusM),
                      ),
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        size: 26,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppDesign.spaceM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Domaći Market',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const BetaBadge(showInfoIcon: false),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Platforma u fazi testiranja i izrade',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Zatvori',
                    ),
                  ],
                ),
                const SizedBox(height: AppDesign.spaceL),

                // Kartica 1: Šta je aktivno
                _buildInfoCard(
                  context: context,
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: Colors.green,
                  title: 'Šta već možete da koristite:',
                  body:
                      '• Registracija i prijava: Možete slobodno kreirati nalog kao kupac ili domaći proizvođač.\n'
                      '• Istraživanje ponude: Pregled sveže domaće hrane i raznovrsnih malih oglasa.\n'
                      '• Oglasi i proizvodi: Postavljanje, izmena i upravljanje vašom ponudom.\n'
                      '• Pretraga i filteri: Filtriranje po gradovima, regionima i kategorijama.',
                  isDark: isDark,
                ),
                const SizedBox(height: AppDesign.spaceM),

                // Kartica 2: Šta je u izradi
                _buildInfoCard(
                  context: context,
                  icon: Icons.construction_rounded,
                  iconColor: Colors.amber.shade800,
                  title: 'Trenutno u izradi i testiranju:',
                  body:
                      '• Pojedine napredne funkcije, automatizacije i analitika se kontinuirano unapređuju.\n'
                      '• Baza domaćinstava, prodavaca i proizvoda se svakodnevno proširuje novim podacima.\n'
                      '• Moguće su povremene estetske i funkcionalne nadogradnje bez prekida rada.',
                  isDark: isDark,
                ),
                const SizedBox(height: AppDesign.spaceM),

                // Kartica 3: Povratne informacije
                _buildInfoCard(
                  context: context,
                  icon: Icons.favorite_outline_rounded,
                  iconColor: colorScheme.primary,
                  title: 'Vaš utisak nam puno znači!',
                  body:
                      'Ukoliko primetite bilo kakvu grešku, nelogičnost ili imate ideju kako da Domaći Market bude još bolji, bićemo zahvalni na vašoj povratnoj informaciji putem Korisničke podrške.',
                  isDark: isDark,
                ),
                const SizedBox(height: AppDesign.spaceXL),

                // Dugme na dnu
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Razumem, nastavi ka sajtu'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDesign.radiusM),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceM),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDesign.radiusM),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: AppDesign.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.4,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
