import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_error.dart';
import '../../models/classified_subscription_model.dart';

class ClassifiedSubscriptionsService {
  final SupabaseClient? _customClient;

  ClassifiedSubscriptionsService([SupabaseClient? client])
      : _customClient = client;

  /// Konstruktor za testiranje
  ClassifiedSubscriptionsService.test([this._customClient]);

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  /// Preuzima sva aktivna praćenja kategorija i pretraga za trenutnog korisnika
  Future<List<ClassifiedSubscriptionModel>> getSubscriptions() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final res = await _client
          .from('classified_category_subscriptions')
          .select('''
            id,
            user_id,
            category_id,
            search_query,
            max_price,
            currency,
            created_at,
            classified_categories:category_id(name, icon_name)
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (res as List)
          .map((e) =>
              ClassifiedSubscriptionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Kreira novu pretplatu na kategoriju / sačuvanu pretragu
  Future<ClassifiedSubscriptionModel> subscribe({
    required String categoryId,
    String? searchQuery,
    double? maxPrice,
    String currency = 'EUR',
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw AppError(message: 'Morate biti prijavljeni da biste pratili kategoriju.');
      }

      final data = {
        'user_id': user.id,
        'category_id': categoryId,
        if (searchQuery != null && searchQuery.trim().isNotEmpty)
          'search_query': searchQuery.trim(),
        if (maxPrice != null && maxPrice > 0) 'max_price': maxPrice,
        'currency': currency,
      };

      final res = await _client
          .from('classified_category_subscriptions')
          .insert(data)
          .select('''
            id,
            user_id,
            category_id,
            search_query,
            max_price,
            currency,
            created_at,
            classified_categories:category_id(name, icon_name)
          ''')
          .single();

      return ClassifiedSubscriptionModel.fromJson(res);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Briše pretplatu po ID-ju
  Future<void> unsubscribe(String subscriptionId) async {
    try {
      await _client
          .from('classified_category_subscriptions')
          .delete()
          .eq('id', subscriptionId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Uklanja praćenje date kategorije za trenutnog korisnika
  Future<void> unsubscribeByCategory(String categoryId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client
          .from('classified_category_subscriptions')
          .delete()
          .eq('user_id', user.id)
          .eq('category_id', categoryId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }
}
