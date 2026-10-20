// generate_status.dart
import 'dart:convert';
import 'dart:io';

/// Čita ratchet baseline (tool/coverage_ratchet.json) — platformski nezavisan
/// broj jer se coverage iz lcov.info razlikuje za ~0.02% između Windows/Linux
/// zbog razlika u instrumentaciji. Korišćenjem baseline-a STATUS.md je
/// deterministički i CI `git diff` check radi pouzdano. Ako fajl ne postoji,
/// pada na sirovi lcov broj.
double? _readRatchetTotal() {
  final file = File('tool/coverage_ratchet.json');
  if (!file.existsSync()) return null;
  try {
    final json = jsonDecode(file.readAsStringSync());
    if (json is Map<String, dynamic>) {
      return (json['total'] as num?)?.toDouble();
    }
  } catch (_) {
    // Ignoriši neispravan fajl i padni na lcov.
  }
  return null;
}

void main(List<String> args) {
  final statusFile = File('STATUS.md');
  final testDir = Directory('test');
  final lcovFile = File('coverage/lcov.info');
  final migrationsDir = Directory('supabase/migrations');
  final force = args.contains('--force');

  int testCount = 0;
  if (testDir.existsSync()) {
    final testFiles = testDir
        .listSync(recursive: true)
        .where((e) => e.path.endsWith('_test.dart'));
    testCount = testFiles.length;
  }

  double coverage = 0.0;
  final ratchetTotal = _readRatchetTotal();
  if (ratchetTotal != null) {
    // Preforirani izvor: ratchet baseline (deterministički po platformi).
    coverage = ratchetTotal;
  } else if (lcovFile.existsSync()) {
    final lines = lcovFile.readAsLinesSync();
    int totalLines = 0;
    int coveredLines = 0;
    for (final line in lines) {
      if (line.startsWith('LF:')) {
        totalLines += int.parse(line.substring(3));
      } else if (line.startsWith('LH:')) {
        coveredLines += int.parse(line.substring(3));
      }
    }
    if (totalLines > 0) {
      coverage = (coveredLines / totalLines) * 100;
    }
  }

  int migrationCount = 0;
  if (migrationsDir.existsSync()) {
    migrationCount =
        migrationsDir.listSync().where((e) => e.path.endsWith('.sql')).length;
  }

  final coverageStr = coverage.toStringAsFixed(2);

  // Ako STATUS.md već postoji i nije prosleđen --force, proveravamo da li su se metrike promenile.
  // Ako su metrike identične, ne menjamo timestamp kako CI `git diff --quiet -- STATUS.md` ne bi lažno padao.
  if (!force && statusFile.existsSync()) {
    final existingContent = statusFile.readAsStringSync();
    final testMatch =
        RegExp(r'- \*\*Test fajlovi\*\*:\s*(\d+)').firstMatch(existingContent);
    final covMatch =
        RegExp(r'- \*\*Pokrivenost koda \(Coverage\)\*\*:\s*([\d\.]+)%')
            .firstMatch(existingContent);
    final migMatch = RegExp(r'- \*\*Broj SQL migracija\*\*:\s*(\d+)')
        .firstMatch(existingContent);

    if (testMatch != null && covMatch != null && migMatch != null) {
      final existingTests = int.tryParse(testMatch.group(1)!);
      final existingCov = covMatch.group(1);
      final existingMigs = int.tryParse(migMatch.group(1)!);

      if (existingTests == testCount &&
          existingCov == coverageStr &&
          existingMigs == migrationCount) {
        stdout.writeln(
          'STATUS.md je već ažuran (metrike nepromenjene: $testCount test fajlova, $coverageStr% coverage, $migrationCount migracija).',
        );
        return;
      }
    }
  }

  final sb = StringBuffer();
  sb.writeln('# Projekat: Mleko');
  sb.writeln('Poslednji put generisano: ${DateTime.now().toIso8601String()}');
  sb.writeln('');
  sb.writeln('## Status');
  sb.writeln('- **Test fajlovi**: $testCount');
  sb.writeln('- **Pokrivenost koda (Coverage)**: $coverageStr%');
  sb.writeln('- **Broj SQL migracija**: $migrationCount');
  sb.writeln('');
  sb.writeln('Ovaj fajl je auto-generisan.');

  statusFile.writeAsStringSync(sb.toString());
  stdout.writeln(
    'STATUS.md uspešno generisan ($testCount test fajlova, $coverageStr% coverage, $migrationCount migracija).',
  );
}
