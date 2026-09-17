import 'dart:convert';
import 'dart:io';

/// CI guard: pada ako su keystore, `key.properties` ili `.env` fajlovi
/// greškom pod verzionom kontrolom.
///
/// Uputstvo za potpisivanje: docs/ANDROID_RELEASE_SIGNING.md
void main() {
  final result = Process.runSync('git', <String>['ls-files']);
  if (result.exitCode != 0) {
    stderr.writeln(
      'UPOZORENJE: `git ls-files` nije uspeo — preskačem proveru osetljivih fajlova.',
    );
    return;
  }

  final trackedPaths = const LineSplitter().convert(result.stdout.toString());
  final patterns = <RegExp>[
    RegExp(r'(^|/)key\.properties$'),
    RegExp(r'\.(jks|keystore|p12|pfx)$', caseSensitive: false),
    RegExp(r'(^|/)\.env$'),
    RegExp(r'(^|/)service-account.*\.json$', caseSensitive: false),
  ];

  final offenders = trackedPaths
      .where((path) => patterns.any((pattern) => pattern.hasMatch(path)))
      .toList();

  if (offenders.isEmpty) {
    stdout.writeln(
      'OK: nema commitovanih keystore-a, key.properties ni .env fajlova.',
    );
    return;
  }

  stderr.writeln('GREŠKA: osetljivi fajlovi su pod verzionom kontrolom:');
  for (final path in offenders) {
    stderr.writeln('  - $path');
  }
  stderr.writeln(
    '\nUkloni ih iz gita (`git rm --cached <fajl>`, pa ih dodaj u .gitignore) '
    'i rotiraj kompromitovane tajne.',
  );
  exitCode = 1;
}
