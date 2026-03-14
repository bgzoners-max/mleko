class QuantityEngine {
  const QuantityEngine._();

  static const double _epsilon = 0.000001;

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
