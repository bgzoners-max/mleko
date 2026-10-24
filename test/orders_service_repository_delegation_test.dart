import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/order_item_model.dart';
import 'package:mleko/models/order_model.dart';
import 'package:mleko/models/order_status_audit_log_model.dart';
import 'package:mleko/models/seller_delivery_models.dart';
import 'package:mleko/services/orders/order_services.dart';

/// Unit testovi za Repository delegaciju u [OrdersService] (refaktor tačke 4 —
/// composition over inheritance). Mock repozitorijum snima sve pozive, pa se
/// proverava da servis prosleđuje argumente vernulo i vraća rezultat nepromenjen.
void main() {
  test('fetchOrdersByBuyer delegira argumente i vraća rezultat', () async {
    final repo = _RecordingOrdersRepository();
    final service = OrdersService.forTesting(repository: repo);

    final result = await service.fetchOrdersByBuyer(
      'buyer-1',
      statusFilter: OrdersService.statusFilterActiveNonArchived,
      limit: 5,
      offset: 3,
    );

    expect(result, hasLength(1));
    expect(result.first.id, 'order-1');
    expect(repo.calls['fetchOrdersByBuyer'], {
      'buyerId': 'buyer-1',
      'statusFilter': 'active',
      'limit': 5,
      'offset': 3,
    });
  });

  test('fetchOrdersBySeller delegira argumente i vraća rezultat', () async {
    final repo = _RecordingOrdersRepository();
    final service = OrdersService.forTesting(repository: repo);

    final result = await service.fetchOrdersBySeller(
      'seller-1',
      statusFilter: 'sent',
      limit: 10,
      offset: 20,
    );

    expect(result, hasLength(1));
    expect(repo.calls['fetchOrdersBySeller'], {
      'sellerId': 'seller-1',
      'statusFilter': 'sent',
      'limit': 10,
      'offset': 20,
    });
  });

  test('pojedinačne dohvate (getOrderById/getOrderItems/audit logs) delegira',
      () async {
    final repo = _RecordingOrdersRepository();
    final service = OrdersService.forTesting(repository: repo);

    final order = await service.getOrderById('order-1');
    final items = await service.getOrderItems('order-1');
    final logs = await service.getOrderStatusAuditLogs('order-1');

    expect(order?.id, 'order-1');
    expect(items, hasLength(1));
    expect(items.first.productName, 'Med');
    expect(logs, hasLength(1));
    expect(repo.calls['getOrderById'], {'orderId': 'order-1'});
    expect(repo.calls['getOrderItems'], {'orderId': 'order-1'});
    expect(repo.calls['getOrderStatusAuditLogs'], {'orderId': 'order-1'});
  });

  test('statistike (seller/buyer/po prodavcu) delegira i vraća vrednosti',
      () async {
    final repo = _RecordingOrdersRepository();
    final service = OrdersService.forTesting(repository: repo);

    final sellerStats = await service.getSellerStats('seller-1');
    final buyerStats = await service.getBuyerStats('buyer-1');
    final perSeller = await service.getOrdersByBuyerForSellerStats('buyer-1');

    expect(sellerStats.totalCount, 10);
    expect(buyerStats.totalSpent, 9000);
    expect(perSeller, hasLength(1));
    expect(repo.calls['getSellerStats'], {'sellerId': 'seller-1'});
    expect(repo.calls['getBuyerStats'], {'buyerId': 'buyer-1'});
    expect(
        repo.calls['getOrdersByBuyerForSellerStats'], {'buyerId': 'buyer-1'});
  });

  test('fetchMore* delegira obavezan offset', () async {
    final repo = _RecordingOrdersRepository();
    final service = OrdersService.forTesting(repository: repo);

    await service.fetchMoreOrdersByBuyer('buyer-1', offset: 40);
    await service.fetchMoreOrdersBySeller('seller-1', offset: 60);

    expect(repo.calls['fetchMoreOrdersByBuyer'],
        {'buyerId': 'buyer-1', 'offset': 40, 'statusFilter': null});
    expect(repo.calls['fetchMoreOrdersBySeller'],
        {'sellerId': 'seller-1', 'offset': 60, 'statusFilter': null});
  });

  test('stream upiti (getOrdersByBuyer/Seller) delegira refreshTrigger',
      () async {
    final repo = _RecordingOrdersRepository();
    final service = OrdersService.forTesting(repository: repo);
    final refresh = Stream<void>.periodic(const Duration(hours: 1));

    final sellerStream =
        service.getOrdersBySeller('seller-1', refreshTrigger: refresh);
    final buyerStream =
        service.getOrdersByBuyer('buyer-1', refreshTrigger: refresh);

    expect(await sellerStream.first, hasLength(1));
    expect(await buyerStream.first, hasLength(1));
    expect(repo.calls['getOrdersBySeller'], {
      'sellerId': 'seller-1',
      'statusFilter': null,
      'refreshTrigger': refresh,
    });
    expect(repo.calls['getOrdersByBuyer'], {
      'buyerId': 'buyer-1',
      'statusFilter': null,
      'refreshTrigger': refresh,
    });
  });

  test('createSingleProductOrder delegira sve argumente', () async {
    final repo = _RecordingOrdersRepository();
    final service = OrdersService.forTesting(repository: repo);
    const selection = DeliverySelectionModel(
      method: DeliveryMethod.sellerDelivery,
      pointId: 'point-1',
      slotId: 'slot-1',
      city: 'Beograd',
      pointLabel: 'Kod domaćina',
      address: 'Selovačka 1',
      weekday: 3,
      timeFrom: '09:00',
      timeTo: '12:00',
    );

    final orderId = await service.createSingleProductOrder(
      buyerId: 'buyer-1',
      sellerId: 'seller-1',
      productId: 'product-1',
      productName: 'Med bagrem',
      quantityKg: 0.5,
      unitType: 'kg',
      note: 'Molim svežije',
      buyerCity: 'Beograd',
      buyerPhone: '0600000000',
      buyerAddress: 'Ulica 1',
      buyerPostalCode: '11000',
      deliveryMethod: DeliveryMethod.sellerDelivery,
      deliverySelection: selection,
    );

    expect(orderId, 'new-order-id');
    expect(repo.calls['createSingleProductOrder'], {
      'buyerId': 'buyer-1',
      'sellerId': 'seller-1',
      'productId': 'product-1',
      'productName': 'Med bagrem',
      'quantityKg': 0.5,
      'unitType': 'kg',
      'note': 'Molim svežije',
      'buyerCity': 'Beograd',
      'buyerPhone': '0600000000',
      'buyerAddress': 'Ulica 1',
      'buyerPostalCode': '11000',
      'deliveryMethod': DeliveryMethod.sellerDelivery,
      'deliverySelection': selection,
    });
  });

  test('createOrderWithItems delegira listu stavki', () async {
    final repo = _RecordingOrdersRepository();
    final service = OrdersService.forTesting(repository: repo);
    final items = [
      const OrderItemModel(
        productId: 'product-1',
        productName: 'Med',
        quantityKg: 0.5,
        unitPrice: 1200,
      ),
      const OrderItemModel(
        productId: 'product-2',
        productName: 'Sir',
        quantityKg: 1,
        unitPrice: 900,
      ),
    ];

    final orderId = await service.createOrderWithItems(
      buyerId: 'buyer-1',
      sellerId: 'seller-1',
      items: items,
      note: 'Grupna porudžbina',
      buyerCity: 'Beograd',
      buyerPhone: '0600000000',
    );

    expect(orderId, 'new-order-id');
    expect(repo.calls['createOrderWithItems']?['items'], same(items));
    expect(
        repo.calls['createOrderWithItems']?['deliveryMethod'],
        DeliveryMethod.agreement,
        reason: 'Podrazumevana metoda dostave se prosleđuje.');
  });

  test('statusne promene (update/cancel/archive/confirm) delegiraju', () async {
    final repo = _RecordingOrdersRepository();
    final service = OrdersService.forTesting(repository: repo);

    await service.updateOrderStatus('order-1', OrderStatus.accepted);
    await service.cancelOrderBySeller('order-1', 'Nema na stanju');
    await service.archiveOrderByBuyer('buyer-1', 'order-1');
    await service.archiveOrderBySeller('seller-1', 'order-1');
    await service.archiveOrder('order-1');
    await service.confirmOrderReceivedByBuyer('order-1');

    expect(repo.calls['updateOrderStatus'],
        {'orderId': 'order-1', 'status': OrderStatus.accepted});
    expect(repo.calls['cancelOrderBySeller'],
        {'orderId': 'order-1', 'reason': 'Nema na stanju'});
    expect(
        repo.calls['archiveOrderByBuyer'], {'buyerId': 'buyer-1', 'orderId': 'order-1'});
    expect(repo.calls['archiveOrderBySeller'],
        {'sellerId': 'seller-1', 'orderId': 'order-1'});
    expect(repo.calls['archiveOrder'], {'orderId': 'order-1'});
    expect(repo.calls['confirmOrderReceivedByBuyer'], {'orderId': 'order-1'});
  });

  test('forTesting koristi prosleđeni repozitorijum (repository getter)',
      () async {
    final repo = _RecordingOrdersRepository();
    final service = OrdersService.forTesting(repository: repo);

    expect(identical(service.repository, repo), isTrue,
        reason: 'Servis mora delegirati na prosleđeni repozitorijum.');
  });

  test('factory sa repository != null stvara NOVU instancu (ne singleton)',
      () async {
    final repo = _RecordingOrdersRepository();
    final serviceA = OrdersService(repository: repo);
    final serviceB = OrdersService(repository: repo);
    final singleton = OrdersService();

    expect(identical(serviceA, serviceB), isFalse,
        reason: 'Eksplicitni repository zahteva novu instancu za test/plug-in.');
    expect(identical(serviceA, singleton), isFalse,
        reason: 'Factory bez argumenata vraća jediničnu instancu.');
  });
}

