import 'package:flutter/material.dart';

/// Amazon Marketplace paleta boja i tokeni za kompaktni prikaz malih oglasa.
class AmazonColors {
  // ── Primarna Amazon tamna paleta (zaglavlja, navigacija, akcenti) ──
  static const Color darkNavy = Color(0xFF131921); // Amazon Top Navbar / Banner
  static const Color navNavy = Color(0xFF232F3E); // Amazon Sub-nav / Bar
  static const Color slate = Color(0xFF37475A); // Amazon Slate siva / linije

  // ── Amazon topla jantarna / narandžasta paleta (CTA dugmad, isticanja) ──
  static const Color amber = Color(0xFFFF9900); // Amazon Smile Orange / CTA
  static const Color amberLight = Color(0xFFFEBD69); // Amazon Search Button / svetliji akcenat
  static const Color amberHover = Color(0xFFF3A847); // Amazon Button Hover
  static const Color amberDark = Color(0xFFC45500); // Amazon Border / Pressed

  // ── Cene i bedževi ──
  static const Color dealRed = Color(0xFFB12704); // Legendarna Amazon crvena za cene
  static const Color badgeRed = Color(0xFFCC0C39); // Amazon Deal / Hitno bedž
  static const Color gold = Color(0xFFFF9900); // Best Seller / Istaknuto
  static const Color green = Color(0xFF007600); // Amazon Dostupno / Novo stanje

  // ── Linkovi i interaktivni elementi ──
  static const Color link = Color(0xFF007185); // Amazon teal/plavi link
  static const Color linkHover = Color(0xFFC7511F); // Amazon link hover narandžasta

  // ── Podloge i kartice ──
  static const Color canvasLight = Color(0xFFEAEDED); // Amazon svetlo siva pozadina stranice
  static const Color cardWhite = Color(0xFFFFFFFF); // Čisto bela površina kartice
  static const Color borderGray = Color(0xFFD5D9D9); // Suptilna siva ivica
  static const Color borderSubtle = Color(0xFFE7E7E7); // Još nežnija linija razdvajanja

  // ── Tipografija ──
  static const Color textPrimary = Color(0xFF0F1111); // Skoro crna za maksimalnu čitljivost
  static const Color textSecondary = Color(0xFF565959); // Neutralna siva za lokaciju, vreme, valutu

  // ── Dark mode varijante ──
  static const Color darkCanvas = Color(0xFF0F141C);
  static const Color darkCard = Color(0xFF1A222D);
  static const Color darkBorder = Color(0xFF2E3A4B);
  static const Color darkTextPrimary = Color(0xFFF0F6FC);
  static const Color darkTextSecondary = Color(0xFF8B949E);

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
}
