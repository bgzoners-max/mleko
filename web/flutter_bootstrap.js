{{flutter_js}}
{{flutter_build_config}}

// Deterministički build hash za dugoročno keširanje (public, max-age=31536000, immutable)
try {
  var buildHash = '__BUILD_HASH__';
  if (!buildHash || buildHash.indexOf('__') === 0) {
    buildHash = 'v1';
  }
  if (window._flutter && window._flutter.buildConfig && window._flutter.buildConfig.builds) {
    window._flutter.buildConfig.builds.forEach(function (build) {
      if (build.mainJsPath) {
        build.mainJsPath = build.mainJsPath + '?v=' + buildHash;
      }
    });
  }
} catch (e) {
  console.warn("Build hash injection note:", e);
}

// Učitaj Flutter bez registracije zastarelog Service Worker-a i sakrij SEO fallback tek nakon uspešnog pokretanja
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
    } catch (err) {
      console.error("Flutter engine initialization error:", err);
      var fb = document.getElementById('loading-fallback');
      if (fb) {
        fb.innerHTML = '<p style="font-size:13px;color:#C62828;margin-bottom:10px;">Došlo je do greške pri učitavanju.</p><button type="button" onclick="window.location.reload(true)" style="background-color:#1B5E20;color:#ffffff;border:none;border-radius:8px;padding:8px 18px;font-size:13px;font-weight:600;cursor:pointer;">Pokušaj ponovo</button>';
        fb.style.display = 'block';
      }
      return;
    }
    var loader = document.getElementById('app-loading-screen');
    if (loader) {
      loader.style.display = 'none';
    }
    var crawlerDiv = document.getElementById('seo-crawler-content');
    if (crawlerDiv) {
      crawlerDiv.style.display = 'none';
    }
  }
}).catch(function (err) {
  console.error("Flutter loader error:", err);
  var fb = document.getElementById('loading-fallback');
  if (fb) {
    fb.innerHTML = '<p style="font-size:13px;color:#C62828;margin-bottom:10px;">Došlo je do greške pri učitavanju.</p><button type="button" onclick="window.location.reload(true)" style="background-color:#1B5E20;color:#ffffff;border:none;border-radius:8px;padding:8px 18px;font-size:13px;font-weight:600;cursor:pointer;">Pokušaj ponovo</button>';
    fb.style.display = 'block';
  }
});
