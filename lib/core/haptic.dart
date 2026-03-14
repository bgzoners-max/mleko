import 'package:flutter/services.dart';

/// Pomoćna funkcija za haptic feedback na dugmićima i interakcijama.
/// Poziva [HapticFeedback.lightImpact] pre izvršavanja akcije.
void withHaptic(VoidCallback? action) {
  if (action == null) return;
  HapticFeedback.lightImpact();
  action();
}
