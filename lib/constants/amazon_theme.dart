import 'package:flutter/material.dart';

/// Autentična "Craft & Heritage" paleta boja i tokeni za Domaći Market.
///
/// Istorijsko ime `AmazonColors` zadržano je kao alias radi kompatibilnosti;
/// novi kod treba da koristi [AppPalette].
typedef AppPalette = AmazonColors;

class AmazonColors {
  // ── Primarna tamna šumska paleta (zaglavlja, navigacija, akcenti) ──
  static const Color darkNavy = Color(0xFF142419); // Duboka šumska mahovina
  static const Color navNavy = Color(0xFF1E3424); // Šumski bor / Sub-nav
  static const Color slate = Color(0xFF384A3E); // Maslinasto-grafitna siva / linije

  // ── Topla jantarna / medena paleta (CTA dugmad, isticanja) ──
  static const Color amber = Color(0xFFD97724); // Domaći med / zrelo žito
  static const Color amberLight = Color(0xFFE89844); // Svetlo žito / akcenat
  static const Color amberHover = Color(0xFFC66900); // Topli pečeni med
  static const Color amberDark = Color(0xFFA65300); // Tamna karamela

  // ── Cene i bedževi ──
  static const Color dealRed = Color(0xFF9E3D24); // Bogata topla terakota / pečena glina
  static const Color badgeRed = Color(0xFFB33320); // Domaći sveži plodovi
  static const Color gold = Color(0xFFD48B38); // Zlatno polje / istaknuto
  static const Color green = Color(0xFF2E7D32); // Prirodna livada / sveže

  // ── Linkovi i interaktivni elementi ──
  static const Color link = Color(0xFF245938); // Prirodna tamnozelena šuma
  static const Color linkHover = Color(0xFFC66900); // Topla ćilibarska

  // ── Podloge i kartice ──
  static const Color canvasLight = Color(0xFFF8F6F0); // Topli ton nebeljenog lana / papira
  static const Color cardWhite = Color(0xFFFFFFFF); // Čista površina kartice
  static const Color borderGray = Color(0xFFEAE5D9); // Blaga topla boja gline i peska
  static const Color borderSubtle = Color(0xFFF2EFE8); // Suptilna unutrašnja linija

  // ── Tipografija ──
  static const Color textPrimary = Color(0xFF1B201C); // Topla ugljena za prirodnu čitljivost
  static const Color textSecondary = Color(0xFF626C61); // Topla kadulja siva za metapodatke

  // ── Dark mode varijante (topla noćna šuma) ──
  static const Color darkCanvas = Color(0xFF121714);
  static const Color darkCard = Color(0xFF1B241E);
  static const Color darkBorder = Color(0xFF2B3A30);
  static const Color darkTextPrimary = Color(0xFFF1F5F2);
  static const Color darkTextSecondary = Color(0xFF98A69A);

  // ── Svetle varijante za visoku čitljivost u tamnoj temi (WCAG AAA) ──
  static const Color lightGreen = Color(0xFF81C784); // Svetlo zelena za tamnu temu (kontrast >8.5:1)
  static const Color lightYellow = Color(0xFFFFD54F); // Svetlo žuta / toplo zlato

  // Helper metode za dinamički odabir svetlo/tamno
  static Color getCanvas(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkCanvas : canvasLight;
  }

  static Color getCardSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkCard : cardWhite;
  }

  static Color getBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBorder : borderGray;
  }

  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : textPrimary;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : textSecondary;
  }

  static Color getLink(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? lightGreen : link;
  }

  static Color getGreen(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? lightGreen : green;
  }

  /// Meka, difuzna organska senka za kartice
  static List<BoxShadow> getCardShadow(BuildContext context, {bool isHovered = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: isHovered ? 0.35 : 0.2),
          blurRadius: isHovered ? 16 : 8,
          offset: Offset(0, isHovered ? 6 : 2),
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF142419).withValues(alpha: isHovered ? 0.09 : 0.04),
        blurRadius: isHovered ? 18 : 8,
        offset: Offset(0, isHovered ? 6 : 2),
      ),
    ];
  }
}
