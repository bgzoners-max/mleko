import 'dart:io';

void main() {
  final migrationsDir = Directory('supabase/migrations');
  final files = migrationsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final tablesCreated = <String>{};
  final tablesRlsEnabled = <String>{};
  final policies = <String, List<String>>{};
  final nakedAuthUidPolicies = <String>[];
  final permissiveWritePolicies = <String>[];
  final securityDefinersWithoutSearchPath = <String>[];
  final securityDefiners = <String, Map<String, dynamic>>{};

  for (final file in files) {
    final content = file.readAsStringSync();
    final filename = file.uri.pathSegments.last;

    // 1. Table creation
    final tableMatches = RegExp(
      r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:public\.)?([a-z0-9_]+)\s*\(',
      caseSensitive: false,
    ).allMatches(content);

    for (final m in tableMatches) {
      final tbl = m.group(1)!.toLowerCase();
      tablesCreated.add(tbl);
    }

    // 2. ALTER TABLE ... ENABLE ROW LEVEL SECURITY
    final rlsMatches = RegExp(
      r'ALTER\s+TABLE\s+(?:ONLY\s+)?(?:public\.)?([a-z0-9_]+)\s+ENABLE\s+ROW\s+LEVEL\s+SECURITY',
      caseSensitive: false,
    ).allMatches(content);

    for (final m in rlsMatches) {
      tablesRlsEnabled.add(m.group(1)!.toLowerCase());
    }

    // 3. Security Definers search_path check
    // Look for CREATE [OR REPLACE] FUNCTION ... SECURITY DEFINER
    final funcBlocks = content.split(RegExp(r'CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION', caseSensitive: false));
    for (var i = 1; i < funcBlocks.length; i++) {
      final block = funcBlocks[i];
      if (block.toUpperCase().contains('SECURITY DEFINER')) {
        final nameMatch = RegExp(r'^\s*(?:public\.)?([a-z0-9_]+)\s*\(', caseSensitive: false).firstMatch(block);
        final fnName = nameMatch != null ? nameMatch.group(1)! : 'unknown';
        final hasSearchPath = RegExp(r'SET\s+search_path\s*=', caseSensitive: false).hasMatch(block);
        if (!hasSearchPath) {
          securityDefinersWithoutSearchPath.add('$fnName in $filename');
        }
        securityDefiners[fnName] = {
          'file': filename,
          'hasSearchPath': hasSearchPath,
        };
      }
    }

    // 4. Policy analysis
    final policyMatches = RegExp(
      r'CREATE\s+POLICY\s+"?([^"\s]+)"?\s+ON\s+(?:public\.)?([a-z0-9_]+)([\s\S]*?);',
      caseSensitive: false,
    ).allMatches(content);

    for (final m in policyMatches) {
      final policyName = m.group(1)!;
      final table = m.group(2)!.toLowerCase();
      final body = m.group(3)!;

      policies.putIfAbsent(table, () => []).add('$policyName ($filename)');

      // Check for naked auth.uid() (performance rule: should be (select auth.uid()))
      // Regex looks for auth.uid() not immediately preceded by (select
      final hasNakedAuthUid = RegExp(r'(?<!\(\s*select\s+)auth\.uid\(\)', caseSensitive: false).hasMatch(body);
      if (hasNakedAuthUid) {
        nakedAuthUidPolicies.add('$policyName ON $table in $filename');
      }

      // Check for permissive write policies
      final isWrite = RegExp(r'FOR\s+(ALL|INSERT|UPDATE|DELETE)', caseSensitive: false).hasMatch(body);
      final isPermissiveTrue = RegExp(r'(USING|WITH\s+CHECK)\s*\(\s*true\s*\)', caseSensitive: false).hasMatch(body);
      if (isWrite && isPermissiveTrue) {
        permissiveWritePolicies.add('$policyName ON $table ($filename): write with (true)');
      }
    }
  }

  print('=== RLS & DATABASE SECURITY AUDIT ===\n');

  print('1. TABLES WITHOUT RLS:');
  final missingRls = tablesCreated.difference(tablesRlsEnabled);
  if (missingRls.isEmpty) {
    print('  [PASS] All ${tablesCreated.length} tables have RLS explicitly enabled.');
  } else {
    for (final t in missingRls) {
      print('  [FAIL] Table "$t" has NO "ENABLE ROW LEVEL SECURITY" found!');
    }
  }

  print('\n2. SECURITY DEFINER FUNCTIONS MISSING "SET search_path":');
  if (securityDefinersWithoutSearchPath.isEmpty) {
    print('  [PASS] All SECURITY DEFINER functions specify search_path.');
  } else {
    print('  Found ${securityDefinersWithoutSearchPath.length} functions without explicit search_path:');
    for (final s in securityDefinersWithoutSearchPath) {
      print('  - $s');
    }
  }

  print('\n3. RLS POLICIES WITH PERMISSIVE WRITES (USING/WITH CHECK true):');
  if (permissiveWritePolicies.isEmpty) {
    print('  [PASS] No permissive write policies found.');
  } else {
    for (final p in permissiveWritePolicies) {
      print('  - $p');
    }
  }

  print('\n4. RLS POLICIES WITH NAKED auth.uid() (Performance recommendation: (select auth.uid())):');
  print('  Found ${nakedAuthUidPolicies.length} policy definitions with naked auth.uid().');
  for (final p in nakedAuthUidPolicies.take(15)) {
    print('  - $p');
  }
  if (nakedAuthUidPolicies.length > 15) {
    print('  ... and ${nakedAuthUidPolicies.length - 15} more.');
  }
}
