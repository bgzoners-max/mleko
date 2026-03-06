enum UserRole { buyer, seller }

class UserModel {
  final String id;
  final String? email;
  final String? phone;
  final String? displayName;
  final String? city;
  final String? address;
  final UserRole role;
  final bool isGuest;

  final String? farmName;
  final String? location;
  final String? profileImageUrl;
  final double? lat;
  final double? lng;
  final bool isVerified;
  final String? sellerStory;
  final List<String> farmGalleryUrls;
  final List<String> sellerTags;
  final DateTime? createdAt;
  /// Sopstveni šabloni brzih odgovora (samo za prodavce).
  final List<String> sellerQuickReplies;

  const UserModel({
    required this.id,
    this.email,
    this.phone,
    this.displayName,
    this.city,
    this.address,
    this.role = UserRole.buyer,
    this.isGuest = false,
    this.farmName,
    this.location,
    this.profileImageUrl,
    this.lat,
    this.lng,
    this.isVerified = false,
    this.sellerStory,
    this.farmGalleryUrls = const [],
    this.sellerTags = const [],
    this.createdAt,
    this.sellerQuickReplies = const [],
  });

  bool get isSeller => role == UserRole.seller;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      displayName: json['display_name'] as String?,
      city: json['city'] as String?,
      address: json['address'] as String?,
      role: json['role'] == 'seller' ? UserRole.seller : UserRole.buyer,
      isGuest: json['is_guest'] as bool? ?? false,
      farmName: json['farm_name'] as String?,
      location: json['location'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      isVerified: json['is_verified'] as bool? ?? false,
      sellerStory: json['seller_story'] as String?,
      farmGalleryUrls: (json['farm_gallery_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      sellerTags: (json['seller_tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      sellerQuickReplies: (json['seller_quick_replies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (displayName != null) 'display_name': displayName,
      if (city != null) 'city': city,
      if (address != null) 'address': address,
      'role': role == UserRole.seller ? 'seller' : 'buyer',
      'is_guest': isGuest,
      if (farmName != null) 'farm_name': farmName,
      if (location != null) 'location': location,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      if (sellerQuickReplies.isNotEmpty) 'seller_quick_replies': sellerQuickReplies,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? displayName,
    String? city,
    String? address,
    UserRole? role,
    bool? isGuest,
    String? farmName,
    String? location,
    String? profileImageUrl,
    double? lat,
    double? lng,
    bool? isVerified,
    String? sellerStory,
    List<String>? farmGalleryUrls,
    List<String>? sellerTags,
    DateTime? createdAt,
    List<String>? sellerQuickReplies,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      city: city ?? this.city,
      address: address ?? this.address,
      role: role ?? this.role,
      isGuest: isGuest ?? this.isGuest,
      farmName: farmName ?? this.farmName,
      location: location ?? this.location,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isVerified: isVerified ?? this.isVerified,
      sellerStory: sellerStory ?? this.sellerStory,
      farmGalleryUrls: farmGalleryUrls ?? this.farmGalleryUrls,
      sellerTags: sellerTags ?? this.sellerTags,
      createdAt: createdAt ?? this.createdAt,
      sellerQuickReplies: sellerQuickReplies ?? this.sellerQuickReplies,
    );
  }
}
