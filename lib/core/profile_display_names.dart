import 'package:supabase_flutter/supabase_flutter.dart';

/// Određuje prikazno ime profila po prioritetu: farm_name -> display_name -> 'Korisnik'.
String resolveProfileDisplayName(String? farmName, String? displayName) {
  final farm = farmName?.trim();
  if (farm != null && farm.isNotEmpty) return farm;
  final display = displayName?.trim();
  if (display != null && display.isNotEmpty) return display;
  return 'Korisnik';
}

/// Jedan upit: id → prikazno ime (farm_name ili display_name).
Future<Map<String, String>> fetchProfileDisplayNames(
  Iterable<String> userIds, {
  SupabaseClient? client,
}) async {
  final ids = userIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet().toList();
  if (ids.isEmpty) return {};
  final supa = client ?? Supabase.instance.client;
  final res = await supa
      .from('public_profiles')
      .select('id, farm_name, display_name')
      .inFilter('id', ids);
  final map = <String, String>{};
  for (final row in res as List) {
    final id = row['id'] as String;
    final farm = row['farm_name'] as String?;
    final display = row['display_name'] as String?;
    map[id] = resolveProfileDisplayName(farm, display);
  }
  return map;
}

