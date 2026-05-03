import 'package:flutter/material.dart';

/// Centralizovan dizajn sistem sa tokenima za razmake, radijuse i veličine.
/// Pomaže u održavanju vizuelne konzistentnosti i izbegavanju hardkodovanih vrednosti.
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
