// generate_status.dart
import 'dart:io';

void main() {
  final statusFile = File('STATUS.md');
  final testDir = Directory('test');
  final lcovFile = File('coverage/lcov.info');
  final migrationsDir = Directory('supabase/migrations');

  int testCount = 0;
  if (testDir.existsSync()) {
    final testFiles = testDir.listSync(recursive: true).where((e) => e.path.endsWith('_test.dart'));
    testCount = testFiles.length; // Ovo broji test fajlove, ali možemo računati da je svaki fajl 1+ test, ili možemo izvući broj testova iz coverage-a (otežano)
    // Actually, to get number of tests requires parsing dart files. We can just list test files for now.
  }

  double coverage = 0.0;
  if (lcovFile.existsSync()) {
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
    migrationCount = migrationsDir.listSync().where((e) => e.path.endsWith('.sql')).length;
  }

  final sb = StringBuffer();
  sb.writeln('# Projekat: Mleko');
  sb.writeln('Poslednji put generisano: ${DateTime.now().toIso8601String()}');
  sb.writeln('');
  sb.writeln('## Status');
  sb.writeln('- **Test fajlovi**: $testCount');
  sb.writeln('- **Pokrivenost koda (Coverage)**: ${coverage.toStringAsFixed(2)}%');
  sb.writeln('- **Broj SQL migracija**: $migrationCount');
  sb.writeln('');
  sb.writeln('Ovaj fajl je auto-generisan.');

  statusFile.writeAsStringSync(sb.toString());
  stdout.writeln('STATUS.md uspešno generisan.');
}
