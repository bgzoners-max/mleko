/// MVP konstante – kategorije, regioni, način preuzimanja.
class AppConstants {
  AppConstants._();

  static const String appName = 'Naše selo';
  static const String appTagline = 'Naša snaga';

  static const List<String> regions = [
    'Vojvodina',
    'Šumadija',
    'Beograd',
    'Južna Srbija',
    'Istočna Srbija',
    'Zapadna Srbija',
  ];

  static const List<String> pickupOptions = ['Lično', 'Kurir', 'Dogovor'];

  static const int maxProductDescriptionLength = 300;
  static const int maxProductImages = 3;

  /// Proizvod je „Novo“ ako je kreiran u poslednjih N dana
  static const int newProductDays = 14;
  /// Proizvod je „Popularno“ ako ima bar N prodaja
  static const int popularProductMinSales = 2;
}
