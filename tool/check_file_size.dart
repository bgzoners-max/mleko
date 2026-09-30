import 'dart:io';

const int lineThreshold = 700;

// Lista izuzetaka za fajlove koji su trenutno preveliki.
// Cilj je postepeno refaktorisati ove fajlove i uklanjati ih sa ove liste.
// Novi fajlovi (ili rastući fajlovi) ne smeju preći [lineThreshold]!
const List<String> ignoreFiles = [
  // Blizu granice (713-726 linija) — nisu bili deo ovog refaktora.
  // Sledeci ciklus: razbiti ispod 700 i ukloniti sa ove liste.
  'lib/core/router.dart',
  'lib/screens/about_screen.dart',
  'lib/screens/classifieds/my_classified_ads_screen.dart',
  'lib/screens/search_screen.dart',

  // Jos uvek preko limita — refaktorisati u sledecoj fazi.
  'lib/screens/admin/admin_push_health_screen.dart',
  'lib/screens/admin/classifieds_moderation_screen.dart',
  'lib/screens/seller/add_edit_product_screen.dart',
  'lib/screens/seller/seller_orders_screen.dart',
  'lib/services/communication/chat_service.dart',
  'lib/widgets/skeleton.dart',
  'lib/widgets/checkout/checkout_multi_form.dart',
  'lib/widgets/classifieds/classified_ad_card.dart',
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
