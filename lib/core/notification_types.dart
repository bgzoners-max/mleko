// Vrednosti `notifications.type`: vidi `docs/SUPABASE_DATABASE.md` i `supabase/migrations/*notify*.sql`.

/// Tipovi koji vode na ekran porudžbina (push / lokalni prikaz).
/// Uključuje i `order_status_changed` iz trenutnih SQL triggera.
bool notificationTypeIsOrderRelated(String? type) {
  if (type == null || type.isEmpty) return false;
  return type == 'new_order' ||
      type == 'order_status' ||
      type == 'order_status_changed';
}

/// Tipovi notifikacija koji se odnose na male oglase (praćenje kategorija, sačuvane pretrage).
bool notificationTypeIsClassifiedRelated(String? type) {
  if (type == null || type.isEmpty) return false;
  return type == 'classified_saved_search' ||
      type == 'new_classified_ad' ||
      type == 'classified_ad_moderation';
}

