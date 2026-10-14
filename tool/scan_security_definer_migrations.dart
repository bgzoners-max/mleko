import 'dart:io';

/// Heuristički pregled migracija: `SECURITY DEFINER` + `p_*_id` bez `auth.uid()`.
/// Namena: ručni review pri novoj migraciji (javni RPC i trigger-i često nemaju `auth.uid()`).
///
/// Fajlovi sa prefiksom `<= 20260321160000` se preskaču (istorija pre P3 auth guard migracije).
///
/// Pokretanje: `dart run tool/scan_security_definer_migrations.dart`
const _kLegacyCutoff =
    '20260321160000'; // security_definer_rpc_auth_guards — posle ovoga stroži review

void main() {
  final dir = Directory('supabase/migrations');
  if (!dir.existsSync()) {
    stderr.writeln('No supabase/migrations directory.');
    exitCode = 2;
    return;
  }

  /// Javni DEFINER RPC ili agregati — namerno bez `auth.uid()` u celom fajlu.
  const publicFunctions = <String>{
    'get_home_products',
    'get_product_sales_counts',
    'get_product_ratings',
    'get_seller_stats',
    'get_seller_loyalty_stats',
    'get_product_order_count',
    'is_seller_verified',
    'search_products_fts',
    'get_related_seller_products',
    'send_push_notification',
    'invoke_send_push',
    'check_ticket_message_limit',
    'validate_product_delivery_point_same_seller',
    'get_conversation_info_with_profile',
  };

  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  var reviewCount = 0;
  stdout.writeln('SECURITY DEFINER migration scan (heuristic)\n');

  for (final file in files) {
    final text = file.readAsStringSync();
    if (!text.contains('SECURITY DEFINER')) continue;

    final rel = file.path.replaceAll('\\', '/');
    final base = rel.split('/').last;
    final ts = _migrationTimestamp(base);
    final isLegacy = ts != null && ts.compareTo(_kLegacyCutoff) <= 0;

    final definerHits = 'SECURITY DEFINER'.allMatches(text).length;
    final hasAuthUid = text.contains('auth.uid()');
    final hasScopedParam = RegExp(r'\bp_(user|seller|buyer)_id\b').hasMatch(text);

    if (!hasScopedParam) {
      stdout.writeln('OK   $rel  (DEFINER×$definerHits, no p_*_id params)');
      continue;
    }

    if (hasAuthUid) {
      stdout.writeln('OK   $rel  (DEFINER×$definerHits, has auth.uid())');
      continue;
    }

    final fnNames = _extractPublicFunctionNames(text);
    final onlyPublic = fnNames.isNotEmpty &&
        fnNames.every((n) => publicFunctions.contains(n));
    if (onlyPublic) {
      stdout.writeln(
        'OK   $rel  (DEFINER×$definerHits, public allowlist: ${fnNames.join(", ")})',
      );
      continue;
    }

    if (isLegacy) {
      stdout.writeln(
        '—    $rel  (legacy ≤$_kLegacyCutoff, skip strict flag)',
      );
      continue;
    }

    reviewCount++;
    stdout.writeln(
      '>>> REVIEW $rel  DEFINER×$definerHits, p_*_id present, no auth.uid() '
      '(functions: ${fnNames.isEmpty ? "?" : fnNames.join(", ")})',
    );
  }

  stdout.writeln('');
  if (reviewCount == 0) {
    stdout.writeln('Done: nothing flagged for manual review.');
  } else {
    stdout.writeln(
      'Done: $reviewCount file(s) flagged — see docs/SECURITY_DEFINER_RPC.md '
      'and update tool/scan_security_definer_migrations.dart allowlist if intentional.',
    );
  }
}

/// Izvlači `public.name` iz `CREATE ... FUNCTION public.name(` u fajlu.
Set<String> _extractPublicFunctionNames(String text) {
  final re = RegExp(
    r'CREATE\s+(OR\s+REPLACE\s+)?FUNCTION\s+public\.(\w+)\s*\(',
    caseSensitive: false,
  );
  return re.allMatches(text).map((m) => m.group(2)!).toSet();
}

/// `20260228130000_name.sql` → `20260228130000`
String? _migrationTimestamp(String basename) {
  final m = RegExp(r'^(\d{14})_').firstMatch(basename);
  return m?.group(1);
}
