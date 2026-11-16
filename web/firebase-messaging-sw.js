// Service Worker za Web Push obaveštenja (Domaći Market).
// Postoji kako bi /firebase-messaging-sw.js uvek bio serviran kao application/javascript
// umesto SPA fallback-a (index.html / text/html) kada Web Push koristi VAPID ključ.

self.addEventListener('push', function (event) {
  if (!event.data) return;
  let payload = {};
  try {
    payload = event.data.json();
  } catch (_) {
    payload = { notification: { title: 'Domaći Market', body: event.data.text() } };
  }
  const notification = payload.notification || {};
  const title = notification.title || (payload.data && payload.data.title) || 'Domaći Market';
  const body = notification.body || (payload.data && payload.data.body) || '';
  const data = payload.data || {};

  event.waitUntil(
    self.registration.showNotification(title, {
      body: body,
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      data: data,
    })
  );
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  const data = (event.notification && event.notification.data) || {};
  const targetRoute = typeof data.route === 'string' && data.route.startsWith('/')
    ? data.route
    : '/';

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (clientList) {
      for (const client of clientList) {
        if ('focus' in client) {
          return client.focus();
        }
      }
      if (self.clients.openWindow) {
        return self.clients.openWindow(targetRoute);
      }
      return undefined;
    })
  );
});
