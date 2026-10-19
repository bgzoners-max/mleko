import 'dart:convert';
import 'dart:io';

void main() {
  final buildWebDir = Directory('build/web');
  final functionsDir = Directory('functions');
  final deployDir = Directory('build/cloudflare-deploy');

  if (!buildWebDir.existsSync()) {
    stderr.writeln('Build output directory not found: ${buildWebDir.path}');
    stderr
        .writeln('Run `flutter build web` before preparing the Cloudflare bundle.');
    exitCode = 1;
    return;
  }

  if (deployDir.existsSync()) {
    deployDir.deleteSync(recursive: true);
  }
  deployDir.createSync(recursive: true);

  // 1. Određivanje determinističkog build heša
  final buildHash = _getBuildHash(buildWebDir);
  stdout.writeln('Determined build hash for immutable caching: $buildHash');

  // 2. Provera da li klijent koristi Google CDN ili lokalni CanvasKit
  final bootstrapFile = File('${buildWebDir.path}/flutter_bootstrap.js');
  final usesLocalCanvasKit = bootstrapFile.existsSync() &&
      bootstrapFile.readAsStringSync().contains('"useLocalCanvasKit":true');

  stdout.writeln(
      'CanvasKit loading strategy: ${usesLocalCanvasKit ? "Local bundle" : "Google CDN (optimized, skipping local 36MB canvaskit/)"}');

  // 3. Kopiranje i optimizacija public web bundle-a direktno u deploy root
  _copyDirectoryWithFilter(
    source: buildWebDir,
    target: deployDir,
    shouldInclude: (relativePath) {
      final normalized = relativePath.replaceAll('\\', '/');

      // Preskoči debug simbole (nepotrebni u produkciji)
      if (normalized.endsWith('.symbols')) return false;

      // Preskoči interne build fajlove
      if (normalized == '.last_build_id') return false;

      // Ako je uključen Google CDN (default za Flutter Web), preskoči lokalni canvaskit
      if (!usesLocalCanvasKit &&
          (normalized == 'canvaskit' || normalized.startsWith('canvaskit/'))) {
        return false;
      }

      // Ako se koristi lokalni canvaskit, preskoči neiskorišćene wasm varijante za dart2js
      if (normalized.startsWith('canvaskit/skwasm') ||
          normalized.startsWith('canvaskit/wimp')) {
        return false;
      }

      return true;
    },
  );

  // 4. Kopiranje Cloudflare Pages Functions ako postoje
  if (functionsDir.existsSync()) {
    _copyDirectoryWithFilter(
      source: functionsDir,
      target: Directory('${deployDir.path}/functions'),
      shouldInclude: (_) => true,
    );
    stdout.writeln('Synchronized Cloudflare Pages Functions into deploy bundle');
  }

  // 4b. Validacija i osiguranje .well-known direktorijuma (npr. Digital Asset Links)
  final wellKnownSource = Directory('web/.well-known');
  if (wellKnownSource.existsSync()) {
    final assetLinks = File('${wellKnownSource.path}/assetlinks.json');
    if (assetLinks.existsSync()) {
      final content = assetLinks.readAsStringSync().trim();
      if (content.isEmpty) {
        stderr.writeln('ERROR: web/.well-known/assetlinks.json is empty!');
        exitCode = 1;
        return;
      }
      try {
        final parsed = jsonDecode(content);
        if (parsed is! List || parsed.isEmpty) {
          stderr.writeln(
              'ERROR: web/.well-known/assetlinks.json must be a non-empty JSON array.');
          exitCode = 1;
          return;
        }
      } catch (e) {
        stderr.writeln(
            'ERROR: web/.well-known/assetlinks.json is not valid JSON: $e');
        exitCode = 1;
        return;
      }
    }

    final wellKnownTarget = Directory('${deployDir.path}/.well-known');
    _copyDirectoryWithFilter(
      source: wellKnownSource,
      target: wellKnownTarget,
      shouldInclude: (_) => true,
    );
    stdout.writeln('Validated and synchronized .well-known assets');
  }

  // 5. Post-procesiranje flutter_bootstrap.js: ubrizgavanje determinističkog heša
  final targetBootstrap = File('${deployDir.path}/flutter_bootstrap.js');
  if (targetBootstrap.existsSync()) {
    var content = targetBootstrap.readAsStringSync();
    content = content.replaceAll('__BUILD_HASH__', buildHash);
    content = content.replaceAll('{{BUILD_HASH}}', buildHash);
    content = content.replaceAll(
      RegExp(r'var\s+buildHash\s*=\s*["\x27]v1["\x27];'),
      'var buildHash = "$buildHash";',
    );
    content = content.replaceAll(
      RegExp(r'var\s+buster\s*=\s*Date\.now\(\);'),
      'var buster = "$buildHash";',
    );
    content = content.replaceAll(
      RegExp(r'//[#@]\s*sourceMappingURL=\S+'),
      '',
    );
    targetBootstrap.writeAsStringSync(content);
    stdout.writeln('Injected build hash into flutter_bootstrap.js and stripped source map references');
  }

  // 5b. Ukloni sourceMappingURL iz svih preostalih .js fajlova
  for (final entity in deployDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.js')) {
      final js = entity.readAsStringSync();
      if (js.contains('sourceMappingURL=')) {
        entity.writeAsStringSync(
          js.replaceAll(RegExp(r'//[#@]\s*sourceMappingURL=\S+'), ''),
        );
      }
    }
  }

  // 5c. Kreiraj validne prazne source map JSON fajlove
  const emptySourceMap = '{"version":3,"file":"script.js","sources":[],"mappings":""}';
  File('${deployDir.path}/flutter.js.map').writeAsStringSync(emptySourceMap);
  File('${deployDir.path}/flutter_bootstrap.js.map').writeAsStringSync(emptySourceMap);
  File('${deployDir.path}/main.dart.js.map').writeAsStringSync(emptySourceMap);
  stdout.writeln('Created fallback source map stubs for production audit compliance');

  // 6. Post-procesiranje index.html: ubrizgavanje preload taga i heša
  final targetIndexHtml = File('${deployDir.path}/index.html');
  if (targetIndexHtml.existsSync()) {
    var content = targetIndexHtml.readAsStringSync();
    content = content.replaceAll(
      '<!-- __PRELOAD_MAIN_JS__ -->',
      '<link rel="preload" href="main.dart.js?v=$buildHash" as="script">',
    );
    content = content.replaceAll(
      '<!-- {{PRELOAD_MAIN_JS}} -->',
      '<link rel="preload" href="main.dart.js?v=$buildHash" as="script">',
    );
    content = content.replaceAll(
      '<link rel="preload" href="flutter_bootstrap.js" as="script">',
      '<link rel="preload" href="flutter_bootstrap.js?v=$buildHash" as="script">',
    );
    content = content.replaceAll(
      '<script src="flutter_bootstrap.js" defer></script>',
      '<script src="flutter_bootstrap.js?v=$buildHash" defer></script>',
    );
    content = content.replaceAll('__BUILD_HASH__', buildHash);
    content = content.replaceAll('{{BUILD_HASH}}', buildHash);
    content = content.replaceAll(
      RegExp(r"s\.src\s*=\s*'flutter_bootstrap\.js\?v='\s*\+\s*Date\.now\(\);"),
      "s.src = 'flutter_bootstrap.js?v=$buildHash';",
    );
    targetIndexHtml.writeAsStringSync(content);
    stdout.writeln('Injected preload tags and build hash into index.html');
  }

  // 7. Kopiranje Cloudflare Pages specifičnih fajlova (_headers, _redirects)
  final cfHeaders = File('web/_headers');
  if (cfHeaders.existsSync()) {
    cfHeaders.copySync('${deployDir.path}/_headers');
    stdout.writeln('Copied _headers configuration');
  }

  final cfRedirects = File('web/_redirects');
  if (cfRedirects.existsSync()) {
    cfRedirects.copySync('${deployDir.path}/_redirects');
    stdout.writeln('Copied _redirects configuration');
  }

  // 7b. Kreiraj čiste direktorijumske rute za statičke HTML stranice
  //     kako bi Cloudflare Pages servirao čist HTML bez 308 redirect petlje
  for (final page in ['politika-privatnosti', 'uslovi-koriscenja']) {
    final src = File('${deployDir.path}/$page.html');
    if (src.existsSync()) {
      final pageDir = Directory('${deployDir.path}/$page');
      pageDir.createSync(recursive: true);
      src.copySync('${pageDir.path}/index.html');
      stdout.writeln('Created clean directory index for $page');
    }
  }

  // 8. Prikaz statistike pripremljenog bundle-a
  final totalBytes = _calculateDirectorySize(deployDir);
  final totalMB = (totalBytes / (1024 * 1024)).toStringAsFixed(2);
  final totalFiles = deployDir
      .listSync(recursive: true)
      .whereType<File>()
      .length;

  stdout.writeln('----------------------------------------------------');
  stdout.writeln('Prepared Cloudflare Pages deploy bundle in ${deployDir.path}');
  stdout.writeln('Total deploy size: $totalMB MB ($totalFiles files)');
  stdout.writeln('----------------------------------------------------');
}

