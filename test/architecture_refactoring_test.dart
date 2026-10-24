import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/conversation_model.dart';
import 'package:mleko/models/message_model.dart';
import 'package:mleko/models/order_item_model.dart';
import 'package:mleko/models/order_model.dart';
import 'package:mleko/models/order_status_audit_log_model.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/models/seller_delivery_models.dart';
import 'package:mleko/repositories/repositories.dart';
import 'package:mleko/services/communication/chat_service.dart';
import 'package:mleko/services/communication/push_service.dart';
import 'package:mleko/services/communication/push_token_repository.dart';
import 'package:mleko/services/orders/orders_service.dart';

class _FakeOrdersRepository implements OrdersRepository {
  int fetchOrdersByBuyerCalled = 0;
  int createOrderCalled = 0;

  @override
  Future<List<OrderModel>> fetchOrdersByBuyer(
    String buyerId, {
    String? statusFilter,
    int limit = 20,
    int offset = 0,
  }) async {
    fetchOrdersByBuyerCalled++;
    return [];
  }

  @override
  Future<List<OrderModel>> fetchOrdersBySeller(
    String sellerId, {
    String? statusFilter,
    int limit = 20,
    int offset = 0,
  }) async =>
      [];

  @override
  Future<List<OrderModel>> fetchMoreOrdersByBuyer(
    String buyerId, {
    required int offset,
    String? statusFilter,
  }) async =>
      [];

  @override
  Future<List<OrderModel>> fetchMoreOrdersBySeller(
    String sellerId, {
    required int offset,
    String? statusFilter,
  }) async =>
      [];

  @override
  Future<OrderModel?> getOrderById(String orderId) async => null;

  @override
  Future<List<OrderItemModel>> getOrderItems(String orderId) async => [];

  @override
  Future<List<OrderStatusAuditLogModel>> getOrderStatusAuditLogs(
    String orderId,
  ) async =>
      [];

  @override
  Future<SellerStats> getSellerStats(String sellerId) async =>
      SellerStats(pendingCount: 0, totalCount: 0, revenue: 0);

  @override
  Future<BuyerStats> getBuyerStats(String buyerId) async =>
      BuyerStats(pendingCount: 0, totalSuccessCount: 0, totalSpent: 0);

  @override
  Future<List<BuyerSellerStats>> getOrdersByBuyerForSellerStats(
    String buyerId,
  ) async =>
      [];

  @override
  Stream<List<OrderModel>> getOrdersBySeller(
    String sellerId, {
    String? statusFilter,
    Stream<void>? refreshTrigger,
  }) =>
      const Stream.empty();

  @override
  Stream<List<OrderModel>> getOrdersByBuyer(
    String buyerId, {
    String? statusFilter,
    Stream<void>? refreshTrigger,
  }) =>
      const Stream.empty();

  @override
  Future<String> createSingleProductOrder({
    required String buyerId,
    required String sellerId,
    required String productId,
    required String productName,
    required double quantityKg,
    required String unitType,
    required String note,
    required String buyerCity,
    required String buyerPhone,
    String? buyerAddress,
    String? buyerPostalCode,
    DeliveryMethod deliveryMethod = DeliveryMethod.agreement,
    DeliverySelectionModel? deliverySelection,
  }) async {
    createOrderCalled++;
    return 'fake-order-id';
  }

  @override
  Future<String> createOrderWithItems({
    required String buyerId,
    required String sellerId,
    required List<OrderItemModel> items,
    required String note,
    required String buyerCity,
    required String buyerPhone,
    String? buyerAddress,
    String? buyerPostalCode,
    DeliveryMethod deliveryMethod = DeliveryMethod.agreement,
    DeliverySelectionModel? deliverySelection,
  }) async {
    createOrderCalled++;
    return 'fake-order-id';
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {}

  @override
  Future<void> cancelOrderBySeller(String orderId, String reason) async {}

  @override
  Future<void> archiveOrderByBuyer(String buyerId, String orderId) async {}

  @override
  Future<void> archiveOrderBySeller(String sellerId, String orderId) async {}

  @override
  Future<void> archiveOrder(String orderId) async {}

  @override
  Future<void> confirmOrderReceivedByBuyer(String orderId) async {}
}

class _FakeChatRepository implements ChatRepository {
  int sendMessageCount = 0;

  @override
  Future<String?> findConversationId(
    String buyerId,
    String sellerId, {
    String? productId,
    String? adId,
    String? orderId,
  }) async =>
      'conv-123';

  @override
  Future<String> getOrCreateConversation(
    String buyerId,
    String sellerId, {
    String? productId,
    String? adId,
    String? orderId,
    bool updateOrderIdIfPresent = true,
  }) async =>
      'conv-123';

  @override
  Future<List<ConversationModel>> getConversations(String userId) async => [];

  @override
  Stream<List<ConversationModel>> watchConversations(
    String userId, {
    Stream<void>? refreshTrigger,
  }) =>
      const Stream.empty();

  @override
  Future<void> setConversationUserPrefs(
    String conversationId, {
    bool? isFavorite,
    bool? hidden,
  }) async {}

  @override
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
  }) async =>
      [];

  @override
  Future<List<MessageModel>> fetchOlderMessages(
    String conversationId, {
    required DateTime before,
    int limit = 50,
  }) async =>
      [];

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
    String? imageUrl,
  }) async {
    sendMessageCount++;
  }


  @override
  Future<void> markAsRead(String conversationId, String currentUserId) async {}
}

