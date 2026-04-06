class Category {
  final String id;
  final String name;
  final String? slug;
  final String? icon;
  final int order;
  final String? parentId;
  final String? section;

  const Category({
    required this.id,
    required this.name,
    this.slug,
    this.icon,
    this.order = 0,
    this.parentId,
    this.section,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      icon: json['icon'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
      parentId: json['parent_id'] as String?,
      section: json['section'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon': icon,
      'order': order,
      'parent_id': parentId,
      'section': section,
    };
  }
}

/// Grupa kategorija – roditelj (npr. Sirevi) sa podkategorijama
class CategoryGroup {
  final Category parent;
  final List<Category> children;

  const CategoryGroup({required this.parent, required this.children});

  /// Svi izbori koji se mogu selektovati (podkategorije, ili roditelj ako nema dece)
  List<Category> get selectable =>
      children.isNotEmpty ? children : [parent];
}
