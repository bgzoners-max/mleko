import 'dart:async';
import 'package:flutter/foundation.dart';

/// Pomoćna klasa za sprečavanje višestrukog ili prebrzog pozivanja akcija
/// (double-tap na dugme, slanje poruka, učitavanje).
class ActionDebouncer {
  final Duration defaultDuration;
  Timer? _timer;
  DateTime? _lastExecution;
  bool _isBusy = false;

  ActionDebouncer({this.defaultDuration = const Duration(milliseconds: 400)});

  bool get isBusy => _isBusy;
  bool get isActive => _timer?.isActive ?? false;

  /// Debounce: Izvršava akciju tek nakon što istekne [duration] bez novih poziva.
  void run(VoidCallback action, {Duration? duration}) {
    _timer?.cancel();
    _timer = Timer(duration ?? defaultDuration, action);
  }

  /// Throttle: Izvršava akciju odmah, a ignoriše sve pozive u narednih [duration].
  /// Vraća `true` ako je akcija izvršena, `false` ako je ignorisana.
  bool throttle(VoidCallback action, {Duration? duration}) {
    final now = DateTime.now();
    final delay = duration ?? defaultDuration;
    if (_lastExecution == null || now.difference(_lastExecution!) >= delay) {
      _lastExecution = now;
      action();
      return true;
    }
    return false;
  }

  /// Async guard: Sprečava paralelno pokretanje asinhronih operacija dok prethodna traje.
  /// Vraća rezultat operacije ili `null` ako je akcija već u toku.
  Future<T?> runAsync<T>(Future<T> Function() asyncAction) async {
    if (_isBusy) return null;
    _isBusy = true;
    try {
      return await asyncAction();
    } finally {
      _isBusy = false;
    }
  }

  /// Otkazuje zakazane tajmere i resetuje stanje.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _isBusy = false;
  }
}

