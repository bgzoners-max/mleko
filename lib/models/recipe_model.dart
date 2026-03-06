class RecipeModel {
  final String id;
  final String title;
  final String description;
  final String ingredients;
  final String instructions;
  final String? imageUrl;
  final String category;
  final DateTime createdAt;

  const RecipeModel({
    required this.id,
    required this.title,
    this.description = '',
    this.ingredients = '',
    this.instructions = '',
    this.imageUrl,
    this.category = 'Sir',
    required this.createdAt,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'];
    return RecipeModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      ingredients: json['ingredients'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String? ?? 'Sir',
      createdAt: createdAt != null
          ? (createdAt is String
              ? (DateTime.tryParse(createdAt) ?? DateTime.now())
              : createdAt as DateTime)
          : DateTime.now(),
    );
  }
}
