import 'package:flutter/widgets.dart';

/// Staticki katalog Lucide ikonica koriscenih u oglasima i filterima
///
/// Koristi lokalni `assets/fonts/lucide.ttf` font bez zavisnosti od eksternog paketa,
/// sto eliminise CanvasKit fontPackage prefiks probleme na Flutter Webu.
@staticIconProvider
class LucideIcons {
  const LucideIcons._();

  static const String _fontFamily = 'Lucide';

  // Karakteristike telefona i tehnike
  static const IconData hardDrive = IconData(0xe0ed, fontFamily: _fontFamily);
  static const IconData cpu = IconData(0xe0a9, fontFamily: _fontFamily);
  static const IconData batteryCharging = IconData(0xe054, fontFamily: _fontFamily);
  static const IconData unlock = IconData(0xe10c, fontFamily: _fontFamily);
  static const IconData smartphone = IconData(0xe163, fontFamily: _fontFamily);
  static const IconData layers = IconData(0xe529, fontFamily: _fontFamily);
  static const IconData nfc = IconData(0xe3c3, fontFamily: _fontFamily);
  static const IconData signal = IconData(0xe25f, fontFamily: _fontFamily);
  static const IconData shieldCheck = IconData(0xe1ff, fontFamily: _fontFamily);
  static const IconData badgeCheck = IconData(0xe241, fontFamily: _fontFamily);
  static const IconData radioTower = IconData(0xe404, fontFamily: _fontFamily);
  static const IconData store = IconData(0xe3e4, fontFamily: _fontFamily);
  static const IconData wrench = IconData(0xe1b1, fontFamily: _fontFamily);
  static const IconData packageCheck = IconData(0xe266, fontFamily: _fontFamily);
  static const IconData package = IconData(0xe129, fontFamily: _fontFamily);
  static const IconData plug = IconData(0xe37f, fontFamily: _fontFamily);
  static const IconData usb = IconData(0xe356, fontFamily: _fontFamily);
  static const IconData shield = IconData(0xe158, fontFamily: _fontFamily);
  static const IconData sparkles = IconData(0xe412, fontFamily: _fontFamily);
  static const IconData headphones = IconData(0xe0f1, fontFamily: _fontFamily);
  static const IconData receipt = IconData(0xe3d3, fontFamily: _fontFamily);
  static const IconData radio = IconData(0xe142, fontFamily: _fontFamily);
}