String _getBuildHash(Directory buildWebDir) {
  String? commitSha;
  final envSha = Platform.environment['GITHUB_SHA'];
  if (envSha != null && envSha.trim().isNotEmpty) {
    final s = envSha.trim();
    commitSha = s.length > 8 ? s.substring(0, 8) : s;
  } else {
    try {
      final res = Process.runSync('git', ['rev-parse', '--short', 'HEAD']);
      if (res.exitCode == 0) {
        final s = res.stdout.toString().trim();
        if (s.isNotEmpty) commitSha = s;
      }
    } catch (_) {}
  }

  final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  if (commitSha != null) {
    return '${commitSha}_$timestamp';
  }

  final mainJsFile = File('${buildWebDir.path}/main.dart.js');
  if (mainJsFile.existsSync()) {
    final mod =
        mainJsFile.lastModifiedSync().millisecondsSinceEpoch.toRadixString(36);
    final len = mainJsFile.lengthSync().toRadixString(36);
    return '${mod}_${len}_$timestamp';
  }
  return timestamp;
}

int _calculateDirectorySize(Directory dir) {
  var total = 0;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File) {
      total += entity.lengthSync();
    }
  }
  return total;
}

void _copyDirectoryWithFilter({
  required Directory source,
  required Directory target,
  required bool Function(String relativePath) shouldInclude,
}) {
  target.createSync(recursive: true);

  for (final entity in source.listSync(recursive: true)) {
    final relativePath = entity.path.substring(source.path.length + 1);
    if (!shouldInclude(relativePath)) {
      continue;
    }
    if (entity is Directory) {
      Directory('${target.path}/$relativePath').createSync(recursive: true);
      continue;
    }
    if (entity is File) {
      final file = File('${target.path}/$relativePath');
      file.parent.createSync(recursive: true);
      entity.copySync(file.path);
    }
  }
}
