import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_model.dart';
import '../../models/app_error.dart';

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
    String? displayName,
    String? phone,
    String? city,
    String? postalCode,
    String? role,
    bool? isGuest,
    String? farmName,
    String? location,
    String? profileImageUrl,
    double? lat,
    double? lng,
    bool? phonePublic,
  }) async {
    try {
      final data = <String, dynamic>{
        'id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (email != null) data['email'] = email;
      if (displayName != null) data['display_name'] = displayName;
      if (phone != null) data['phone'] = phone;
      if (city != null) data['city'] = city;
      if (postalCode != null) data['postal_code'] = postalCode;
      if (role != null) data['role'] = role;
      if (isGuest != null) data['is_guest'] = isGuest;
      if (farmName != null) data['farm_name'] = farmName;
      if (location != null) data['location'] = location;
      if (profileImageUrl != null) data['profile_image_url'] = profileImageUrl;
      if (lat != null) data['lat'] = lat;
      if (lng != null) data['lng'] = lng;
      if (phonePublic != null) data['phone_public'] = phonePublic;
      await _client.from('profiles').upsert(data);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
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

  Future<void> updateProfileImage(String userId, String imageUrl) async {
    try {
      await _client.from('profiles').update({
        'profile_image_url': imageUrl,
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
