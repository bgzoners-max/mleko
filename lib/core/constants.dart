/// MVP konstante – kategorije, regioni, način preuzimanja.
class AppConstants {
  AppConstants._();

  static const String appName = 'Domaći market';
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

  /// Proizvod dobija bedž „NOVO“ ako je kreiran u poslednjih N sati (prvih 24h)
  static const int newProductHours = 24;
  /// Proizvod je „Novo“ za sekciju na početnoj ako je kreiran u poslednjih N dana
  static const int newProductDays = 14;
  /// Proizvod je „Popularno“ ako ima bar N prodaja
  static const int popularProductMinSales = 2;
}
