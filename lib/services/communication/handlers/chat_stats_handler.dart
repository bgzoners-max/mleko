import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/app_error.dart';
import '../../../models/message_reaction_model.dart';

/// Handler za chat statistiku i vreme odgovora prodavca.
class ChatStatsHandler {
  final SupabaseClient? _customClient;

  ChatStatsHandler({SupabaseClient? client}) : _customClient = client;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  Future<SellerResponseStats> getSellerResponseStats(String sellerId) async {
    try {
      final result = await _client.rpc(
        'get_seller_response_time_stats',
        params: {'p_seller_id': sellerId},
      );

      if (result == null) {
        return const SellerResponseStats(
          sampleCount: 0,
          avgResponseMinutes: null,
          medianResponseMinutes: null,
          lastResponseMinutes: null,
        );
      }

      Map<String, dynamic>? json;
      if (result is List && result.isNotEmpty) {
        final first = result.first;
        if (first is Map<String, dynamic>) {
          json = first;
        } else if (first is Map) {
          json = Map<String, dynamic>.from(first);
        }
      } else if (result is Map<String, dynamic>) {
        json = result;
      } else if (result is Map) {
        json = Map<String, dynamic>.from(result);
      }

      if (json == null) {
        return const SellerResponseStats(
          sampleCount: 0,
          avgResponseMinutes: null,
          medianResponseMinutes: null,
          lastResponseMinutes: null,
        );
      }
      return SellerResponseStats.fromJson(json);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }
}
