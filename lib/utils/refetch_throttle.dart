/// Throttle za burst realtime događaja – dozvoljava maksimalno jedan fetch
/// na [minInterval], a ostale zahteve odlaže dok prozor ne istekne.
///
/// Koristi se na home ekranu: kada stigne pljusak realtime promena (INSERT/
/// UPDATE/DELETE na tabeli `products`), ne želimo da svaka promena pokrene
/// pun RPC ka bazi – dovoljno je najviše jedan fetch u kratkom prozoru.
class RefetchThrottle {
  final Duration minInterval;

  DateTime? _lastAcquiredAt;

  RefetchThrottle({required this.minInterval});

  /// Pokušava da zauzme slot za odmah pokretanje fet ch-a.
  /// Vraća `true` ako je dozvoljeno, `false` ako treba sačekati [remainingWait].
  bool tryAcquire() {
    final now = DateTime.now();
    if (_lastAcquiredAt == null ||
        now.difference(_lastAcquiredAt!) >= minInterval) {
      _lastAcquiredAt = now;
      return true;
    }
    return false;
  }

  /// Koliko još treba čekati pre pokretanja sledećeg fet ch-a.
  Duration get remainingWait {
    final last = _lastAcquiredAt;
    if (last == null) return Duration.zero;
    final elapsed = DateTime.now().difference(last);
    if (elapsed >= minInterval) return Duration.zero;
    return minInterval - elapsed;
  }

  /// Resetuje stanje – poziv nakon eksplicitnog (ne realtime) osvežavanja.
  void reset() {
    _lastAcquiredAt = null;
  }
}