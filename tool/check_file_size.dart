import 'dart:io';

const int lineThreshold = 700;

// Privremena lista za ekrane koji cekaju modularizaciju (preko 700 linija).
const List<String> ignoreFiles = [
  'lib/screens/seller/seller_settings_screen.dart',
];

void main() {
  final dir = Directory('lib');
  if (!dir.existsSync()) {
    print('Greška: lib direktorijum ne postoji.');
    exit(1);
  }

  bool hasErrors = false;
  
  // Rekurzivno pronalazimo sve .dart fajlove
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    // Normalizujemo putanju (zbog Windows/Linux razlika)
    final normalizedPath = file.path.replaceAll('\\', '/');
    
    if (ignoreFiles.any((ignore) => normalizedPath.endsWith(ignore))) {
      continue;
    }

    final lines = file.readAsLinesSync();
    if (lines.length > lineThreshold) {
      print('❌ GREŠKA: Fajl ${file.path} ima ${lines.length} linija (maksimum je $lineThreshold).');
      print('   Molimo refaktorišite kod i razdvojite UI/logiku u odvojene fajlove.');
      hasErrors = true;
    }
  }

  if (hasErrors) {
    print('\nZabranjeno je dodavanje novih fajlova ili uvećavanje postojećih preko 700 linija.');
    exit(1);
  } else {
    print('✅ Svi neizuzeti fajlovi poštuju limit od $lineThreshold linija.');
    exit(0);
  }
}
