// Vrednosti `notifications.type`: vidi `docs/SUPABASE_DATABASE.md` i `supabase/migrations/*notify*.sql`.

/// Tipovi koji vode na ekran porudžbina (push / lokalni prikaz).
/// Uključuje i `order_status_changed` iz trenutnih SQL triggera.
bool notificationTypeIsOrderRelated(String? type) {
  if (type == null || type.isEmpty) return false;
  return type == 'new_order' ||
      type == 'order_status' ||
      type == 'order_status_changed';
}
