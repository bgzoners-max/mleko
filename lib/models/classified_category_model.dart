import 'package:flutter/material.dart';

class ClassifiedCategoryModel {
  final String id;
  final String name;
  final String iconName;
  final String? parentId;
  final int sortOrder;
  final List<ClassifiedCategoryModel> subcategories;

  const ClassifiedCategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    this.parentId,
    this.sortOrder = 0,
    this.subcategories = const [],
  });

  bool get isRoot => parentId == null;

  factory ClassifiedCategoryModel.fromJson(
    Map<String, dynamic> json, {
    List<ClassifiedCategoryModel> subcategories = const [],
  }) {
    return ClassifiedCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['icon_name'] as String? ?? 'category',
      parentId: json['parent_id'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      subcategories: subcategories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'parent_id': parentId,
      'sort_order': sortOrder,
    };
  }

  ClassifiedCategoryModel copyWith({
    List<ClassifiedCategoryModel>? subcategories,
  }) {
    return ClassifiedCategoryModel(
      id: id,
      name: name,
      iconName: iconName,
      parentId: parentId,
      sortOrder: sortOrder,
      subcategories: subcategories ?? this.subcategories,
    );
  }

  IconData get iconData {
    switch (iconName) {
      case 'agriculture':
        return Icons.agriculture;
      case 'directions_car':
        return Icons.directions_car;
      case 'handyman':
        return Icons.handyman;
      case 'chair':
        return Icons.chair;
      case 'smartphone':
        return Icons.smartphone;
      case 'laptop':
        return Icons.laptop;
      case 'home_work':
        return Icons.home_work;
      case 'foundation':
        return Icons.foundation;
      case 'checkroom':
        return Icons.checkroom;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'pets':
        return Icons.pets;
      case 'work':
        return Icons.work;
      case 'grass':
        return Icons.grass;
      case 'yard':
        return Icons.yard;
      case 'build':
        return Icons.build;
      case 'two_wheeler':
        return Icons.two_wheeler;
      case 'kitchen':
        return Icons.kitchen;
      case 'construction':
        return Icons.construction;
      default:
        return Icons.category;
    }
  }
}
