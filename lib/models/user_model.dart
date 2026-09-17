enum UserRole { buyer, seller }

class UserModel {
  final String id;
  final String? email;
  final String? phone;
  final String? displayName;
  final String? city;
  final String? address;
  final String? postalCode;
  final UserRole role;
  final bool isGuest;

  final String? farmName;
  final String? location;
  final String? profileImageUrl;
  final double? lat;
  final double? lng;
  final bool isVerified;
  final bool phonePublic;
  final String? sellerStory;
  final List<String> farmGalleryUrls;
  final List<String> sellerTags;
  final DateTime? createdAt;

  /// Sopstveni šabloni brzih odgovora (samo za prodavce).
  final List<String> sellerQuickReplies;

  final bool isAdmin;

  const UserModel({
    required this.id,
    this.email,
    this.phone,
    this.displayName,
    this.city,
    this.address,
    this.postalCode,
    this.role = UserRole.buyer,
    this.isGuest = false,
    this.farmName,
    this.location,
    this.profileImageUrl,
    this.lat,
    this.lng,
    this.isVerified = false,
    this.phonePublic = false,
    this.sellerStory,
    this.farmGalleryUrls = const [],
    this.sellerTags = const [],
    this.createdAt,
    this.sellerQuickReplies = const [],
    this.isAdmin = false,
  });

  bool get isSeller => role == UserRole.seller;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final role = json['role'] == 'seller' ? UserRole.seller : UserRole.buyer;
    final location = json['location'] as String?;
    // Kupci čuvaju adresu dostave u DB koloni `location` (nema posebne `address` kolone).
    final address = role == UserRole.buyer ? location : null;

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      displayName: json['display_name'] as String?,
      city: json['city'] as String?,
      address: address,
      postalCode: json['postal_code'] as String?,
      role: role,
      isGuest: json['is_guest'] as bool? ?? false,
      farmName: json['farm_name'] as String?,
      location: location,
      profileImageUrl: json['profile_image_url'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      isVerified: json['is_verified'] as bool? ?? false,
      phonePublic: json['phone_public'] as bool? ?? false,
      sellerStory: json['seller_story'] as String?,
      farmGalleryUrls: (json['farm_gallery_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sellerTags: (json['seller_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      sellerQuickReplies: (json['seller_quick_replies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isAdmin: json['is_admin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (displayName != null) 'display_name': displayName,
      if (city != null) 'city': city,
      if (postalCode != null) 'postal_code': postalCode,
      // `address` (kupci) i `location` (prodavci) dele istu DB kolonu `location`.
      if (location != null) 'location': location,
      if (address != null && location == null) 'location': address,
      'phone_public': phonePublic,
      'role': role == UserRole.seller ? 'seller' : 'buyer',
      'is_guest': isGuest,
      if (farmName != null) 'farm_name': farmName,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      if (sellerQuickReplies.isNotEmpty)
        'seller_quick_replies': sellerQuickReplies,
    };
  }

  // Sentinel vrednost za copyWith da razlikuje "nije prosleđeno" od "prosleđeno null"
  static const Object _undefined = Object();

  UserModel copyWith({
    String? id,
    Object? email = _undefined,
    Object? phone = _undefined,
    Object? displayName = _undefined,
    Object? city = _undefined,
    Object? address = _undefined,
    Object? postalCode = _undefined,
    UserRole? role,
    bool? isGuest,
    Object? farmName = _undefined,
    Object? location = _undefined,
    Object? profileImageUrl = _undefined,
    Object? lat = _undefined,
    Object? lng = _undefined,
    bool? isVerified,
    bool? phonePublic,
    Object? sellerStory = _undefined,
    List<String>? farmGalleryUrls,
    List<String>? sellerTags,
    Object? createdAt = _undefined,
    List<String>? sellerQuickReplies,
    bool? isAdmin,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: identical(email, _undefined) ? this.email : email as String?,
      phone: identical(phone, _undefined) ? this.phone : phone as String?,
      displayName: identical(displayName, _undefined) ? this.displayName : displayName as String?,
      city: identical(city, _undefined) ? this.city : city as String?,
      address: identical(address, _undefined) ? this.address : address as String?,
      postalCode: identical(postalCode, _undefined) ? this.postalCode : postalCode as String?,
      role: role ?? this.role,
      isGuest: isGuest ?? this.isGuest,
      farmName: identical(farmName, _undefined) ? this.farmName : farmName as String?,
      location: identical(location, _undefined) ? this.location : location as String?,
      profileImageUrl: identical(profileImageUrl, _undefined) ? this.profileImageUrl : profileImageUrl as String?,
      lat: identical(lat, _undefined) ? this.lat : lat as double?,
      lng: identical(lng, _undefined) ? this.lng : lng as double?,
      isVerified: isVerified ?? this.isVerified,
      phonePublic: phonePublic ?? this.phonePublic,
      sellerStory: identical(sellerStory, _undefined) ? this.sellerStory : sellerStory as String?,
      farmGalleryUrls: farmGalleryUrls ?? this.farmGalleryUrls,
      sellerTags: sellerTags ?? this.sellerTags,
      createdAt: identical(createdAt, _undefined) ? this.createdAt : createdAt as DateTime?,
      sellerQuickReplies: sellerQuickReplies ?? this.sellerQuickReplies,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
