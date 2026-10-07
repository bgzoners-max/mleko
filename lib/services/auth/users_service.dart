import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_model.dart';
import '../../models/app_error.dart';

const Object _undefined = Object();

class UsersService {
  static final UsersService _instance = UsersService._();
  factory UsersService({SupabaseClient? client}) {
    if (client != null) return UsersService._(client: client);
    return _instance;
  }
  UsersService._({SupabaseClient? client}) : _customClient = client;

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  Future<List<UserModel>> getRecentlyRegisteredSellers({
    int limit = 3,
  }) async {
    try {
      final list = await _client
          .from('public_profiles')
          .select()
          .eq('role', 'seller')
          .order('created_at', ascending: false)
          .limit(limit);

      return (list as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final res = await _client
          .from('public_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (res == null) return null;
      return UserModel.fromJson(res);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<List<UserModel>> getUsers(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final list = await _client
          .from('public_profiles')
          .select()
          .inFilter('id', ids);
      return (list as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> upsertProfile(
    String userId, {
    String? email,
    Object? displayName = _undefined,
    Object? phone = _undefined,
    Object? city = _undefined,
    Object? postalCode = _undefined,
    Object? address = _undefined,
    String? role,
    bool? isGuest,
    Object? farmName = _undefined,
    Object? location = _undefined,
    Object? profileImageUrl = _undefined,
    double? lat,
    double? lng,
    bool? phonePublic,
    Object? sellerStory = _undefined,
    List<String>? farmGalleryUrls,
    List<String>? sellerTags,
    List<String>? sellerQuickReplies,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (email != null) updateData['email'] = email;
      if (!identical(displayName, _undefined)) updateData['display_name'] = displayName;
      if (!identical(phone, _undefined)) updateData['phone'] = phone;
      if (!identical(city, _undefined)) updateData['city'] = city;
      if (!identical(postalCode, _undefined)) updateData['postal_code'] = postalCode;
      if (!identical(address, _undefined)) updateData['address'] = address;
      if (role != null) updateData['role'] = role;
      if (isGuest != null) updateData['is_guest'] = isGuest;
      if (!identical(farmName, _undefined)) updateData['farm_name'] = farmName;
      if (!identical(location, _undefined)) updateData['location'] = location;
      if (!identical(profileImageUrl, _undefined)) {
        updateData['profile_image_url'] = profileImageUrl;
      }
      if (lat != null) updateData['lat'] = lat;
      if (lng != null) updateData['lng'] = lng;
      if (phonePublic != null) updateData['phone_public'] = phonePublic;
      if (!identical(sellerStory, _undefined)) updateData['seller_story'] = sellerStory;
      if (farmGalleryUrls != null) updateData['farm_gallery_urls'] = farmGalleryUrls;
      if (sellerTags != null) updateData['seller_tags'] = sellerTags;
      if (sellerQuickReplies != null) {
        updateData['seller_quick_replies'] = sellerQuickReplies;
      }

      final updated = await _client
          .from('profiles')
          .update(updateData)
          .eq('id', userId)
          .select('id')
          .maybeSingle();

      if (updated == null) {
        final insertData = Map<String, dynamic>.from(updateData);
        insertData['id'] = userId;
        insertData['email'] ??= _client.auth.currentUser?.email;
        insertData['role'] ??= 'buyer';
        insertData['is_guest'] ??= false;
        await _client.from('profiles').insert(insertData);
      }
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Ažurira celokupan profil bez gubljenja polja.
  /// Ako je prosleđen [previous], šalju se samo izmenjena polja (Diff).
  Future<void> updateProfile(UserModel user, {UserModel? previous}) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (previous != null) {
        if (user.displayName != previous.displayName) updateData['display_name'] = user.displayName;
        if (user.phone != previous.phone) updateData['phone'] = user.phone;
        if (user.city != previous.city) updateData['city'] = user.city;
        if (user.postalCode != previous.postalCode) updateData['postal_code'] = user.postalCode;
        if (user.address != previous.address) updateData['address'] = user.address;
        if (user.role != previous.role) {
          updateData['role'] = user.role == UserRole.seller ? 'seller' : 'buyer';
        }
        if (user.farmName != previous.farmName) updateData['farm_name'] = user.farmName;
        if (user.location != previous.location) updateData['location'] = user.location;
        if (user.profileImageUrl != previous.profileImageUrl) {
          updateData['profile_image_url'] = user.profileImageUrl;
        }
        if (user.lat != previous.lat) updateData['lat'] = user.lat;
        if (user.lng != previous.lng) updateData['lng'] = user.lng;
        if (user.phonePublic != previous.phonePublic) {
          updateData['phone_public'] = user.phonePublic;
        }
        if (user.sellerStory != previous.sellerStory) {
          updateData['seller_story'] = user.sellerStory;
        }
        if (!_listEquals(user.farmGalleryUrls, previous.farmGalleryUrls)) {
          updateData['farm_gallery_urls'] = user.farmGalleryUrls;
        }
        if (!_listEquals(user.sellerTags, previous.sellerTags)) {
          updateData['seller_tags'] = user.sellerTags;
        }
        if (!_listEquals(user.sellerQuickReplies, previous.sellerQuickReplies)) {
          updateData['seller_quick_replies'] = user.sellerQuickReplies;
        }
      } else {
        updateData.addAll(user.toDbMap());
        updateData.remove('id');
        updateData.remove('created_at');
        updateData.remove('is_admin');
        updateData.remove('is_verified');
      }

      if (updateData.length > 1) {
        final updated = await _client
            .from('profiles')
            .update(updateData)
            .eq('id', user.id)
            .select('id')
            .maybeSingle();

        if (updated == null) {
          final insertData = Map<String, dynamic>.from(user.toDbMap());
          insertData['id'] = user.id;
          insertData['email'] ??= _client.auth.currentUser?.email;
          insertData['role'] ??= user.role == UserRole.seller ? 'seller' : 'buyer';
          insertData['is_guest'] ??= user.isGuest;
          insertData.remove('is_admin');
          insertData.remove('is_verified');
          await _client.from('profiles').insert(insertData);
        }
      }
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> updateBuyerProfile(BuyerProfile profile) async {
    await updateProfile(profile.toUserModel());
  }

  Future<void> updateSellerProfile(SellerProfile profile) async {
    await updateProfile(profile.toUserModel());
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> updateSellerLocation(
      String userId, double lat, double lng) async {
    try {
      await _client.from('profiles').update({
        'lat': lat,
        'lng': lng,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> clearSellerLocation(String userId) async {
    try {
      await _client.from('profiles').update({
        'lat': null,
        'lng': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> updateProfileImage(String userId, String? imageUrl) async {
    try {
      await _client.from('profiles').update({
        'profile_image_url': (imageUrl == null || imageUrl.trim().isEmpty) ? null : imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> updateSellerStory(String userId, String story) async {
    try {
      await _client.from('profiles').update({
        'seller_story': story,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> updateFarmGallery(String userId, List<String> urls) async {
    try {
      await _client.from('profiles').update({
        'farm_gallery_urls': urls,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> updateSellerTags(String userId, List<String> tags) async {
    try {
      await _client.from('profiles').update({
        'seller_tags': tags,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> updateSellerQuickReplies(
      String userId, List<String> replies) async {
    try {
      final cleaned =
          replies.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      await _client.from('profiles').update({
        'seller_quick_replies': cleaned,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> updatePhone(String userId, String phone) async {
    try {
      await _client.from('profiles').update({
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }
}