/// Mock repozitorijum koji snima sve pozive sa argumentima.
class _RecordingOrdersRepository implements OrdersRepository {
  final calls = <String, Map<String, Object?>>{};

  final order = OrderModel(
    id: 'order-1',
    buyerId: 'buyer-1',
    sellerId: 'seller-1',
    note: '',
    buyerCity: 'Beograd',
    buyerPhone: '0600000000',
    createdAt: DateTime(2026, 1, 1),
  );

  @override
  Future<List<OrderModel>> fetchOrdersByBuyer(
    String buyerId, {
    String? statusFilter,
    int limit = 20,
    int offset = 0,
  }) async {
    calls['fetchOrdersByBuyer'] = {
      'buyerId': buyerId,
      'statusFilter': statusFilter,
      'limit': limit,
      'offset': offset,
    };
    return [order];
  }

  @override
  Future<List<OrderModel>> fetchOrdersBySeller(
    String sellerId, {
    String? statusFilter,
    int limit = 20,
    int offset = 0,
  }) async {
    calls['fetchOrdersBySeller'] = {
      'sellerId': sellerId,
      'statusFilter': statusFilter,
      'limit': limit,
      'offset': offset,
    };
    return [order];
  }

  @override
  Future<OrderModel?> getOrderById(String orderId) async {
    calls['getOrderById'] = {'orderId': orderId};
    return order;
  }

