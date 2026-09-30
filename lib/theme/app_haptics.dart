import 'package:flutter/services.dart';

class AppHaptics {
  AppHaptics._();

  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> success() async {
    await HapticFeedback.heavyImpact(); // Approximate for success
  }
}
