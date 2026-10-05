import 'dart:convert';
import 'dart:io';

void main() {
  final buildWebDir = Directory('build/web');
  final apiDir = Directory('api');
  final deployDir = Directory('build/vercel-deploy');

  if (!buildWebDir.existsSync()) {
    stderr.writeln('Build output directory not found: ${buildWebDir.path}');
    stderr
        .writeln('Run `flutter build web` before preparing the Vercel bundle.');
    exitCode = 1;
    return;
  }

  if (!apiDir.existsSync()) {
    stderr.writeln('API directory not found: ${apiDir.path}');
    exitCode = 1;
    return;
  }

  if (deployDir.existsSync()) {
    deployDir.deleteSync(recursive: true);
  }
  deployDir.createSync(recursive: true);

  // Inject .vercel/project.json so `vercel deploy --cwd` always targets the
  // correct project without requiring an interactive `vercel link` step.
  // Override per-environment by writing a different project.json before calling
  // `vercel deploy`, or pass --scope and --project flags explicitly.
  final vercelDir = Directory('${deployDir.path}/.vercel');
  vercelDir.createSync(recursive: true);
  File('${vercelDir.path}/project.json').writeAsStringSync(
    '{"projectId":"prj_0ijRDSsR22CcADS3HzwmJ5XFrlx2",'
    '"orgId":"team_HC3fIUGj1ZMlVbwoicfiCWfD",'
    '"projectName":"mleko"}',
  );
  stdout.writeln('Wrote .vercel/project.json → mleko (production)');

  // 1. Određivanje determinističkog build heša
  final buildHash = _getBuildHash(buildWebDir);
  stdout.writeln('Determined build hash for immutable caching: $buildHash');

  // 2. Provera da li klijent koristi Google CDN ili lokalni CanvasKit
  final bootstrapFile = File('${buildWebDir.path}/flutter_bootstrap.js');
  final usesLocalCanvasKit = bootstrapFile.existsSync() &&
      bootstrapFile.readAsStringSync().contains('"useLocalCanvasKit":true');

  stdout.writeln(
      'CanvasKit loading strategy: ${usesLocalCanvasKit ? "Local bundle" : "Google CDN (optimized, skipping local 36MB canvaskit/)"}');

  // 3. Kopiranje i optimizacija public web bundle-a
  final targetPublicDir = Directory('${deployDir.path}/public');
  _copyDirectoryWithFilter(
    source: buildWebDir,
    target: targetPublicDir,
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

  // 4. Kopiranje API funkcija
  _copyDirectoryWithFilter(
    source: apiDir,
    target: Directory('${deployDir.path}/api'),
    shouldInclude: (_) => true,
  );

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

    final wellKnownTarget = Directory('${targetPublicDir.path}/.well-known');
    _copyDirectoryWithFilter(
      source: wellKnownSource,
      target: wellKnownTarget,
      shouldInclude: (_) => true,
    );
    stdout.writeln('Validated and synchronized .well-known assets to public/.well-known');
  }

  // 5. Post-procesiranje flutter_bootstrap.js: ubrizgavanje determinističkog heša
  final targetBootstrap = File('${targetPublicDir.path}/flutter_bootstrap.js');
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
    targetBootstrap.writeAsStringSync(content);
    stdout.writeln('Injected build hash into flutter_bootstrap.js');
  }

  // 6. Post-procesiranje index.html: ubrizgavanje preload taga i heša u flutter_bootstrap.js
  final targetIndexHtml = File('${targetPublicDir.path}/index.html');
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
    // Ubrizgaj verzionisani flutter_bootstrap.js da browser nikada ne servira stari keš
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
    // Ukloni eventualne zaostale Date.now() pozive
    content = content.replaceAll(
      RegExp(r"s\.src\s*=\s*'flutter_bootstrap\.js\?v='\s*\+\s*Date\.now\(\);"),
      "s.src = 'flutter_bootstrap.js?v=$buildHash';",
    );
    targetIndexHtml.writeAsStringSync(content);
    stdout.writeln('Injected preload tags and build hash into index.html');
  }

  // 7. Kopiranje konfiguracionih fajlova (vercel.json, package.json itd.)
  final filesToCopy = <String>[
    'vercel.json',
    'package.json',
    'package-lock.json',
  ];

  for (final relativePath in filesToCopy) {
    final source = File(relativePath);
    if (!source.existsSync()) {
      stderr.writeln('Missing required file: ${source.path}');
      exitCode = 1;
      return;
    }
    final target = File('${deployDir.path}/$relativePath');
    target.parent.createSync(recursive: true);
    if (relativePath == 'package.json') {
      final map =
          jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
      map.remove('devDependencies');
      if (map['scripts'] is Map<String, dynamic>) {
        (map['scripts'] as Map<String, dynamic>).remove('build');
      }
      map['type'] = 'module';
      final encoder = const JsonEncoder.withIndent('  ');
      target.writeAsStringSync(encoder.convert(map));
    } else {
      source.copySync(target.path);
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
  stdout.writeln('Prepared Vercel deploy bundle in ${deployDir.path}');
  stdout.writeln('Total deploy size: $totalMB MB ($totalFiles files)');
  stdout.writeln('----------------------------------------------------');
}

String _getBuildHash(Directory buildWebDir) {
  // 1. Proveri GITHUB_SHA (iz CI okruženja) ili git commit
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
