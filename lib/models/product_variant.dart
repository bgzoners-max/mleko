import 'dart:convert';

class ProductVariant {
  final String id;
  final String label;
  final double price;
  final String? group;

  const ProductVariant({
    required this.id,
    required this.label,
    required this.price,
    this.group,
  });

  static String normalizeId(String raw) {
    final trimmed = raw.trim().toLowerCase();
    final slug = trimmed
        .replaceAll('č', 'c')
        .replaceAll('ć', 'c')
        .replaceAll('š', 's')
        .replaceAll('đ', 'dj')
        .replaceAll('ž', 'z')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isNotEmpty ? slug : 'varijanta';
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final label = (json['label'] as String? ?? '').trim();
    final rawId = (json['id'] as String? ?? '').trim();
    final id = rawId.isNotEmpty ? rawId : normalizeId(label);
    final price = (json['price'] as num?)?.toDouble() ?? 0.0;
    final group = (json['group'] as String?)?.trim();
    return ProductVariant(
      id: id,
      label: label,
      price: price,
      group: (group != null && group.isNotEmpty) ? group : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'price': price,
        if (group != null && group!.isNotEmpty) 'group': group,
      };

  ProductVariant copyWith({
    String? id,
    String? label,
    double? price,
    String? group,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      label: label ?? this.label,
      price: price ?? this.price,
      group: group ?? this.group,
    );
  }

  static List<ProductVariant> listFromDynamic(dynamic raw) {
    if (raw == null) return const [];
    dynamic decoded = raw;
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return const [];
      try {
        decoded = jsonDecode(trimmed);
      } catch (_) {
        return const [];
      }
    }
    if (decoded is! List) return const [];
    final result = <ProductVariant>[];
    for (final item in decoded) {
      if (item is Map) {
        final variant = ProductVariant.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (variant.label.isNotEmpty && variant.price > 0) {
          result.add(variant);
        }
      }
    }
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductVariant &&
        other.id == id &&
        other.label == label &&
        other.price == price &&
        other.group == group;
  }

  @override
  int get hashCode => Object.hash(id, label, price, group);
}
