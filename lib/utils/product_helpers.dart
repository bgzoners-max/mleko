import '../models/product_model.dart';

/// Da li kategorija podrazumeva tečnost (litri) kao osnovnu jedinicu.
bool isVolumeCategory(String categoryName) {
  final lower = categoryName.toLowerCase();
  // Med se prema REPO_BIBLE Sekcija 6 prodaje u kg, a tegle/džem/zimnica u kg ili komadima.
  return lower.contains('tečn') ||
      lower.contains('sirup') ||
      lower.contains('sok') ||
      lower.contains('ulje') ||
      lower.contains('mleko') ||
      lower.contains('sirće') ||
      lower.contains('rakija');
}

/// Automatski postavlja unitType na litar ako kategorija to zahteva.
String inferUnitType(String categoryName, String currentUnit) {
  if (isVolumeCategory(categoryName)) return ProductModel.unitL;
  return currentUnit;
}

bool isKackavaljLike(String text) {
  final lower = text.toLowerCase();
  return lower.contains('kackavalj') || lower.contains('kačkavalj');
}

double suggestedOrderStepKg({
  required String category,
  required String name,
  required double minOrderKg,
}) {
  if (isKackavaljLike('$category $name')) {
    return minOrderKg < 0.1 ? minOrderKg : 0.1;
  }
  return minOrderKg;
}
