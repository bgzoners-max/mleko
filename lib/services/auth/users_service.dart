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
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (email != null) updateData['email'] = email;
      if (displayName != null) updateData['display_name'] = displayName;
      if (phone != null) updateData['phone'] = phone;
      if (city != null) updateData['city'] = city;
      if (postalCode != null) updateData['postal_code'] = postalCode;
      if (role != null) updateData['role'] = role;
      if (isGuest != null) updateData['is_guest'] = isGuest;
      if (farmName != null) updateData['farm_name'] = farmName;
      if (location != null) updateData['location'] = location;
      if (profileImageUrl != null) {
        updateData['profile_image_url'] = profileImageUrl;
      }
      if (lat != null) updateData['lat'] = lat;
      if (lng != null) updateData['lng'] = lng;
      if (phonePublic != null) updateData['phone_public'] = phonePublic;

      final updated = await _client
          .from('profiles')
          .update(updateData)
          .eq('id', userId)
          .select('id')
          .maybeSingle();

      if (updated == null) {
        final insertData = Map<String, dynamic>.from(updateData);
        insertData['id'] = userId;
        await _client.from('profiles').insert(insertData);
      }
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
