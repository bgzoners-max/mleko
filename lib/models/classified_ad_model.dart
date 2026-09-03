class ClassifiedAdModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double price;
  final String currency; // 'RSD' | 'EUR'
  final String priceType; // 'fixed' | 'negotiable' | 'call' | 'free'
  final String categoryId;
  final String? categoryName;
  final String condition; // 'new' | 'used' | 'not_applicable'
  final List<String> images;
  final String city;
  final String? phone;
  final bool phonePublic;
  final String status; // 'active' | 'sold' | 'archived'
  final int viewsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? sellerName;
  final String? sellerAvatar;

  const ClassifiedAdModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.price,
    this.currency = 'RSD',
    this.priceType = 'fixed',
    required this.categoryId,
    this.categoryName,
    this.condition = 'used',
    this.images = const [],
    required this.city,
    this.phone,
    this.phonePublic = true,
    this.status = 'active',
    this.viewsCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.sellerName,
    this.sellerAvatar,
  });

  bool get isActive => status == 'active';
  bool get isSold => status == 'sold';
  bool get isArchived => status == 'archived';

  String get priceFormatted {
    if (priceType == 'free') return 'Besplatno';
    if (priceType == 'call') return 'Pozvati za cenu';
    if (priceType == 'negotiable' && price <= 0) return 'Cena po dogovoru';

    final formattedNum = price >= 1000
        ? price.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]}.',
            )
        : price.toStringAsFixed(0);

    if (priceType == 'negotiable') {
      return '$formattedNum $currency (dogovor)';
    }
    return '$formattedNum $currency';
  }

  String get conditionLabel {
    switch (condition) {
      case 'new':
        return 'Novo';
      case 'used':
        return 'Polovno';
      default:
        return 'Standardno';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return 'pre $months ${months == 1 ? 'mesec' : 'meseca'}';
    }
    if (diff.inDays > 0) {
      return 'pre ${diff.inDays} ${diff.inDays == 1 ? 'dan' : 'dana'}';
    }
    if (diff.inHours > 0) {
      return 'pre ${diff.inHours} ${diff.inHours == 1 ? 'sat' : 'sata'}';
    }
    if (diff.inMinutes > 0) {
      return 'pre ${diff.inMinutes} min';
    }
    return 'Upravo objavljeno';
  }

  factory ClassifiedAdModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final cat = json['classified_categories'] as Map<String, dynamic>?;

    return ClassifiedAdModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'RSD',
      priceType: json['price_type'] as String? ?? 'fixed',
      categoryId: json['category_id'] as String? ?? '',
      categoryName: cat?['name'] as String?,
      condition: json['condition'] as String? ?? 'used',
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String?,
      phonePublic: json['phone_public'] as bool? ?? true,
      status: json['status'] as String? ?? 'active',
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      sellerName: profile?['farm_name'] as String? ??
          profile?['display_name'] as String?,
      sellerAvatar: profile?['profile_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'price_type': priceType,
      'category_id': categoryId,
      'condition': condition,
      'images': images,
      'city': city,
      if (phone != null) 'phone': phone,
      'phone_public': phonePublic,
      'status': status,
      'views_count': viewsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
