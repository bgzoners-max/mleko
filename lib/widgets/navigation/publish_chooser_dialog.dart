import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/design_system.dart';
import '../../providers/app_state.dart';
import '../guest_auth_prompt.dart';

/// Prikazuje adaptivni modal (Dialog na desktopu, BottomSheet na telefonu)
/// za jasan izbor između objave domaće hrane (Pijaca) i malih oglasa (sve ostalo).
Future<void> showPublishChooserDialog(BuildContext context) {
  final isWide = MediaQuery.sizeOf(context).width >= 600;

  if (isWide) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: PublishChooserDialog(),
      ),
    );
  } else {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PublishChooserDialog(isBottomSheet: true),
    );
  }
}

class PublishChooserDialog extends StatelessWidget {
  final bool isBottomSheet;

  const PublishChooserDialog({super.key, this.isBottomSheet = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isSideBySide = width >= 640 && !isBottomSheet;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isBottomSheet) ...[
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],

        // ── Zaglavlje modala ──
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? AmazonColors.amberLight.withValues(alpha: 0.14)
                    : const Color(0xFFFFE082).withValues(alpha: 0.35),
                shape: BoxShape.circle,
                border: isDark
                    ? Border.all(
                        color: AmazonColors.amberLight.withValues(alpha: 0.3),
                      )
                    : null,
              ),
              child: Icon(
                Icons.add_circle_outline_rounded,
                color: isDark ? AmazonColors.amberLight : AmazonColors.darkNavy,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Šta želite da ponudite?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: isDark
                          ? AmazonColors.darkTextPrimary
                          : AmazonColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Izaberite gde pripada vaša ponuda kako bi vas pravi kupci pronašli:',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? AmazonColors.darkTextSecondary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 20,
                color: isDark
                    ? AmazonColors.darkTextSecondary
                    : AmazonColors.textSecondary,
              ),
              tooltip: 'Zatvori',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // ── Dve jasne kartice za izbor ──
        if (isSideBySide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildFoodOption(context, theme, colorScheme, isDark),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildClassifiedsOption(
                      context, theme, colorScheme, isDark),
                ),
              ],
            ),
          )
        else ...[
          _buildFoodOption(context, theme, colorScheme, isDark),
          const SizedBox(height: 12),
          _buildClassifiedsOption(context, theme, colorScheme, isDark),
        ],

        const SizedBox(height: 12),
      ],
    );

    if (isBottomSheet) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AmazonColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: isDark
              ? const Border(
                  top: BorderSide(color: AmazonColors.darkBorder, width: 1),
                )
              : null,
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: SafeArea(child: SingleChildScrollView(child: content)),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AmazonColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AmazonColors.darkBorder : AmazonColors.borderSubtle,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(child: content),
      ),
    );
  }

  Widget _buildFoodOption(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    const primaryLight = Color(0xFF15803D); // Green 700
    const primaryDark = Color(0xFF4ADE80); // Green 400 (visok kontrast na tamnoj)
    const buttonBgDark = Color(0xFF16A34A); // Green 600
    const lightBg = Color(0xFFF0FDF4); // Green 50

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleFoodSelection(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF064E3B).withValues(alpha: 0.32)
                : lightBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF10B981).withValues(alpha: 0.45)
                  : const Color(0xFF86EFAC),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF065F46).withValues(alpha: 0.7)
                              : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                          border: isDark
                              ? Border.all(
                                  color: primaryDark.withValues(alpha: 0.35),
                                )
                              : null,
                        ),
                        child: Icon(
                          Icons.eco_rounded,
                          color: isDark ? primaryDark : primaryLight,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF065F46)
                                        .withValues(alpha: 0.85)
                                    : const Color(0xFFBBF7D0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Pijaca & Gazdinstva',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? const Color(0xFFA7F3D0)
                                      : primaryLight,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Domaća hrana',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? AmazonColors.darkTextPrimary
                                    : AmazonColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sir, kajmak, mleko, med, suvo meso, jaja, zimnica, voće i povrće, domaći sokovi...',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFD1FAE5)
                          : const Color(0xFF166534),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Online korpa i naručivanje direktno od kupaca\n• Profil vašeg poljoprivrednog gazdinstva i ocene',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? const Color(0xFFA7F3D0).withValues(alpha: 0.78)
                          : Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => _handleFoodSelection(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? buttonBgDark : primaryLight,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                label: const Text(
                  'Dodaj hranu na Pijacu',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassifiedsOption(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    const primaryLight = Color(0xFF1E40AF); // Blue 800
    const primaryDark = Color(0xFF60A5FA); // Blue 400 (visok kontrast na tamnoj)
    const buttonBgDark = Color(0xFF2563EB); // Blue 600
    const lightBg = Color(0xFFEFF6FF); // Blue 50

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleClassifiedsSelection(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E3A8A).withValues(alpha: 0.32)
                : lightBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.45)
                  : const Color(0xFF93C5FD),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E40AF).withValues(alpha: 0.65)
                              : const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(10),
                          border: isDark
                              ? Border.all(
                                  color: primaryDark.withValues(alpha: 0.35),
                                )
                              : null,
                        ),
                        child: Icon(
                          Icons.campaign_rounded,
                          color: isDark ? primaryDark : primaryLight,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E3A8A)
                                        .withValues(alpha: 0.85)
                                    : const Color(0xFFBFDBFE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Mali oglasnik',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? const Color(0xFFBFDBFE)
                                      : primaryLight,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Mali oglasi (Sve ostalo)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? AmazonColors.darkTextPrimary
                                    : AmazonColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Satovi, laptopovi, mobilni telefoni, kućni ljubimci, automobili, nameštaj, alati, nekretnine...',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFDBEAFE)
                          : const Color(0xFF1E3A8A),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Klasičan oglas sa fotografijama i opisom\n• Prikaz kontakt telefona i direktne poruke na sajtu',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? const Color(0xFFBFDBFE).withValues(alpha: 0.78)
                          : Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => _handleClassifiedsSelection(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? buttonBgDark : primaryLight,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                icon: const Icon(Icons.post_add_rounded, size: 16),
                label: const Text(
                  'Postavi mali oglas',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFoodSelection(BuildContext context) {
    Navigator.of(context).pop();
    final appState = context.read<AppState>();
    final user = appState.user;
    final isGuest = user == null || user.isGuest;

    if (isGuest) {
      showGuestAuthPrompt(
        context,
        title: 'Prodaja domaće hrane',
        message:
            'Prijavite se ili se besplatno registrujte da biste dodali domaće proizvode na Pijacu i započeli prodaju.',
        icon: Icons.storefront_rounded,
      );
    } else if (user.isSeller) {
      context.push('/add-product');
    } else {
      context.push('/becoming-seller');
    }
  }

  void _handleClassifiedsSelection(BuildContext context) {
    Navigator.of(context).pop();
    final appState = context.read<AppState>();
    final user = appState.user;
    final isGuest = user == null || user.isGuest;

    if (isGuest) {
      showGuestAuthPrompt(
        context,
        title: 'Postavljanje malog oglasa',
        message:
            'Prijavite se ili se besplatno registrujte da biste besplatno postavili oglas za satove, tehniku, ljubimce i druge stvari.',
        icon: Icons.campaign_rounded,
      );
    } else {
      context.go('/profile?section=new-classified');
    }
  }
}
