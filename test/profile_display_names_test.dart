import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/core/profile_display_names.dart';

void main() {
  group('Profile Display Names Tests', () {
    test('resolveProfileDisplayName prefers farm_name over display_name', () {
      expect(
        resolveProfileDisplayName('Gazdinstvo Petrović', 'Petar'),
        'Gazdinstvo Petrović',
      );
      expect(
        resolveProfileDisplayName('  Farma Jović  ', 'Jovan'),
        'Farma Jović',
      );
    });

    test('resolveProfileDisplayName falls back to display_name when farm_name is empty', () {
      expect(
        resolveProfileDisplayName(null, 'Milica'),
        'Milica',
      );
      expect(
        resolveProfileDisplayName('   ', '  Marko  '),
        'Marko',
      );
    });

    test('resolveProfileDisplayName defaults to Korisnik when both are empty or null', () {
      expect(resolveProfileDisplayName(null, null), 'Korisnik');
      expect(resolveProfileDisplayName('', ''), 'Korisnik');
      expect(resolveProfileDisplayName('   ', '   '), 'Korisnik');
    });

    test('fetchProfileDisplayNames returns empty map for empty or blank IDs without querying', () async {
      final res1 = await fetchProfileDisplayNames([]);
      expect(res1, isEmpty);

      final res2 = await fetchProfileDisplayNames(['', '   ']);
      expect(res2, isEmpty);
    });
  });
}
