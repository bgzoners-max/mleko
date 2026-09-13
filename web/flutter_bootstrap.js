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

// Učitaj Flutter bez registracije zastarelog Service Worker-a
_flutter.loader.load();