  @override
  Future<List<OrderItemModel>> getOrderItems(String orderId) async {
    calls['getOrderItems'] = {'orderId': orderId};
    return [
      const OrderItemModel(
        productId: 'product-1',
        productName: 'Med',
        quantityKg: 0.5,
        unitType: 'kg',
        unitPrice: 1200,
      ),
    ];
  }

  @override
  Future<List<OrderStatusAuditLogModel>> getOrderStatusAuditLogs(
    String orderId,
  ) async {
    calls['getOrderStatusAuditLogs'] = {'orderId': orderId};
    return [
      OrderStatusAuditLogModel(
        id: 'log-1',
        orderId: orderId,
        oldStatus: 'sent',
        newStatus: 'accepted',
        changedByRole: 'seller',
        changedAt: DateTime(2026, 1, 2),
      ),
    ];
  }

  @override
  Future<SellerStats> getSellerStats(String sellerId) async {
    calls['getSellerStats'] = {'sellerId': sellerId};
    return SellerStats(pendingCount: 2, totalCount: 10, revenue: 15000);
  }

  @override
  Future<BuyerStats> getBuyerStats(String buyerId) async {
    calls['getBuyerStats'] = {'buyerId': buyerId};
    return BuyerStats(pendingCount: 1, totalSuccessCount: 4, totalSpent: 9000);
  }

