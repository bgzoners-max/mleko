import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

class UsersService {
  final _client = Supabase.instance.client;

  Future<UserModel?> getUser(String userId) async {
    final res = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    if (res == null) return null;
    return UserModel.fromJson(res);
  }

  Future<void> upsertProfile(
    String userId, {
    String? email,
    String? displayName,
    String? phone,
    String? city,
    String? address,
    String? role,
    bool? isGuest,
    String? farmName,
    String? location,
    String? profileImageUrl,
    double? lat,
    double? lng,
  }) async {
    final data = <String, dynamic>{
      'id': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (email != null) data['email'] = email;
    if (displayName != null) data['display_name'] = displayName;
    if (phone != null) data['phone'] = phone;
    if (city != null) data['city'] = city;
    if (address != null) data['address'] = address;
    if (role != null) data['role'] = role;
    if (isGuest != null) data['is_guest'] = isGuest;
    if (farmName != null) data['farm_name'] = farmName;
    if (location != null) data['location'] = location;
    if (profileImageUrl != null) data['profile_image_url'] = profileImageUrl;
    if (lat != null) data['lat'] = lat;
    if (lng != null) data['lng'] = lng;
    await _client.from('profiles').upsert(data);
  }

  Future<void> updateSellerLocation(String userId, double lat, double lng) async {
    await _client.from('profiles').update({
      'lat': lat,
      'lng': lng,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> clearSellerLocation(String userId) async {
    await _client.from('profiles').update({
      'lat': null,
      'lng': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> updateProfileImage(String userId, String imageUrl) async {
    await _client.from('profiles').update({
      'profile_image_url': imageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> updateSellerStory(String userId, String story) async {
    await _client.from('profiles').update({
      'seller_story': story,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> updateFarmGallery(String userId, List<String> urls) async {
    await _client.from('profiles').update({
      'farm_gallery_urls': urls,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> updateSellerTags(String userId, List<String> tags) async {
    await _client.from('profiles').update({
      'seller_tags': tags,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> updateSellerQuickReplies(String userId, List<String> replies) async {
    final cleaned = replies.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    await _client.from('profiles').update({
      'seller_quick_replies': cleaned,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> updatePhone(String userId, String phone) async {
    await _client.from('profiles').update({
      'phone': phone,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }
}
