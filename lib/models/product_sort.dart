/// Način sortiranja proizvoda
enum ProductSort {
  dateDesc,
  dateAsc,
  priceAsc,
  priceDesc,
  location,
  ratingDesc,
}

extension ProductSortX on ProductSort {
  String get label {
    switch (this) {
      case ProductSort.dateDesc:
        return 'Najnovije';
      case ProductSort.dateAsc:
        return 'Najstarije';
      case ProductSort.priceAsc:
        return 'Cena: najniža';
      case ProductSort.priceDesc:
        return 'Cena: najviša';
      case ProductSort.location:
        return 'Lokacija';
      case ProductSort.ratingDesc:
        return 'Najbolje ocenjeni';
    }
  }
}
