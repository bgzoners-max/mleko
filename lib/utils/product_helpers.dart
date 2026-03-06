import '../models/product_model.dart';

/// Da li kategorija podrazumeva tečnost (litri) kao osnovnu jedinicu.
bool isVolumeCategory(String categoryName) {
  final lower = categoryName.toLowerCase();
  return lower.contains('tečn') || lower.contains('zimnic') ||
      lower.contains('tegl') || lower.contains('tegla') ||
      lower.contains('džem') || lower.contains('sirup') ||
      lower.contains('sok') || lower.contains('med') ||
      lower.contains('ulje') || lower.contains('mleko') ||
      lower.contains('sirće') || lower.contains('rakija');
}

/// Automatski postavlja unitType na litar ako kategorija to zahteva.
String inferUnitType(String categoryName, String currentUnit) {
  if (isVolumeCategory(categoryName)) return ProductModel.unitL;
  return currentUnit;
}
