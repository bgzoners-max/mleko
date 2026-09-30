import 'package:flutter/material.dart';

class AppDesign {
  AppDesign._();

  // Spaces (doubles)
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;

  // Radiuses (doubles)
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;

  // Padding (EdgeInsets)
  static const EdgeInsets paddingS = EdgeInsets.all(spaceS);
  static const EdgeInsets paddingM = EdgeInsets.all(spaceM);
  static const EdgeInsets paddingL = EdgeInsets.all(spaceL);
  static const EdgeInsets paddingXL = EdgeInsets.all(spaceXL);

  // Boxes (SizedBox)
  static const SizedBox boxXS = SizedBox(width: spaceXS, height: spaceXS);
  static const SizedBox boxS = SizedBox(width: spaceS, height: spaceS);
  static const SizedBox boxM = SizedBox(width: spaceM, height: spaceM);
  static const SizedBox boxL = SizedBox(width: spaceL, height: spaceL);

  // Icons
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
}
