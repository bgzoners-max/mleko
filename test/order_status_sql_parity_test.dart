import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/utils/order_status_flow_rules.dart';

/// Parity guard: Dart pravila toka statusa porudžbine moraju da odgovaraju
/// SQL trigeru `enforce_order_status_transition()`.
///
/// Postoje dva izvora istine (Dart za UI/klijent, SQL za bazu). Ovaj test čita
/// najnoviju migraciju koja (re)definiše funkciju i upoređuje dozvoljene
/// tranzicije sa `OrderStatusFlowRules.isAllowedTransition`. Svako buduće
/// razilaženje obara build.
void main() {
  const allStatuses = [
    'sent',
    'accepted',
    'shipped',
    'rejected',
    'delivered',
    'cancelled_by_seller',
    'archived',
  ];

  late final Map<String, Set<String>> sqlTransitions;

  setUpAll(() {
    final body = _latestEnforceTransitionBody();
    sqlTransitions = _parseSystemTransitions(body, allStatuses);
  });

  test('SQL trigger function is present in migrations', () {
    expect(_latestEnforceTransitionBody(), isNotEmpty);
  });

  test('SQL system transitions match Dart isAllowedTransition', () {
    for (final old in allStatuses) {
      for (final next in allStatuses) {
        final dartAllowed = OrderStatusFlowRules.isAllowedTransition(
          oldStatus: old,
          newStatus: next,
        );
        final sqlAllowed = sqlTransitions[old]?.contains(next) ?? false;
        // Za isti status Dart dozvoljava (no-op), SQL se kratko vraća pre CASE-a.
        if (old == next) {
          expect(dartAllowed, isTrue,
              reason: 'Dart treba da dozvoli tranziciju $old -> $next');
          continue;
        }
        expect(
          dartAllowed,
          sqlAllowed,
          reason: 'Nesklad Dart vs SQL za $old -> $next '
              '(dart=$dartAllowed, sql=$sqlAllowed)',
        );
      }
    }
  });

  test('SQL enforced transitions match Dart for role guards', () {
    final body = _latestEnforceTransitionBody();

    // Buyer is the only one who confirms receipt (delivered).
    expect(body.contains('NEW.status = \'delivered\''), isTrue);
    expect(body.contains('v_is_buyer'), isTrue);
    // Seller/buyer may archive terminal statuses.
    expect(
      RegExp(r"\(v_is_seller OR v_is_buyer\)\s+AND\s+NEW\.status = 'archived'")
          .hasMatch(body),
      isTrue,
      reason: 'SQL treba da dozvoli archiviranje i kupcu i prodavcu',
    );
    // Transition matrix sanity: archived is terminal in Dart.
    for (final next in allStatuses) {
      expect(
        OrderStatusFlowRules.isAllowedTransition(
          oldStatus: 'archived',
          newStatus: next,
        ),
        next == 'archived',
      );
    }
  });
}

/// Nađe najnoviju migraciju (po nazivu) koja definiše funkciju i vrati njeno telo.
String _latestEnforceTransitionBody() {
  final dir = Directory('supabase/migrations');
  expect(dir.existsSync(), isTrue,
      reason: 'supabase/migrations direktorijum mora postojati');

  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  const marker = 'FUNCTION public.enforce_order_status_transition';

  String? lastBody;
  for (final f in files) {
    final content = f.readAsStringSync();
    final markerIdx = content.indexOf(marker);
    if (markerIdx < 0) continue;
    final body = _extractFunctionBody(content, markerIdx);
    if (body != null) lastBody = body;
  }

  expect(lastBody, isNotNull,
      reason: 'Nije nađena nijedna migracija sa $marker');
  return lastBody!;
}

/// Izvuče telo funkcije između `$$` ... `$$;` počev od [fromIndex].
String? _extractFunctionBody(String content, int fromIndex) {
  final open = content.indexOf(r'$$', fromIndex);
  if (open < 0) return null;
  final close = content.indexOf(r'$$;', open + 2);
  if (close < 0) return null;
  return content.substring(open + 2, close);
}

/// Parsira sve `CASE OLD.status` blokove (sistemski + role) i vrati uniju
/// dozvoljenih tranzicija po starom statusu — role-agnostički, što odgovara
/// Dart `isAllowedTransition`.
Map<String, Set<String>> _parseSystemTransitions(
  String body,
  List<String> allStatuses,
) {
  final result = <String, Set<String>>{};
  for (final old in allStatuses) {
    result[old] = <String>{};
  }

  // Podeli po `WHEN '<status>'` — svaki chunk počinje starim statusom, a sadrži
  // `NEW.status = 'x'` ili `NEW.status IN ('x', 'y')` ili `false`.
  final chunks = body.split(RegExp(r"WHEN\s+'"));
  final equalsRe = RegExp(r"NEW\.status\s*=\s*'(\w+)'");
  final inRe = RegExp(r"NEW\.status\s+IN\s*\(([^)]*)\)");

  for (var i = 1; i < chunks.length; i++) {
    final chunk = chunks[i];
    final old = chunk.split("'").first;
    if (!result.containsKey(old)) continue;

    for (final m in equalsRe.allMatches(chunk)) {
      result[old]!.add(m.group(1)!);
    }
    for (final m in inRe.allMatches(chunk)) {
      final raw = m.group(1)!;
      for (final token in raw.split(',')) {
        final cleaned = token.replaceAll(RegExp(r"[\s']"), '');
        if (cleaned.isNotEmpty) result[old]!.add(cleaned);
      }
    }
  }

  return result;
}