void main() {
  group('3.1 Dependency Injection & visibleForTesting constructors', () {
    test('OrdersService.forTesting injects mock repository without SupabaseClient', () async {
      final fakeRepo = _FakeOrdersRepository();
      final service = OrdersService.forTesting(repository: fakeRepo);

      await service.fetchOrdersByBuyer('user-1');
      expect(fakeRepo.fetchOrdersByBuyerCalled, equals(1));

      await service.createSingleProductOrder(
        buyerId: 'b-1',
        sellerId: 's-1',
        productId: 'p-1',
        productName: 'Mleko',
        quantityKg: 2,
        unitType: 'L',
        note: 'Hvala',
        buyerCity: 'Beograd',
        buyerPhone: '0612345678',
      );
      expect(fakeRepo.createOrderCalled, equals(1));
    });

    test('ChatService.forTesting injects mock repository cleanly', () async {
      final fakeChatRepo = _FakeChatRepository();
      final service = ChatService.forTesting(repository: fakeChatRepo);

      final convId = await service.getOrCreateConversation('b-1', 's-1');
      expect(convId, equals('conv-123'));

      await service.sendMessage('conv-123', 'sender-1', 'Pozdrav');
      expect(fakeChatRepo.sendMessageCount, equals(1));
    });
  });

  group('3.2 Composition over Mixins', () {
    test('ChatService delegates to composed handlers', () {
      final fakeChatRepo = _FakeChatRepository();
      final service = ChatService.forTesting(repository: fakeChatRepo);

      expect(service.reactions, isA<ChatReactionsHandler>());
      expect(service.typing, isA<ChatTypingHandler>());
      expect(service.media, isA<ChatMediaHandler>());
      expect(service.stats, isA<ChatStatsHandler>());
      expect(service.repository, isA<ChatRepository>());
    });

    test('OrdersService delegates to composed OrdersRepository', () {
      final fakeRepo = _FakeOrdersRepository();
      final service = OrdersService.forTesting(repository: fakeRepo);

      expect(service.repository, equals(fakeRepo));
    });
  });

  group('3.3 Repository Interfaces', () {
    test('PushTokenRepository is an abstract interface with Supabase implementation', () {
      final repo = PushTokenRepository();
      expect(repo, isA<PushTokenRepository>());
      expect(repo, isA<SupabasePushTokenRepository>());
    });

    test('ProductsRepository is an abstract interface with Supabase implementation', () {
      final repo = SupabaseProductsRepository();
      expect(repo, isA<ProductsRepository>());
    });

    test('OrdersRepository is an abstract interface with Supabase implementation', () {
      final repo = SupabaseOrdersRepository();
      expect(repo, isA<OrdersRepository>());
    });

    test('ChatRepository is an abstract interface with Supabase implementation', () {
      final repo = SupabaseChatRepository();
      expect(repo, isA<ChatRepository>());
    });
  });

  group('3.4 ProductModel modularization (ProductStats, ProductDeliveryScope, ProductFormattingUtils)', () {
    test('ProductModel exposes modular deliveryScope and stats value objects', () {
      final product = ProductModel(
        id: 'p-1',
        sellerId: 's-1',
        category: 'Mlečni proizvodi',
        name: 'Domaći sir',
        pricePerKg: 1200,
        minOrderKg: 0.5,
        availableKg: 10,
        description: 'Vrhunski sir',
        imageUrls: const ['https://img.test/sir.jpg'],
        pickupOptions: const ['Lično preuzimanje'],
        location: 'Valjevo',
        createdAt: DateTime(2026, 1, 1),
        deliveryMode: ProductDeliveryMode.allSellerPoints,
        selectedDeliveryPointIds: const ['loc-1', 'loc-2'],
        sellerIsVerified: true,
        avgRating: 4.9,
        reviewCount: 42,
        orderCount: 128,
      );

      expect(product.deliveryScope.mode, equals(ProductDeliveryMode.allSellerPoints));
      expect(product.deliveryScope.selectedPointIds, equals(['loc-1', 'loc-2']));
      expect(product.deliveryScope.supportsSellerDelivery, isTrue);

      expect(product.stats.sellerIsVerified, isTrue);
      expect(product.stats.avgRating, equals(4.9));
      expect(product.stats.reviewCount, equals(42));
      expect(product.stats.orderCount, equals(128));

      // Test copyWith using modular subcomponents
      final updated = product.copyWith(
        stats: const ProductStats(
          sellerIsVerified: true,
          avgRating: 5.0,
          reviewCount: 43,
          orderCount: 129,
        ),
      );
      expect(updated.avgRating, equals(5.0));
      expect(updated.reviewCount, equals(43));
    });

    test('ProductFormattingUtils correctly handles Slavic plurals and formatting', () {
      expect(ProductFormattingUtils.pluralSr(1, one: 'veza', few: 'veze', many: 'veza'), equals('veza'));
      expect(ProductFormattingUtils.pluralSr(2, one: 'veza', few: 'veze', many: 'veza'), equals('veze'));
      expect(ProductFormattingUtils.pluralSr(5, one: 'veza', few: 'veze', many: 'veza'), equals('veza'));
      expect(ProductFormattingUtils.pluralSr(21, one: 'veza', few: 'veze', many: 'veza'), equals('veza'));
      expect(ProductFormattingUtils.pluralSr(24, one: 'veza', few: 'veze', many: 'veza'), equals('veze'));

      expect(ProductFormattingUtils.formatDecimal(1.5), equals('1,5'));
      expect(ProductFormattingUtils.formatDecimal(2.0), equals('2'));

      expect(ProductFormattingUtils.parseQuantityKg('500g'), equals(0.5));
      expect(ProductFormattingUtils.parseQuantityKg('1.5 kg'), equals(1.5));
      expect(ProductFormattingUtils.parseQuantityL('750 ml'), equals(0.75));
    });
  });
}
