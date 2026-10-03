import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/home/seller_inbox_item.dart';
import '../core/logger_service.dart';

/// Jedinstveni inbox za prodavca – porudžbine + razgovori, sortirano po datumu
class SellerInboxService {
  final _client = Supabase.instance.client;

  Future<List<SellerInboxItem>> getInboxItems(String sellerId,
      {int limit = 50, int offset = 0}) async {
    final result = await _client.rpc('get_seller_inbox', params: {
      'p_seller_id': sellerId,
      'p_limit': limit,
      'p_offset': offset,
    });
    final list = result as List? ?? [];
    return list.map((e) => _parseInboxItem(e as Map<String, dynamic>)).toList();
  }

  SellerInboxItem _parseInboxItem(Map<String, dynamic> row) {
    final typeStr = row['type'] as String? ?? 'order';
    final type = typeStr == 'conversation'
        ? SellerInboxItemType.conversation
        : SellerInboxItemType.order;
    final sortDate = _parseDate(row['sort_date']);
    return SellerInboxItem(
      type: type,
      sortDate: sortDate,
      orderId: row['order_id'] as String?,
      conversationId: row['conversation_id'] as String?,
      buyerId: row['buyer_id'] as String?,
      productId: row['product_id'] as String?,
      adId: row['ad_id'] as String?,
      otherPartyName: row['other_party_name'] as String?,
      otherPartyImageUrl: row['other_party_image_url'] as String?,
      productName: row['product_name'] as String?,
      quantityKg: (row['quantity_kg'] as num?)?.toDouble(),
      unitType: row['unit_type'] as String?,
      lastMessageBody: row['last_message_body'] as String?,
      unreadCount: row['unread_count'] as int? ?? 0,
      statusLabel: row['status_label'] as String?,
      buyerPhone: row['buyer_phone'] as String?,
      note: row['note'] as String?,
      buyerCity: row['buyer_city'] as String?,
      buyerAddress: row['buyer_address'] as String?,
    );
  }

  Stream<List<SellerInboxItem>> watchInbox(String sellerId,
      {int limit = 50, int offset = 0, Stream<void>? refreshTrigger}) {
    final controller = StreamController<List<SellerInboxItem>>.broadcast();
    StreamSubscription? refreshSub;

    Future<void> refetch() async {
      try {
        final list = await getInboxItems(sellerId, limit: limit, offset: offset);
        if (!controller.isClosed) controller.add(list);
      } catch (e, st) {
        LoggerService.error('Failed to refresh seller inbox', e,
            stackTrace: st);
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    refetch();

    final channel = _client.channel('seller-inbox-$sellerId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'seller_id',
              value: sellerId),
          callback: (_) => refetch(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'seller_id',
              value: sellerId),
          callback: (_) => refetch(),
        )
        .subscribe();

    refreshSub = refreshTrigger?.listen((_) => refetch());

    controller.onCancel = () {
      refreshSub?.cancel();
      _client.removeChannel(channel);
      if (!controller.isClosed) {
        controller.close();
      }
    };

    return controller.stream;
  }

  DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return v as DateTime;
  }
}
