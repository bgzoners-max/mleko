/// Centralizovani UI tekstovi za loading i kraj liste.
class UiStrings {
  UiStrings._();

  static const String loadingMoreResults = 'Učitavanje još rezultata...';
  static const String noMoreResults = 'Nema više rezultata';

  static const String loadingMoreProducts = 'Učitavanje još proizvoda...';
  static const String noMoreProducts = 'Nema više proizvoda';

  static const String loadingOlderOrders = 'Učitavanje starijih porudžbina...';
  static const String noMoreOrders = 'Nema više porudžbina za prikaz';

  static const String loadingOlderMessages = 'Učitavanje starijih poruka...';
  static const String noMoreMessages = 'Nema starijih poruka';

  // ─── Order status audit log (bez dijakritika) ────────────────────────────
  // Ovi stringovi se koriste u UI-u i testovima (npr. "Prihvaceno").
  static const String orderRoleBuyer = 'Kupac';
  static const String orderRoleSeller = 'Prodavac';
  static const String orderRoleSystem = 'Sistem';

  static const String orderStatusSent = 'Na cekanju';
  static const String orderStatusAccepted = 'Prihvaceno';
  static const String orderStatusShipped = 'Poslato';
  static const String orderStatusDelivered = 'Isporuceno';
  static const String orderStatusRejected = 'Odbijeno';
  static const String orderStatusCancelledBySeller = 'Otkazano';
  static const String orderStatusArchived = 'Arhivirano';

  // ─── Actions / CTA ─────────────────────────────────────────────────────
  static const String actionCancel = 'Otkaži';
  static const String actionMessage = 'Pošalji poruku';
  static const String actionTryAgain = 'Pokušaj ponovo';
  static const String ordersCtaExploreProducts = 'Pregledaj proizvode';

  // ─── Errors ────────────────────────────────────────────────────────────
  static const String errorOpenConversationFailed =
      'Otvaranje razgovora nije uspelo.';
  static const String errorReorderFailed = 'Nije moguće ponovo naručiti.';
}
