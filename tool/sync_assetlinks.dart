import 'dart:convert';
import 'dart:io';

/// Sinhronizuje `web/.well-known/assetlinks.json` sa SHA-256 otiskom ključa
/// kojim se potpisuje Android release build.
///
/// Android App Links verifikacija pada ako se otisak u `assetlinks.json` ne
/// poklapa sa potpisnim certifikatom instalirane aplikacije. Pošto je debug
/// keystore vezan za konkretnu mašinu, ručno prepisivanje otiska lako omaši —
/// zato ovaj alat čita `android/key.properties` i otisak izvlači direktno iz
/// keystore-a preko `keytool`-a.
///
/// Uputstvo: docs/ANDROID_RELEASE_SIGNING.md
///
/// Upotreba:
///   dart run tool/sync_assetlinks.dart
///   dart run tool/sync_assetlinks.dart --print-only
///   dart run tool/sync_assetlinks.dart --extra "AA:BB:..."   (Play App Signing)
///   dart run tool/sync_assetlinks.dart --properties `<putanja>` --out `<putanja>`
const String _defaultPropertiesPath = 'android/key.properties';
const String _defaultOutPath = 'web/.well-known/assetlinks.json';
const String _gradlePath = 'android/app/build.gradle.kts';
const String _packageNameFallback = 'com.mleko.mleko';
const String _passwordEnvVar = 'MLEKO_KEYSTORE_PASSWORD';
const String _debugAlias = 'androiddebugkey';

Future<void> main(List<String> args) async {
  try {
    final options = _parseArgs(args);
    final propertiesPath = options.properties ?? _defaultPropertiesPath;
    final outPath = options.out ?? _defaultOutPath;

    final propertiesFile = File(propertiesPath);
    if (!propertiesFile.existsSync()) {
      _fail(
        'Ne postoji $propertiesPath.\n'
        'Kreiraj ga iz android/key.properties.example '
        '(uputstvo: docs/ANDROID_RELEASE_SIGNING.md).',
      );
    }

    final properties = _readProperties(propertiesFile);
    final storeFileValue = properties['storeFile'];
    final storePassword = properties['storePassword'];
    final keyAlias = properties['keyAlias'];

    if (storeFileValue == null || storePassword == null || keyAlias == null) {
      _fail(
          '$propertiesPath mora sadržati storeFile, storePassword i keyAlias.');
    }

    final storeFile = _resolveStoreFile(storeFileValue);
    final fingerprint = _readSha256(
      storeFile: storeFile,
      alias: keyAlias,
      password: storePassword,
    );

    if (keyAlias.toLowerCase() == _debugAlias) {
      stderr.writeln(
        'UPOZORENJE: koristiš alias "$_debugAlias" — to je DEBUG keystore. '
        'Za distribuciju napravi pravi release keystore.',
      );
    }

    final fingerprints = <String>{fingerprint};
    for (final extra in options.extraFingerprints) {
      fingerprints.add(_normalizeFingerprint(extra));
    }

    final packageName = _readPackageName();
    final json = _buildJson(
      packageName: packageName,
      fingerprints: fingerprints.toList(),
    );

    stdout.writeln('Keystore: ${storeFile.path}');
    stdout.writeln('Alias:    $keyAlias');
    stdout.writeln('Paket:    $packageName');
    stdout.writeln('Otisci:   ${fingerprints.join(', ')}');

    if (options.printOnly) {
      stdout.writeln(json.trimRight());
      return;
    }

    final outFile = File(outPath);
    if (outFile.existsSync() && outFile.readAsStringSync() == json) {
      stdout.writeln('$outPath je već usklađen — nema izmena.');
      return;
    }

    outFile.parent.createSync(recursive: true);
    outFile.writeAsStringSync(json);
    stdout.writeln('Upisano: $outPath');

    if (options.extraFingerprints.isEmpty) {
      stdout.writeln(
        'Napomena: ako koristiš Play App Signing, dodaj i otisak app signing '
        'certifikata iz Play Console preko --extra.',
      );
    }
  } on _ToolFailure catch (error) {
    stderr.writeln('GREŠKA: ${error.message}');
    exitCode = 1;
  }
}

class _Options {
  String? properties;
  String? out;
  bool printOnly = false;
  final List<String> extraFingerprints = <String>[];
}

class _ToolFailure implements Exception {
  const _ToolFailure(this.message);

  final String message;
}

Never _fail(String message) => throw _ToolFailure(message);

_Options _parseArgs(List<String> args) {
  final options = _Options();
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--properties') {
      options.properties = _requireValue(args, ++i, arg);
    } else if (arg == '--out') {
      options.out = _requireValue(args, ++i, arg);
    } else if (arg == '--extra') {
      options.extraFingerprints.add(_requireValue(args, ++i, arg));
    } else if (arg == '--print-only') {
      options.printOnly = true;
    } else if (arg == '--help' || arg == '-h') {
      _printUsage();
      exit(0);
    } else {
      _fail('Nepoznat argument: $arg (vidi --help)');
    }
  }
  return options;
}

