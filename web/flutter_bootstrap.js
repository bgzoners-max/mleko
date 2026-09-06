{{flutter_js}}
{{flutter_build_config}}

// Cloudflare CDN Cache-Buster: Dodaj timestamp na mainJsPath da Cloudflare edge serveri ne bi servirali keširan main.dart.js
try {
  var buster = Date.now();
  if (window._flutter && window._flutter.buildConfig && window._flutter.buildConfig.builds) {
    window._flutter.buildConfig.builds.forEach(function (build) {
      if (build.mainJsPath) {
        build.mainJsPath = build.mainJsPath + '?v=' + buster;
      }
    });
  }
} catch (e) {
  console.warn("Cache buster note:", e);
}

// Učitaj Flutter bez registracije zastarelog Service Worker-a
_flutter.loader.load();
