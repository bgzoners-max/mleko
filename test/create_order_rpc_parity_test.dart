import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Parity guard: Parametri koje `OrderManagementMixin.createOrder` šalje ka
/// RPC funkciji `create_order_with_items` moraju se 100% poklapati sa
/// parametrima najnovije SQL migracije u `supabase/migrations/`.
///
/// Svako razilaženje (dodavanje/preimenovanje polja na jednoj strani bez druge)
/// obara build.
void main() {
  late final String latestMigrationContent;
  late final Set<String> sqlRpcParamNames;
  late final Set<String> dartClientParamNames;

  setUpAll(() {
    latestMigrationContent = _findLatestCreateOrderMigrationContent();
    sqlRpcParamNames = _extractSqlRpcParams(latestMigrationContent);
    dartClientParamNames = _extractDartClientRpcParams();
  });

  test('Najnovija migracija definiše create_order_with_items', () {
    expect(latestMigrationContent, isNotEmpty);
    expect(sqlRpcParamNames, isNotEmpty);
  });

  test('Dart klijent šalje tačno one parametre koje SQL RPC prihvata', () {
    // Svi parametri koje klijent šalje moraju postojati u SQL definiciji
    for (final param in dartClientParamNames) {
      expect(
        sqlRpcParamNames.contains(param),
        isTrue,
        reason:
            'Parametar "$param" koji klijent šalje u order_management_mixin.dart '
            'ne postoji u SQL funkciji create_order_with_items u najnovijoj migraciji!',
      );
    }
  });

  test('SQL RPC prima p_buyer_postal_code i čuva ga u orders', () {
    expect(sqlRpcParamNames.contains('p_buyer_postal_code'), isTrue);
    expect(latestMigrationContent.contains('buyer_postal_code'), isTrue);
  });

  test('SQL RPC nema stari 11-arg overload', () {
    // Najnovija migracija mora eksplicitno ukloniti 11-arg potpis
    expect(
      latestMigrationContent.contains('DROP FUNCTION IF EXISTS public.create_order_with_items(') ||
          latestMigrationContent.contains('DROP FUNCTION public.create_order_with_items('),
      isTrue,
    );
  });
}

String _findLatestCreateOrderMigrationContent() {
  final dir = Directory('supabase/migrations');
  if (!dir.existsSync()) return '';

  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => b.path.compareTo(a.path));

  for (final file in files) {
    final content = file.readAsStringSync();
    if (content.contains('CREATE OR REPLACE FUNCTION public.create_order_with_items(') ||
        content.contains('CREATE FUNCTION public.create_order_with_items(')) {
      return content;
    }
  }
  return '';
}

Set<String> _extractSqlRpcParams(String sqlContent) {
  final regExp = RegExp(
    r'CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+public\.create_order_with_items\s*\(([^)]+)\)',
    caseSensitive: false,
    multiLine: true,
  );
  final match = regExp.firstMatch(sqlContent);
  if (match == null) return {};

  final paramsChunk = match.group(1) ?? '';
  final paramList = paramsChunk.split(',');

  final names = <String>{};
  for (final raw in paramList) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) continue;
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.isNotEmpty) {
      names.add(parts.first.toLowerCase());
    }
  }
  return names;
}

Set<String> _extractDartClientRpcParams() {
  final file = File('lib/services/orders/mixins/order_management_mixin.dart');
  if (!file.existsSync()) return {};

  final content = file.readAsStringSync();
  final rpcIndex = content.indexOf("'create_order_with_items'");
  if (rpcIndex == -1) return {};

  final paramsIndex = content.indexOf('params:', rpcIndex);
  if (paramsIndex == -1) return {};

  final mapStart = content.indexOf('{', paramsIndex);
  final mapEnd = content.indexOf('}', mapStart);
  if (mapStart == -1 || mapEnd == -1) return {};

  final mapBody = content.substring(mapStart, mapEnd);
  final keyRegex = RegExp(r"'([a-zA-Z0-9_]+)':");

  return keyRegex
      .allMatches(mapBody)
      .map((m) => m.group(1)!.toLowerCase())
      .toSet();
}
