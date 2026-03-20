import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Provere da lokalni markdown linkovi i putanje iz README/CONTRIBUTING postoje.
void main() {
  test('CONTRIBUTING: docs/*.md links exist', () {
    final contributing = File('CONTRIBUTING.md');
    expect(contributing.existsSync(), isTrue);

    final text = contributing.readAsStringSync();
    final linkRe = RegExp(r'\[docs/[^\]]+\]\((docs/[^)]+)\)');
    final paths = linkRe.allMatches(text).map((m) => m.group(1)!).toSet().toList()
      ..sort();

    expect(paths, isNotEmpty);
    for (final path in paths) {
      expect(File(path).existsSync(), isTrue, reason: 'Missing file: $path');
    }
  });

  test('README: local markdown link targets exist', () {
    final readme = File('README.md');
    expect(readme.existsSync(), isTrue);

    final targets = _localMarkdownLinkTargets(readme.readAsStringSync());
    expect(targets, isNotEmpty,
        reason: 'README should contain at least one local [text](path) link');

    final baseUri = readme.absolute.parent.uri;
    for (final t in targets) {
      final resolved = baseUri.resolve(t).toFilePath();
      expect(File(resolved).existsSync(), isTrue,
          reason: 'Missing target for link: $t → $resolved');
    }
  });

  test('README references DB integration SQL path', () {
    final text = File('README.md').readAsStringSync();
    expect(
      text.contains('supabase/tests/order_status_flow_integration.sql'),
      isTrue,
    );
    expect(
      File('supabase/tests/order_status_flow_integration.sql').existsSync(),
      isTrue,
    );
  });

  test('SECURITY_DEFINER auth guards migration exists', () {
    expect(
      File('supabase/migrations/20260321160000_security_definer_rpc_auth_guards.sql')
          .existsSync(),
      isTrue,
    );
  });
}

/// Lokalni ciljevi iz `[label](target)` — bez http(s), mailto, praznih, samo #.
List<String> _localMarkdownLinkTargets(String markdown) {
  final re = RegExp(r'\[([^\]]*)\]\(([^)]+)\)');
  final out = <String>[];
  for (final m in re.allMatches(markdown)) {
    var target = m.group(2)!.trim();
    if (target.startsWith('http://') || target.startsWith('https://')) {
      continue;
    }
    if (target.startsWith('mailto:')) continue;
    final hash = target.indexOf('#');
    if (hash >= 0) target = target.substring(0, hash);
    target = target.trim();
    if (target.isEmpty) continue;
    out.add(target);
  }
  return out;
}
