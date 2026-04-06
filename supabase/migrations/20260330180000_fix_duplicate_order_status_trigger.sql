-- Ukloni dupli trigger koji je uzrokovao slanje DVEJU notifikacija pri svakoj promeni statusa.
-- on_order_status_change i on_order_status_changed_notify_buyer su oba pozivali
-- istu funkciju notify_order_status_change() na UPDATE orders.
-- Zadržavamo samo on_order_status_changed_notify_buyer.
DROP TRIGGER IF EXISTS on_order_status_change ON public.orders;
