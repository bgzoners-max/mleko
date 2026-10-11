import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

export '../constants/amazon_theme.dart' show AmazonColors;

/// Tipografski tokeni: serif (Bitter) za naslove, sans (Roboto) za tekst.
///
/// Bitter je topli, zanatski slab-serif koji "Domaćem Marketu" daje karakter
/// nasleđa i sela, uz potpunu podršku za srpske dijakritike (č, ć, š, ž, đ).
/// Roboto ostaje radni konj za sitne, guste tekstove gde je čitljivost
/// kritična (cene, metapodaci, forme, dugmad).
class AppFonts {
  AppFonts._();

  /// Naslov sekcije ili ekrana — topli zanatski serif (Bitter).
  static TextStyle display(
    Color color, {
    double fontSize = 17,
    FontWeight fontWeight = FontWeight.w700,
    double height = 1.3,
    double letterSpacing = -0.1,
  }) {
    // Bitter bundle u assets/google_fonts sadrži: Regular (w400), Medium (w500),
    // SemiBold (w600) i Bold (w700). Za veće težine (w800, w900) mapiramo na w700
    // kako google_fonts ne bi bacao runtime Exception za nepostojeće Bitter-ExtraBold/Black.
    final resolvedWeight = fontWeight.value > FontWeight.w700.value
        ? FontWeight.w700
        : (fontWeight.value < FontWeight.w400.value
            ? FontWeight.w400
            : fontWeight);

    return GoogleFonts.bitter(
      textStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: resolvedWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      ),
    );
  }
}

/// Centralizovan dizajn sistem sa tokenima za razmake, radijuse, veličine i boje.
/// Služi kao jedinstven izvor istine (SSOT) za UI konzistentnost.
class AppDesign {
  AppDesign._();

  // Spacing (Razmaci)
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 24.0;
  static const double spaceXXL = 32.0;

  // Border Radius (Zaobljenja)
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;

  // Icon Sizes (Veličine ikonica)
  static const double iconS = 16.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;
  static const double iconXL = 32.0;

  // Padding helperi za lakše korišćenje
  static const EdgeInsets paddingXS = EdgeInsets.all(spaceXS);
  static const EdgeInsets paddingS = EdgeInsets.all(spaceS);
  static const EdgeInsets paddingM = EdgeInsets.all(spaceM);
  static const EdgeInsets paddingL = EdgeInsets.all(spaceL);

  // Horizontalni i vertikalni razmaci kao widgeti
  static const Widget boxXS = SizedBox(height: spaceXS, width: spaceXS);
  static const Widget boxS = SizedBox(height: spaceS, width: spaceS);
  static const Widget boxM = SizedBox(height: spaceM, width: spaceM);
  static const Widget boxL = SizedBox(height: spaceL, width: spaceL);
  static const Widget boxXL = SizedBox(height: spaceXL, width: spaceXL);

  // Compact tokens for space optimization
  static const double spaceCompact = 6.0;
  static const EdgeInsets paddingCompact = EdgeInsets.all(spaceCompact);
  static const Widget boxCompact = SizedBox(height: spaceCompact, width: spaceCompact);
}
