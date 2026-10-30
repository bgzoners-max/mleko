enum UserRole { buyer, seller }

/// Eksplicitni DTO za profil kupca
class BuyerProfile {
  final String id;
  final String? email;
  final String? phone;
  final String? displayName;
  final String? city;
  final String? address;
  final String? postalCode;
  final bool isGuest;
  final String? profileImageUrl;
  final DateTime? createdAt;

  const BuyerProfile({
    required this.id,
    this.email,
    this.phone,
    this.displayName,
    this.city,
    this.address,
    this.postalCode,
    this.isGuest = false,
    this.profileImageUrl,
    this.createdAt,
  });

  factory BuyerProfile.fromUserModel(UserModel user) {
    return BuyerProfile(
      id: user.id,
      email: user.email,
      phone: user.phone,
      displayName: user.displayName,
      city: user.city,
      address: user.buyerAddress,
      postalCode: user.postalCode,
      isGuest: user.isGuest,
      profileImageUrl: user.profileImageUrl,
      createdAt: user.createdAt,
    );
  }

  factory BuyerProfile.fromJson(Map<String, dynamic> json) {
    return BuyerProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      displayName: json['display_name'] as String?,
      city: json['city'] as String?,
      address: (json['address'] as String?) ?? (json['location'] as String?),
      postalCode: json['postal_code'] as String?,
      isGuest: json['is_guest'] as bool? ?? false,
      profileImageUrl: json['profile_image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  UserModel toUserModel() {
    return UserModel(
      id: id,
      email: email,
      phone: phone,
      displayName: displayName,
      city: city,
      address: address,
      postalCode: postalCode,
      role: UserRole.buyer,
      isGuest: isGuest,
      location: address,
      profileImageUrl: profileImageUrl,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (displayName != null) 'display_name': displayName,
      if (city != null) 'city': city,
      if (address != null) 'address': address,
      if (address != null) 'location': address, // DB backward-kompatibilnost
      if (postalCode != null) 'postal_code': postalCode,
      'role': 'buyer',
      'is_guest': isGuest,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
    };
  }
}

/// Eksplicitni DTO za profil prodavca
class SellerProfile {
  final String id;
  final String? email;
  final String? phone;
  final bool phonePublic;
  final String? displayName;
  final String? farmName;
  final String? city;
  final String? postalCode;
  final String? location; // Lokacija gazdinstva / farme
  final String? address;  // Opciona fizička/poslovna adresa
  final String? profileImageUrl;
  final double? lat;
  final double? lng;
  final bool isVerified;
  final String? sellerStory;
  final List<String> farmGalleryUrls;
  final List<String> sellerTags;
  final List<String> sellerQuickReplies;
  final DateTime? createdAt;
  final String? legalType;
  final String? bpg;
  final String? bpgMasked;
  final String? pib;
  final bool hasRegisteredEntity;
  final DateTime? legalLiabilityAcceptedAt;

  const SellerProfile({
    required this.id,
    this.email,
    this.phone,
    this.phonePublic = false,
    this.displayName,
    this.farmName,
    this.city,
    this.postalCode,
    this.location,
    this.address,
    this.profileImageUrl,
    this.lat,
    this.lng,
    this.isVerified = false,
    this.sellerStory,
    this.farmGalleryUrls = const [],
    this.sellerTags = const [],
    this.sellerQuickReplies = const [],
    this.createdAt,
    this.legalType,
    this.bpg,
    this.bpgMasked,
    this.pib,
    this.hasRegisteredEntity = false,
    this.legalLiabilityAcceptedAt,
  });

  factory SellerProfile.fromUserModel(UserModel user) {
    return SellerProfile(
      id: user.id,
      email: user.email,
      phone: user.phone,
      phonePublic: user.phonePublic,
      displayName: user.displayName,
      farmName: user.farmName,
      city: user.city,
      postalCode: user.postalCode,
      location: user.sellerLocation,
      address: user.address,
      profileImageUrl: user.profileImageUrl,
      lat: user.lat,
      lng: user.lng,
      isVerified: user.isVerified,
      sellerStory: user.sellerStory,
      farmGalleryUrls: user.farmGalleryUrls,
      sellerTags: user.sellerTags,
      sellerQuickReplies: user.sellerQuickReplies,
      createdAt: user.createdAt,
      legalType: user.legalType,
      bpg: user.bpg,
      bpgMasked: user.bpgMasked,
      pib: user.pib,
      hasRegisteredEntity: user.hasRegisteredEntity,
      legalLiabilityAcceptedAt: user.legalLiabilityAcceptedAt,
    );
  }

