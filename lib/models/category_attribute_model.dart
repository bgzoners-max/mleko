import 'package:flutter/material.dart';

enum AttributeType {
  number,
  text,
  select,
  boolean,
}

class CategoryAttributeOption {
  final String value;
  final String label;

  const CategoryAttributeOption({
    required this.value,
    required this.label,
  });
}

class CategoryAttribute {
  final String key;
  final String label;
  final AttributeType type;
  final String? unit;
  final List<CategoryAttributeOption>? options;
  final num? min;
  final num? max;
  final bool isRequired;
  final bool isDecimal;
  final String? hint;
  final IconData? icon;

  const CategoryAttribute({
    required this.key,
    required this.label,
    required this.type,
    this.unit,
    this.options,
    this.min,
    this.max,
    this.isRequired = false,
    this.isDecimal = false,
    this.hint,
    this.icon,
  });

  /// Formatira sirovu vrednost u čitljiv tekst sa jedinicom ili labelom
  String formatValue(dynamic value) {
    if (value == null) return '';

    if (type == AttributeType.boolean) {
      return (value == true || value == 'true') ? 'Da' : 'Ne';
    }

    if (type == AttributeType.select && options != null) {
      final opt = options!.firstWhere(
        (o) => o.value.toString() == value.toString(),
        orElse: () => CategoryAttributeOption(
          value: value.toString(),
          label: value.toString(),
        ),
      );
      return opt.label;
    }

    if (type == AttributeType.number) {
      if (value is num) {
        final hasDecimals = (value % 1) != 0;
        final String formattedNum;
        if (hasDecimals) {
          final parts = value.toString().split('.');
          final integerPart = int.tryParse(parts[0]) ?? 0;
          final decimalPart = parts.length > 1 ? parts[1] : '';
          final formattedInt = integerPart.abs() >= 1000
              ? integerPart.toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (m) => '${m[1]}.',
                  )
              : integerPart.toString();
          formattedNum = decimalPart.isNotEmpty ? '$formattedInt,$decimalPart' : formattedInt;
        } else {
          final intVal = value.toInt();
          formattedNum = intVal.abs() >= 1000
              ? intVal.toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (m) => '${m[1]}.',
                  )
              : intVal.toString();
        }
        return unit != null ? '$formattedNum $unit' : formattedNum;
      }
    }

    final strVal = value.toString();
    return unit != null ? '$strVal $unit' : strVal;
  }
}
