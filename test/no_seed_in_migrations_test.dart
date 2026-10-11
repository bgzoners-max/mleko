import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supabase/migrations are free from test seed users and auth.users inserts', () {
    final migrationsDir = Directory('supabase/migrations');
    expect(migrationsDir.existsSync(), isTrue, reason: 'supabase/migrations directory must exist');

    final sqlFiles = migrationsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))
        .toList();

    expect(sqlFiles.isNotEmpty, isTrue);

    final forbiddenPatterns = [
      RegExp(r'INSERT\s+INTO\s+auth\.users', caseSensitive: false),
      RegExp(r'_seed_create_user|_seed_test_user', caseSensitive: false),
      RegExp(r'INSERT\s+INTO\s+(public\.)?profiles.*@test\.rs', caseSensitive: false),
      RegExp(r'INSERT\s+INTO\s+(public\.)?profiles.*@example\.com', caseSensitive: false),
    ];

    final violations = <String>[];

    for (final file in sqlFiles) {
      final lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('--')) continue;

        for (final pattern in forbiddenPatterns) {
          if (pattern.hasMatch(line)) {
            violations.add('${file.path}:${i + 1} -> "$line"');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'No test users or seed data may be inserted in migrations. Seed belongs in seed.sql: $violations',
    );
  });
}