String _requireValue(List<String> args, int index, String flag) {
  if (index >= args.length) {
    _fail('Nedostaje vrednost za $flag');
  }
  return args[index];
}

void _printUsage() {
  stdout.writeln('''
Sinhronizacija Android Digital Asset Links (assetlinks.json).

Upotreba:
  dart run tool/sync_assetlinks.dart [opcije]

Opcije:
  --properties <putanja>  key.properties (default: $_defaultPropertiesPath)
  --out <putanja>         izlazni assetlinks.json (default: $_defaultOutPath)
  --extra <otisak>        dodatni SHA-256 otisak, npr. Play App Signing
                          (može se ponoviti)
  --print-only            samo prikaži rezultat, ne upisuj fajl
  -h, --help              prikaži ovu pomoć
''');
}

Map<String, String> _readProperties(File file) {
  final result = <String, String>{};
  for (final rawLine in const LineSplitter().convert(file.readAsStringSync())) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#') || line.startsWith('!')) continue;
    final separator = line.indexOf('=');
    if (separator <= 0) continue;
    result[line.substring(0, separator).trim()] =
        line.substring(separator + 1).trim();
  }
  return result;
}

File _resolveStoreFile(String value) {
  final normalized = value.trim().replaceAll(r'\', '/');
  final isAbsolute =
      normalized.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(normalized);

  final candidates = <String>[
    if (isAbsolute) normalized,
    'android/app/$normalized',
    'android/$normalized',
    normalized,
  ];

  for (final candidate in candidates) {
    final file = File(candidate);
    if (file.existsSync()) return file;
  }

  _fail(
    'Keystore iz key.properties (storeFile=$value) nije pronađen. '
    'Proverene putanje:\n${candidates.map((c) => '  - $c').join('\n')}',
  );
}

String _readPackageName() {
  final gradleFile = File(_gradlePath);
  if (!gradleFile.existsSync()) return _packageNameFallback;

  final match = RegExp(r'applicationId\s*=\s*"([^"]+)"')
      .firstMatch(gradleFile.readAsStringSync());
  return match?.group(1) ?? _packageNameFallback;
}

String _readSha256({
  required File storeFile,
  required String alias,
  required String password,
}) {
  final keytool = Platform.environment['KEYTOOL'] ?? 'keytool';
  ProcessResult result;
  try {
    // Lozinka se prosleđuje kroz env promenljivu, ne kroz argumente procesa.
    result = Process.runSync(
      keytool,
      <String>[
        '-list',
        '-v',
        '-keystore',
        storeFile.path,
        '-alias',
        alias,
        '-storepass:env',
        _passwordEnvVar,
      ],
      environment: <String, String>{_passwordEnvVar: password},
    );
  } on ProcessException catch (error) {
    _fail(
      'Ne mogu da pokrenem "$keytool": ${error.message}\n'
      'Instaliraj JDK ili postavi KEYTOOL env promenljivu na punu putanju keytool-a.',
    );
  }

  final output = '${result.stdout}\n${result.stderr}';
  if (result.exitCode != 0) {
    _fail('keytool je vratio kod ${result.exitCode}:\n$output');
  }

  final marker = output.indexOf('SHA256:');
  if (marker < 0) {
    _fail('keytool izlaz ne sadrži SHA256 otisak:\n$output');
  }

  // Konzola ume da prelomi otisak u više redova, pa uklanjamo sve
  // što nije heksadecimalno (razmaci, novi red, dvotačke).
  final compact = output
      .substring(marker + 'SHA256:'.length)
      .replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
  if (compact.length < 64) {
    _fail(
      'Neispravan SHA256 otisak u keytool izlazu '
      '(${compact.length} heksadecimalnih znakova, očekivano 64).',
    );
  }

  return _normalizeFingerprint(compact.substring(0, 64));
}

String _normalizeFingerprint(String value) {
  final compact = value.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
  if (compact.length != 64) {
    _fail(
      'Otisak mora sadržati 64 heksadecimalna znaka, dobijeno '
      '${compact.length} za "$value".',
    );
  }

  final pairs = <String>[];
  for (var i = 0; i < compact.length; i += 2) {
    pairs.add(compact.substring(i, i + 2).toUpperCase());
  }
  return pairs.join(':');
}

String _buildJson({
  required String packageName,
  required List<String> fingerprints,
}) {
  final payload = <Map<String, Object>>[
    <String, Object>{
      'relation': <String>['delegate_permission/common.handle_all_urls'],
      'target': <String, Object>{
        'namespace': 'android_app',
        'package_name': packageName,
        'sha256_cert_fingerprints': fingerprints,
      },
    },
  ];
  return '${const JsonEncoder.withIndent('  ').convert(payload)}\n';
}
