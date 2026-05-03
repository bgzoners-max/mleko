import 'package:flutter/services.dart';

/// Centralizovan sistem za taktilni feedback (vibracije).
class AppHaptics {
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> medium() => HapticFeedback.mediumImpact();
  static Future<void> heavy() => HapticFeedback.heavyImpact();
  static Future<void> selection() => HapticFeedback.selectionClick();
  
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  static Future<void> error() => HapticFeedback.vibrate();
}

/// Pomoćna funkcija za haptic feedback na dugmićima i interakcijama.
void withHaptic(VoidCallback? action, {bool medium = false}) {
  if (action == null) return;
  if (medium) {
    AppHaptics.medium();
  } else {
    AppHaptics.light();
  }
  action();
}
