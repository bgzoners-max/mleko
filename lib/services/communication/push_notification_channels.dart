import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Definicije Android kanala + lokalni prikaz notifikacija.
///
/// Izdvojeno iz `PushService` kao korak 1 split-a: ovaj fajl poseduje
/// isključivo kanale (`mleko_urgent_v2`, `orders_high_v2`) i formatiranje
/// lokalne notifikacije. Nema Firebase stream-ove niti Supabase upite.
const _channelId = 'mleko_urgent_v2';
const _channelName = 'Hitno';

const _ordersChannelId = 'orders_high_v2';
const _ordersChannelName = 'Porudžbine';

const defaultChannel = AndroidNotificationChannel(
  _channelId,
  _channelName,
  description: 'Push obaveštenja za poruke',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

const ordersChannel = AndroidNotificationChannel(
  _ordersChannelId,
  _ordersChannelName,
  description: 'Notifikacije za nove porudžbine i status',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

/// Alias radi kompatibilnosti sa postojecim pozivima.
const defaultPushChannel = defaultChannel;
const ordersPushChannel = ordersChannel;