  @override
  Future<List<BuyerSellerStats>> getOrdersByBuyerForSellerStats(
    String buyerId,
  ) async {
    calls['getOrdersByBuyerForSellerStats'] = {'buyerId': buyerId};
    return [
      const BuyerSellerStats(
        sellerId: 'seller-1',
        sellerName: 'Gazdinstvo Pero',
        orderCount: 3,
        totalSpent: 7500,
        lastOrderId: 'order-1',
      ),
    ];
  }

  @override
  Future<List<OrderModel>> fetchMoreOrdersByBuyer(
    String buyerId, {
    required int offset,
    String? statusFilter,
  }) async {
    calls['fetchMoreOrdersByBuyer'] = {
      'buyerId': buyerId,
      'offset': offset,
      'statusFilter': statusFilter,
    };
    return [order];
  }

  @override
  Future<List<OrderModel>> fetchMoreOrdersBySeller(
    String sellerId, {
    required int offset,
    String? statusFilter,
  }) async {
    calls['fetchMoreOrdersBySeller'] = {
      'sellerId': sellerId,
      'offset': offset,
      'statusFilter': statusFilter,
    };
    return [order];
  }

  @override
  Stream<List<OrderModel>> getOrdersBySeller(
    String sellerId, {
    String? statusFilter,
    Stream<void>? refreshTrigger,
  }) {
    calls['getOrdersBySeller'] = {
      'sellerId': sellerId,
      'statusFilter': statusFilter,
      'refreshTrigger': refreshTrigger,
    };
    return Stream.value([order]);
  }

  @override
  Stream<List<OrderModel>> getOrdersByBuyer(
    String buyerId, {
    String? statusFilter,
    Stream<void>? refreshTrigger,
  }) {
    calls['getOrdersByBuyer'] = {
      'buyerId': buyerId,
      'statusFilter': statusFilter,
      'refreshTrigger': refreshTrigger,
    };
    return Stream.value([order]);
  }

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
    calls['createSingleProductOrder'] = {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'productId': productId,
      'productName': productName,
      'quantityKg': quantityKg,
      'unitType': unitType,
      'note': note,
      'buyerCity': buyerCity,
      'buyerPhone': buyerPhone,
      'buyerAddress': buyerAddress,
      'buyerPostalCode': buyerPostalCode,
      'deliveryMethod': deliveryMethod,
      'deliverySelection': deliverySelection,
    };
    return 'new-order-id';
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
    calls['createOrderWithItems'] = {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'items': items,
      'note': note,
      'buyerCity': buyerCity,
      'buyerPhone': buyerPhone,
      'buyerAddress': buyerAddress,
      'buyerPostalCode': buyerPostalCode,
      'deliveryMethod': deliveryMethod,
      'deliverySelection': deliverySelection,
    };
    return 'new-order-id';
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    calls['updateOrderStatus'] = {'orderId': orderId, 'status': status};
  }

  @override
  Future<void> cancelOrderBySeller(String orderId, String reason) async {
    calls['cancelOrderBySeller'] = {'orderId': orderId, 'reason': reason};
  }

  @override
  Future<void> archiveOrderByBuyer(String buyerId, String orderId) async {
    calls['archiveOrderByBuyer'] = {'buyerId': buyerId, 'orderId': orderId};
  }

  @override
  Future<void> archiveOrderBySeller(String sellerId, String orderId) async {
    calls['archiveOrderBySeller'] = {'sellerId': sellerId, 'orderId': orderId};
  }

  @override
  Future<void> archiveOrder(String orderId) async {
    calls['archiveOrder'] = {'orderId': orderId};
  }

  @override
  Future<void> confirmOrderReceivedByBuyer(String orderId) async {
    calls['confirmOrderReceivedByBuyer'] = {'orderId': orderId};
  }
}
