// Domaci Market — app-shell skripte (izdvojeno iz web/index.html).
// Sekcija 1: PWA instalacioni baner (Android/desktop/i iOS fallback).
// Sekcija 2: ciscenje Service Worker-a i lokalnog kesa po novom build-u.
// Build hash se ubrizgava preko tool/prepare_cloudflare_deploy.dart;
// placeholder __BUILD_HASH__ ostaje netaknut u development rezimu.
    // PWA Instalacioni prompt sa podrškom za Android (beforeinstallprompt),
    // desktop i iOS Safari fallback („Dodaj na početni ekran”) uz 7-dnevni snooze
    (function () {
      var deferredPrompt = null;
      var banner = document.getElementById('pwa-install-banner');
      var installBtn = document.getElementById('pwa-install-btn');
      var dismissBtn = document.getElementById('pwa-dismiss-btn');
      var iosGuide = document.getElementById('pwa-ios-guide');
      var iosDoneBtn = document.getElementById('pwa-ios-done-btn');

      var isStandalone = window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone === true;
      if (isStandalone) return;

      var dismissedUntil = (function () {
        try { return localStorage.getItem('dm_pwa_dismissed_until'); } catch (e) { return null; }
      })();
      if (dismissedUntil && Number(dismissedUntil) > Date.now()) {
        return;
      }

      // Provera iOS / iPadOS platforme (Safari nema beforeinstallprompt event)
      var isIOS = (/iPad|iPhone|iPod/.test(navigator.userAgent) ||
                   (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)) &&
                  !window.MSStream;

      // 1. Android i desktop Chrome/Edge: slušaj beforeinstallprompt
      window.addEventListener('beforeinstallprompt', function (e) {
        e.preventDefault();
        deferredPrompt = e;
        setTimeout(function () {
          if (deferredPrompt && banner) {
            banner.classList.add('pwa-visible');
          }
        }, 3000);
      });

      // 2. iOS Safari fallback: prikaži baner sa uputstvom za manualno dodavanje
      if (isIOS) {
        setTimeout(function () {
          if (!deferredPrompt && banner) {
            banner.classList.add('pwa-visible');
          }
        }, 3500);
      }

      if (installBtn) {
        installBtn.addEventListener('click', function () {
          if (deferredPrompt) {
            banner.classList.remove('pwa-visible');
            deferredPrompt.prompt();
            deferredPrompt.userChoice.then(function (choice) {
              deferredPrompt = null;
              if (choice.outcome === 'accepted') {
                try {
                  localStorage.setItem('dm_pwa_dismissed_until', String(Date.now() + 365 * 24 * 60 * 60 * 1000));
                } catch (e) {}
              }
            });
          } else if (isIOS && iosGuide) {
            // Na iOS-u otvori korake za Safari „Add to Home Screen”
            var isHidden = !iosGuide.classList.contains('pwa-guide-visible');
            if (isHidden) {
              iosGuide.classList.add('pwa-guide-visible');
              installBtn.textContent = 'Zatvori';
            } else {
              iosGuide.classList.remove('pwa-guide-visible');
              installBtn.textContent = 'Instaliraj';
            }
          }
        });
      }

      if (iosDoneBtn) {
        iosDoneBtn.addEventListener('click', function () {
          if (banner) banner.classList.remove('pwa-visible');
          // Nakon što je korisnik video uputstvo, odloži ponovno prikazivanje na 14 dana
          try {
            localStorage.setItem('dm_pwa_dismissed_until', String(Date.now() + 14 * 24 * 60 * 60 * 1000));
          } catch (e) {}
        });
      }

      if (dismissBtn) {
        dismissBtn.addEventListener('click', function () {
          if (banner) banner.classList.remove('pwa-visible');
          // Standardno 7-dnevno odlaganje (snooze)
          try {
            localStorage.setItem('dm_pwa_dismissed_until', String(Date.now() + 7 * 24 * 60 * 60 * 1000));
          } catch (e) {}
        });
      }
    })();

// ── Sekcija 2: build-hash ciscenje keša ──
    // Automatsko ciscenje Service Worker-a i lokalnog kesa za svaki novi build
    (function () {
      function safeGetItem(key) {
        try { return localStorage.getItem(key); } catch (e) { return null; }
      }
      function safeSetItem(key, val) {
        try { localStorage.setItem(key, val); } catch (e) {}
      }

      var currentBuild = '__BUILD_HASH__';
      if (currentBuild && currentBuild.indexOf('__') === -1 && window.fetch) {
        var origFetch = window.fetch;
        window.fetch = function (input, init) {
          if (typeof input === 'string' &&
              (input.indexOf('assets/fonts/') !== -1 ||
               input.indexOf('FontManifest.json') !== -1 ||
               input.indexOf('AssetManifest') !== -1) &&
              input.indexOf('?') === -1) {
            input = input + '?v=' + currentBuild;
          }
          return origFetch.call(this, input, init);
        };
      }
      var lastBuild = safeGetItem('dm_build_hash');
      if (currentBuild && currentBuild.indexOf('__') === -1 && lastBuild && lastBuild !== currentBuild) {
        var cleanupTasks = [];
        if ('serviceWorker' in navigator) {
          cleanupTasks.push(
            navigator.serviceWorker.getRegistrations().then(function (regs) {
              return Promise.all(
                regs
                  .filter(function (r) {
                    var worker = r.active || r.waiting || r.installing;
                    var scriptUrl = worker && worker.scriptURL ? worker.scriptURL : '';
                    return !scriptUrl || scriptUrl.indexOf('flutter_service_worker.js') !== -1;
                  })
                  .map(function (r) { return r.unregister(); })
              );
            })
          );
        }
        if ('caches' in window) {
          cleanupTasks.push(
            caches.keys().then(function (keys) {
              return Promise.all(
                keys
                  .filter(function (k) { return k.indexOf('flutter') !== -1; })
                  .map(function (k) { return caches.delete(k); })
              );
            })
          );
        }
        Promise.all(cleanupTasks).then(function () {
          safeSetItem('dm_build_hash', currentBuild);
          window.location.reload();
        }).catch(function () {
          safeSetItem('dm_build_hash', currentBuild);
          window.location.reload();
        });
      } else if (currentBuild && currentBuild.indexOf('__') === -1 && !lastBuild) {
        safeSetItem('dm_build_hash', currentBuild);
      }
    })();
