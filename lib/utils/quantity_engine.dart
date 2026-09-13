class QuantityEngine {
  const QuantityEngine._();

  static const double _epsilon = 0.000001;

  /// Centralno razrešavanje koraka poručivanja u skladu sa REPO_BIBLE.md.
  /// Prioritet ima eksplicitni `orderStep` (> 0). Ako nije postavljen, koristi se `minQuantity` (> 0),
  /// a kao poslednji fallback 1.0.
  static double resolveStep({
    required double? orderStep,
    required double minQuantity,
  }) {
    if (orderStep != null && orderStep > 0) {
      return orderStep;
    }
    if (minQuantity > 0) {
      return minQuantity;
    }
    return 1.0;
  }

  /// Proverava da li je zadata količina validna za dati proizvod prema minQuantity i orderStep.
  static bool isProductQuantityValid({
    required double quantity,
    required double minOrderKg,
    required double? orderStep,
  }) {
    final step = resolveStep(orderStep: orderStep, minQuantity: minOrderKg);
    return isValidQuantity(
      quantity: quantity,
      minQuantity: minOrderKg,
      step: step,
    );
  }

  static bool isValidQuantity({
    required double quantity,
    required double minQuantity,
    required double step,
  }) {
    if (quantity + _epsilon < minQuantity) {
      return false;
    }

    final delta = quantity - minQuantity;
    if (delta.abs() < _epsilon) {
      return true;
    }

    final ratio = delta / step;
    return (ratio - ratio.roundToDouble()).abs() < _epsilon;
  }

  static double normalizeQuantity({
    required double quantity,
    required double minQuantity,
    required double step,
  }) {
    if (quantity <= minQuantity) {
      return _roundForStorage(minQuantity);
    }

    final stepsFromMin = ((quantity - minQuantity) / step).roundToDouble();
    return _roundForStorage(minQuantity + (stepsFromMin * step));
  }

  static List<double> generateQuantities({
    required double minQuantity,
    required double maxLimit,
    required double step,
  }) {
    if (step <= 0 || maxLimit + _epsilon < minQuantity) {
      return <double>[];
    }

    final result = <double>[];
    var current = minQuantity;

    while (current <= maxLimit + _epsilon) {
      result.add(_roundForStorage(current));
      current += step;
    }

    return result;
  }

  static double _roundForStorage(double value) {
    return double.parse(value.toStringAsFixed(3));
  }
}
