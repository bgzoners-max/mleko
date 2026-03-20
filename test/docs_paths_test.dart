import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Brza provera da CONTRIBUTING i ostali linkovi ka docs/* i dalje postoje na disku.
void main() {
  test('docs referenced from CONTRIBUTING exist', () {
    final contributing = File('CONTRIBUTING.md');
    expect(contributing.existsSync(), isTrue, reason: 'CONTRIBUTING.md missing');

    final text = contributing.readAsStringSync();
    final linkRe = RegExp(r'\[docs/[^\]]+\]\((docs/[^)]+)\)');
    final paths = linkRe
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet()
        .toList()
      ..sort();

    expect(paths, isNotEmpty,
        reason: 'Add at least one [docs/...](docs/...) link in CONTRIBUTING.md');

    for (final p in paths) {
      expect(File(p).existsSync(), isTrue, reason: 'Missing file: $p');
    }
  });

  test('SECURITY_DEFINER_RPC migration file exists', () {
    expect(
      File('supabase/migrations/20260321160000_security_definer_rpc_auth_guards.sql')
          .existsSync(),
      isTrue,
    );
  });
}
