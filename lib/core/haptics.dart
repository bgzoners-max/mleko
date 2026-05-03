import 'package:flutter/services.dart';

/// Centralizovan sistem za taktilni feedback (vibracije).
/// Pomaže da aplikacija deluje "opipljivije" i premium.
class AppHaptics {
  /// Suptilan klik, odličan za promenu kvantiteta ili toggle.
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Nešto jači feedback, npr. za dodavanje u korpu.
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Jak feedback, koristi se retko (npr. dugme za plaćanje).
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Specijalni feedback za uspeh (npr. završena porudžbina).
  static Future<void> success() async {
    // Na iOS-u ovo daje specifičan "success" ritam
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  /// Feedback za grešku.
  static Future<void> error() async {
    await HapticFeedback.vibrate();
  }

  /// Feedback za selekciju (npr. scroll wheel).
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }
}
