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
