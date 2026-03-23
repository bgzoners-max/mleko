import 'package:supabase_flutter/supabase_flutter.dart';

/// Jedan upit: id → prikazno ime (farm_name ili display_name).
Future<Map<String, String>> fetchProfileDisplayNames(Iterable<String> userIds) async {
  final ids = userIds.toSet().where((id) => id.isNotEmpty).toList();
  if (ids.isEmpty) return {};
  final res = await Supabase.instance.client
      .from('profiles')
      .select('id, farm_name, display_name')
      .inFilter('id', ids);
  final map = <String, String>{};
  for (final row in res as List) {
    final id = row['id'] as String;
    final farm = row['farm_name'] as String?;
    final display = row['display_name'] as String?;
    final raw = (farm != null && farm.trim().isNotEmpty)
        ? farm.trim()
        : (display != null && display.trim().isNotEmpty)
            ? display.trim()
            : 'Korisnik';
    map[id] = raw;
  }
  return map;
}