  factory SellerProfile.fromJson(Map<String, dynamic> json) {
    final bpg = json['bpg'] as String?;
    final bpgMasked = json['bpg_masked'] as String?;
    final pib = json['pib'] as String?;
    final hasRegisteredEntity = (json['has_registered_entity'] as bool?) ??
        ((bpg != null && bpg.length == 12) ||
            (bpgMasked != null && bpgMasked.isNotEmpty) ||
            (pib != null && pib.length == 9));

    return SellerProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      phonePublic: json['phone_public'] as bool? ?? false,
      displayName: json['display_name'] as String?,
      farmName: json['farm_name'] as String?,
      city: json['city'] as String?,
      postalCode: json['postal_code'] as String?,
      location: json['location'] as String?,
      address: json['address'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      isVerified: json['is_verified'] as bool? ?? false,
      sellerStory: json['seller_story'] as String?,
      farmGalleryUrls: (json['farm_gallery_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sellerTags: (json['seller_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sellerQuickReplies: (json['seller_quick_replies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      legalType: json['legal_type'] as String?,
      bpg: bpg,
      bpgMasked: bpgMasked,
      pib: pib,
      hasRegisteredEntity: hasRegisteredEntity,
      legalLiabilityAcceptedAt: json['legal_liability_accepted_at'] != null
          ? DateTime.tryParse(json['legal_liability_accepted_at'] as String)
          : null,
    );
  }

  UserModel toUserModel() {
    return UserModel(
      id: id,
      email: email,
      phone: phone,
      phonePublic: phonePublic,
      displayName: displayName,
      farmName: farmName,
      city: city,
      postalCode: postalCode,
      location: location,
      address: address ?? location,
      role: UserRole.seller,
      profileImageUrl: profileImageUrl,
      lat: lat,
      lng: lng,
      isVerified: isVerified,
      sellerStory: sellerStory,
      farmGalleryUrls: farmGalleryUrls,
      sellerTags: sellerTags,
      sellerQuickReplies: sellerQuickReplies,
      createdAt: createdAt,
      legalType: legalType,
      bpg: bpg,
      bpgMasked: bpgMasked,
      pib: pib,
      hasRegisteredEntity: hasRegisteredEntity,
      legalLiabilityAcceptedAt: legalLiabilityAcceptedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'phone_public': phonePublic,
      if (displayName != null) 'display_name': displayName,
      if (farmName != null) 'farm_name': farmName,
      if (city != null) 'city': city,
      if (postalCode != null) 'postal_code': postalCode,
      if (location != null) 'location': location,
      if (address != null) 'address': address,
      'role': 'seller',
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (sellerStory != null) 'seller_story': sellerStory,
      if (farmGalleryUrls.isNotEmpty) 'farm_gallery_urls': farmGalleryUrls,
      if (sellerTags.isNotEmpty) 'seller_tags': sellerTags,
      if (sellerQuickReplies.isNotEmpty)
        'seller_quick_replies': sellerQuickReplies,
      if (legalType != null) 'legal_type': legalType,
      if (bpg != null) 'bpg': bpg,
      if (pib != null) 'pib': pib,
      if (legalLiabilityAcceptedAt != null)
        'legal_liability_accepted_at':
            legalLiabilityAcceptedAt!.toIso8601String(),
    };
  }
}

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
  final String? legalType;
  final String? bpg;
  final String? bpgMasked;
  final String? pib;
  final bool hasRegisteredEntity;
  final DateTime? legalLiabilityAcceptedAt;

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
    this.legalType,
    this.bpg,
    this.bpgMasked,
    this.pib,
    this.hasRegisteredEntity = false,
    this.legalLiabilityAcceptedAt,
  });

  bool get isSeller => role == UserRole.seller;

  bool get isRegisteredProducer =>
      hasRegisteredEntity ||
      (bpg != null && bpg!.length == 12) ||
      (bpgMasked != null && bpgMasked!.isNotEmpty) ||
      (pib != null && pib!.length == 9);

  String? get registeredProducerBadgeLabel {
    if (!isRegisteredProducer) return null;
    if (legalType == 'company' || (pib != null && pib!.isNotEmpty)) {
      return 'Registrovani proizvođač (PIB)';
    }
    return 'Verifikovano gazdinstvo (BPG)';
  }

  /// Kanonski getter za adresu kupca (osigurava da se ne meša sa gazdinstvom).
  String? get buyerAddress => isSeller ? address : (address ?? location);

  /// Kanonski getter za lokaciju gazdinstva prodavca.
  String? get sellerLocation => isSeller ? (location ?? address) : null;

  BuyerProfile toBuyerProfile() => BuyerProfile.fromUserModel(this);
  SellerProfile toSellerProfile() => SellerProfile.fromUserModel(this);

  factory UserModel.fromBuyerProfile(BuyerProfile buyer) => buyer.toUserModel();
  factory UserModel.fromSellerProfile(SellerProfile seller) => seller.toUserModel();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final role = json['role'] == 'seller' ? UserRole.seller : UserRole.buyer;
    final rawLocation = json['location'] as String?;
    final rawAddress = json['address'] as String?;

    // Kanonsko razdvajanje:
    // Kupac: primarna adresa je `address` (uz fallback na `location` za legacy profile).
    // Prodavac: primarna lokacija gazdinstva je `location`.
    // Ako za prodavca `address` nije eksplicitno zadata, fallback je na `rawLocation`
    // radi kompatibilnosti sa prikazom na karticama.
    final String? location = rawLocation;
    final String? address = rawAddress ?? rawLocation;
    final bpg = json['bpg'] as String?;
    final bpgMasked = json['bpg_masked'] as String?;
    final pib = json['pib'] as String?;
    final hasRegisteredEntity = (json['has_registered_entity'] as bool?) ??
        ((bpg != null && bpg.length == 12) ||
            (bpgMasked != null && bpgMasked.isNotEmpty) ||
            (pib != null && pib.length == 9));

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
      legalType: json['legal_type'] as String?,
      bpg: bpg,
      bpgMasked: bpgMasked,
      pib: pib,
      hasRegisteredEntity: hasRegisteredEntity,
      legalLiabilityAcceptedAt: json['legal_liability_accepted_at'] != null
          ? DateTime.tryParse(json['legal_liability_accepted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final isSellerMode = role == UserRole.seller;
    return {
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (displayName != null) 'display_name': displayName,
      if (city != null) 'city': city,
      if (postalCode != null) 'postal_code': postalCode,
      // Kanonsko i ujednačeno mapiranje:
      // Kupac: adresa ide u kolonu `address`, a sinhronizuje se i u `location` radi legacy upita.
      // Prodavac: lokacija gazdinstva ide striktno u `location`, dok fizička adresa ide u `address`.
      if (address != null) 'address': address,
      if (isSellerMode && location != null) 'location': location,
      if (!isSellerMode && address != null) 'location': address,
      'phone_public': phonePublic,
      'role': isSellerMode ? 'seller' : 'buyer',
      'is_guest': isGuest,
      if (farmName != null) 'farm_name': farmName,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (sellerStory != null) 'seller_story': sellerStory,
      if (farmGalleryUrls.isNotEmpty) 'farm_gallery_urls': farmGalleryUrls,
      if (sellerTags.isNotEmpty) 'seller_tags': sellerTags,
      if (sellerQuickReplies.isNotEmpty)
        'seller_quick_replies': sellerQuickReplies,
      if (legalType != null) 'legal_type': legalType,
      if (bpg != null) 'bpg': bpg,
      if (pib != null) 'pib': pib,
      if (legalLiabilityAcceptedAt != null)
        'legal_liability_accepted_at':
            legalLiabilityAcceptedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toDbMap() => toJson();

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
    Object? legalType = _undefined,
    Object? bpg = _undefined,
    Object? bpgMasked = _undefined,
    Object? pib = _undefined,
    bool? hasRegisteredEntity,
    Object? legalLiabilityAcceptedAt = _undefined,
  }) {
    final nextRole = role ?? this.role;
    final nextAddress = identical(address, _undefined) ? this.address : address as String?;

    // Ako je kupac promenio adresu bez eksplicitnog navođenja `location`, sinhronizujemo `location`
    // kako kupčeva stara lokacija ne bi prebrisala novu adresu. Za prodavca ostaju potpuno odvojeni.
    final nextLocation = identical(location, _undefined)
        ? (nextRole == UserRole.buyer && !identical(address, _undefined)
            ? nextAddress
            : this.location)
        : location as String?;

    final nextBpg = identical(bpg, _undefined) ? this.bpg : bpg as String?;
    final nextBpgMasked = identical(bpgMasked, _undefined)
        ? this.bpgMasked
        : bpgMasked as String?;
    final nextPib = identical(pib, _undefined) ? this.pib : pib as String?;

    return UserModel(
      id: id ?? this.id,
      email: identical(email, _undefined) ? this.email : email as String?,
      phone: identical(phone, _undefined) ? this.phone : phone as String?,
      displayName: identical(displayName, _undefined) ? this.displayName : displayName as String?,
      city: identical(city, _undefined) ? this.city : city as String?,
      address: nextAddress,
      postalCode: identical(postalCode, _undefined) ? this.postalCode : postalCode as String?,
      role: nextRole,
      isGuest: isGuest ?? this.isGuest,
      farmName: identical(farmName, _undefined) ? this.farmName : farmName as String?,
      location: nextLocation,
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
      legalType: identical(legalType, _undefined) ? this.legalType : legalType as String?,
      bpg: nextBpg,
      bpgMasked: nextBpgMasked,
      pib: nextPib,
      hasRegisteredEntity: hasRegisteredEntity ??
          ((nextBpg != null && nextBpg.length == 12) ||
              (nextBpgMasked != null && nextBpgMasked.isNotEmpty) ||
              (nextPib != null && nextPib.length == 9)),
      legalLiabilityAcceptedAt: identical(legalLiabilityAcceptedAt, _undefined)
          ? this.legalLiabilityAcceptedAt
          : legalLiabilityAcceptedAt as DateTime?,
    );
  }
}

