// tool/check_no_seed_data_in_migrations.dart
//
// CI Guard: Garantuje da nijedna SQL migracija u supabase/migrations/ ne sadrži
// seed podatke ili direktne inserte u auth.users / profiles sa test nalozima.
// Svi seed podaci pripadaju isključivo u supabase/seed.sql.

import 'dart:io';

void main() {
  final migrationsDir = Directory('supabase/migrations');
  if (!migrationsDir.existsSync()) {
    stderr.writeln('ERROR: supabase/migrations direktorijum ne postoji.');
    exit(1);
  }

  final sqlFiles = migrationsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final violations = <String>[];

  // Obrasci zabranjeni u produkcijskim migracijama
  final forbiddenPatterns = [
    RegExp(r'INSERT\s+INTO\s+auth\.users', caseSensitive: false),
    RegExp(r'_seed_create_user|_seed_test_user', caseSensitive: false),
    RegExp(r'INSERT\s+INTO\s+(public\.)?profiles.*@test\.rs', caseSensitive: false),
    RegExp(r'INSERT\s+INTO\s+(public\.)?profiles.*@example\.com', caseSensitive: false),
  ];

  for (final file in sqlFiles) {
    final lines = file.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      // Ignoriši SQL komentare
      if (line.startsWith('--')) continue;

      for (final pattern in forbiddenPatterns) {
        if (pattern.hasMatch(line)) {
          violations.add(
            '${file.path}:${i + 1} -> "$line" (Zabranjen seed obrazac: ${pattern.pattern})',
          );
        }
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln('::error::Pronađeni su seed podaci u supabase/migrations/!');
    stderr.writeln(
      'Test podaci i nalozi su zabranjeni u produkcijskim migracijama. '
      'Seed podaci smeju biti isključivo u supabase/seed.sql.\n',
    );
    for (final v in violations) {
      stderr.writeln('  - $v');
    }
    exit(1);
  }

  stdout.writeln(
    'OK: Svih ${sqlFiles.length} migracija je čisto od seed test podataka.',
  );
}
