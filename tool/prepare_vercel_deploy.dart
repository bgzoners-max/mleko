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

  // 6. Post-procesiranje index.html: ubrizgavanje preload taga za main.dart.js
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
    // Ukloni eventualne zaostale Date.now() pozive
    content = content.replaceAll(
      RegExp(r"s\.src\s*=\s*'flutter_bootstrap\.js\?v='\s*\+\s*Date\.now\(\);"),
      "s.src = 'flutter_bootstrap.js';",
    );
    targetIndexHtml.writeAsStringSync(content);
    stdout.writeln('Injected preload tag for main.dart.js into index.html');
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
      // Remove heavy devDependencies like `supabase` CLI to speed up Vercel build
      final content = source.readAsStringSync();
      final sanitized = content.replaceAll(
          RegExp(r'"devDependencies":\s*\{[^}]*\},?'), '');
      target.writeAsStringSync(sanitized);
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
  final buildIdFile = File('${buildWebDir.path}/.last_build_id');
  if (buildIdFile.existsSync()) {
    final text = buildIdFile.readAsStringSync().trim();
    if (text.isNotEmpty) {
      return text.length > 12 ? text.substring(0, 12) : text;
    }
  }
  final mainJsFile = File('${buildWebDir.path}/main.dart.js');
  if (mainJsFile.existsSync()) {
    final mod = mainJsFile.lastModifiedSync().millisecondsSinceEpoch.toRadixString(36);
    final len = mainJsFile.lengthSync().toRadixString(36);
    return '${mod}_$len';
  }
  return DateTime.now().millisecondsSinceEpoch.toString();
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
