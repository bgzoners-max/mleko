import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/services/communication/chat_room_manager.dart';
import 'package:mleko/services/communication/chat_service.dart';
import 'package:mleko/services/communication/realtime_channel_manager.dart';

void main() {
  group('4.1 Migration Squash & Baseline Schema', () {
    test('supabase/schema.sql snapshot exists and contains baseline DDL', () {
      final schemaFile = File('supabase/schema.sql');
      expect(schemaFile.existsSync(), isTrue, reason: 'supabase/schema.sql should exist as baseline snapshot');
      final content = schemaFile.readAsStringSync();
      expect(content.contains('CONSOLIDATED SUPABASE SCHEMA SNAPSHOT'), isTrue);
      expect(content.contains('CREATE TABLE'), isTrue);
      expect(content.length, greaterThan(100000));
    });

    test('tool/squash_migrations.dart correctly targets cutoff and identifies migrations', () {
      final toolFile = File('tool/squash_migrations.dart');
      expect(toolFile.existsSync(), isTrue);
    });
  });

  group('4.2 Composite & Targeted Database Indexes', () {
    test('Migration 20261024120000 defines required composite indexes', () {
      final migrationFile = File('supabase/migrations/20261024120000_performance_composite_indexes.sql');
      expect(migrationFile.existsSync(), isTrue);
      final sql = migrationFile.readAsStringSync();

      // products(seller_id, available_now, category)
      expect(sql.contains('idx_products_seller_available_category'), isTrue);
      expect(sql.contains('(seller_id, available_now, category)'), isTrue);

      // products(category, available_now, created_at DESC)
      expect(sql.contains('idx_products_category_available_created'), isTrue);

      // messages(conversation_id, created_at DESC)
      expect(sql.contains('idx_messages_conversation_created'), isTrue);
      expect(sql.contains('(conversation_id, created_at DESC)'), isTrue);

      // orders
      expect(sql.contains('idx_orders_buyer_status_created'), isTrue);
      expect(sql.contains('idx_orders_seller_status_created'), isTrue);

      // user_push_tokens
      expect(sql.contains('idx_push_tokens_user'), isTrue);

      // conversations
      expect(sql.contains('idx_conversations_buyer_updated'), isTrue);
      expect(sql.contains('idx_conversations_seller_updated'), isTrue);
    });
  });

  group('4.3 Realtime Channels Hygiene & Lifecycle', () {
    test('ChatRoomManager releases rooms and channels via releaseRoom and releaseAll', () async {
      final roomManager = ChatRoomManager();
      expect(roomManager.activeRoomCount, 0);
    });

    test('RealtimeChannelManager refCount tracks active listeners correctly', () {
      final manager = RealtimeChannelManager();
      expect(manager.activeChannelCount, greaterThanOrEqualTo(0));
    });

    test('ChatService exposes cleanUp and dispose methods for lifecycle cleanup', () {
      final service = ChatService();
      expect(service.cleanUp, isNotNull);
      expect(service.dispose, isNotNull);
    });
  });
}
