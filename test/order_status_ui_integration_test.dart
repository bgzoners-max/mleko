import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mleko/models/order_model.dart';
import 'package:mleko/models/order_status_audit_log_model.dart';
import 'package:mleko/widgets/order_status_audit_log_section.dart';
import 'package:mleko/widgets/order_status_timeline.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('sr');
  });

  testWidgets('timeline + audit section render status flow in UI',
      (tester) async {
    Future<List<OrderStatusAuditLogModel>> fakeLoader(String _) async {
      return [
        OrderStatusAuditLogModel(
          id: '1',
          orderId: 'ord-1',
          oldStatus: 'accepted',
          newStatus: 'shipped',
          changedByRole: 'seller',
          changedByUserId: 'u-seller',
          changedAt: DateTime.utc(2026, 3, 7, 12, 0),
        ),
        OrderStatusAuditLogModel(
          id: '2',
          orderId: 'ord-1',
          oldStatus: 'shipped',
          newStatus: 'delivered',
          changedByRole: 'buyer',
          changedByUserId: 'u-buyer',
          changedAt: DateTime.utc(2026, 3, 7, 14, 30),
        ),
      ];
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              const OrderStatusTimeline(status: OrderStatus.shipped),
              OrderStatusAuditLogSection(
                orderId: 'ord-1',
                logsLoader: fakeLoader,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Poslato'), findsAtLeastNWidgets(1));
    expect(find.text('Istorija statusa'), findsOneWidget);
    expect(find.text('2 promena'), findsOneWidget);

    await tester.tap(find.text('Istorija statusa'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Prihvaceno -> Poslato'), findsOneWidget);
    expect(find.textContaining('Poslato -> Isporuceno'), findsOneWidget);
    expect(find.textContaining('Prodavac'), findsNWidgets(2));
    expect(find.textContaining('Kupac'), findsOneWidget);
  });

  testWidgets('timeline shows stopped message for rejected order',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OrderStatusTimeline(status: OrderStatus.rejected),
        ),
      ),
    );

    expect(find.textContaining('Tok porudžbine je prekinut'), findsOneWidget);
  });

  testWidgets('audit section shows retry button on error', (tester) async {
    Future<List<OrderStatusAuditLogModel>> failingLoader(String _) async {
      throw Exception('DB error');
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderStatusAuditLogSection(
            orderId: 'ord-1',
            logsLoader: failingLoader,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
        find.text('Greška pri učitavanju istorije statusa.'), findsOneWidget);
    expect(find.text('Pokušaj ponovo'), findsOneWidget);
  });
}
