import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Regresiona zaštita: bundle-ovani Bitter fontovi moraju biti PUNI TTF
/// fajlovi (sa latin-ext skupom za č/ć/š/ž/đ), ne latin-only subseti.
///
/// Veličine i imena odgovaraju kanonskim Google fajlovima koje očekuje
/// `google_fonts` paket — asset se poklapa po sufiksu imena fajla
/// ("Bitter-Regular", "Bitter-SemiBold", "Bitter-Bold", ...).
/// Izvor je kanonski Google Fonts endpoint sa SHA-256 verifikacijom.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Bundled Bitter font assets are full TTF files (not latin subsets)',
      () async {
    const expectedSizes = <String, int>{
      'Bitter-Regular': 149308,
      'Bitter-Medium': 149532,
      'Bitter-SemiBold': 149504,
      'Bitter-Bold': 150576,
    };

    for (final entry in expectedSizes.entries) {
      final path = 'assets/google_fonts/${entry.key}.ttf';
      final data = await rootBundle.load(path);
      expect(
        data.lengthInBytes,
        entry.value,
        reason:
            '$path ima pogrešnu veličinu — verovatno je preuzet latin-only '
            'subset bez č/ć/š/ž/đ. Preuzmi pun fajl sa fonts.gstatic.com.',
      );
      // TrueType magic: 0x00 0x01 0x00 0x00
      expect(
        data.getUint16(0),
        0x0001,
        reason: '$path nije validan TrueType font.',
      );
    }
  });

  test('Bitter OFL licence accompanies the bundled font files', () async {
    final license =
        await rootBundle.loadString('assets/google_fonts/Bitter-OFL.txt');
    expect(license, contains('SIL OPEN FONT LICENSE'));
  });

  test('Bundled Roboto font assets are full TTF files with proper sizes',
      () async {
    const expectedRobotoSizes = <String, int>{
      'Roboto-Regular': 89960,
      'Roboto-Medium': 90088,
      'Roboto-Bold': 90536,
      'Roboto-Light': 90008,
    };

    for (final entry in expectedRobotoSizes.entries) {
      final path = 'assets/google_fonts/${entry.key}.ttf';
      final data = await rootBundle.load(path);
      expect(
        data.lengthInBytes,
        entry.value,
        reason: '$path ima pogrešnu veličinu.',
      );
      // TrueType magic: 0x00 0x01 0x00 0x00
      expect(
        data.getUint16(0),
        0x0001,
        reason: '$path nije validan TrueType font.',
      );
    }
  });

  test('Roboto OFL license accompanies the bundled font files', () async {
    final license =
        await rootBundle.loadString('assets/google_fonts/OFL.txt');
    expect(license, contains('SIL OPEN FONT LICENSE'));
  });
}
