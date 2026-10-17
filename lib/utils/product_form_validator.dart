import 'dart:math' as math;

import 'package:mleko/models/category.dart';
import 'package:mleko/models/product_model.dart';
import '../utils/product_helpers.dart';

/// Poslovna logika za kreiranje i uređivanje proizvoda — izdvojena iz
/// `AddEditProductScreen` radi testabilnosti i čitljivosti.
class ProductFormValidator {
  const ProductFormValidator._();

  /// Vraća naziv prve selektovane kategorije iz grupa, ili `null` ako nema.
  static String? firstSelectableCategory(List<CategoryGroup>? groups) {
    if (groups == null) return null;
    for (final group in groups) {
      if (group.selectable.isNotEmpty) {
        return group.selectable.first.name;
      }
    }
    return null;
  }

  /// Razrešava `order_step` po istoj logici kao u ekranu:
  ///
  /// - ako je prosleđen eksplicitni korak > 0, koristi se on;
  /// - pojedinice pojedinim po jedinicama imaju podrazumevane korake;
  /// - za kg kategorije koristi se `suggestedOrderStepKg`;
  /// - konačni korak ne može biti veći od `minOrderKg`.
  static double resolveOrderStep({
    required String category,
    required String name,
    required String unitType,
    required double minOrderKg,
    double? parsedOrderStep,
  }) {
    if (parsedOrderStep != null && parsedOrderStep > 0) {
      return parsedOrderStep;
    }

    if (minOrderKg <= 0) {
      return 0.1;
    }

    final defaultStepByUnit = switch (unitType) {
      ProductModel.unitL => 1.0,
      ProductModel.unitG => 0.05,
      ProductModel.unitPiece => 1.0,
      ProductModel.unitVeza => 1.0,
      ProductModel.unitPak => 1.0,
      _ => suggestedOrderStepKg(
          category: category, name: name, minOrderKg: minOrderKg),
    };

    return math.min(defaultStepByUnit, minOrderKg);
  }

  /// Formatira hint količinu za prikaz kupcu, ili `null` ako je unos nevažeći/prazan.
  static String? formatQuantityHint(String text, String unitType) {
    final raw = text.trim();
    if (raw.isEmpty) return null;
    if (unitType == ProductModel.unitKg) {
      final qty = ProductModel.parseQuantityKg(raw);
      if (qty > 0) {
        return 'Prikaz kupcima: ${ProductModel.formatQuantityWithUnit(qty, ProductModel.unitKg)}';
      }
    } else if (unitType == ProductModel.unitL) {
      final qty = ProductModel.parseQuantityL(raw);
      if (qty > 0) {
        return 'Prikaz kupcima: ${ProductModel.formatQuantityWithUnit(qty, ProductModel.unitL)}';
      }
    }
    return null;
  }
}
