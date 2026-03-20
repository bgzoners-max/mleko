// ignore_for_file: avoid_relative_lib_imports, unused_import

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:mleko/models/order_model.dart';
import 'package:mleko/models/order_status_audit_log_model.dart';
import 'package:mleko/widgets/order_status_audit_log_section.dart';
import 'package:mleko/widgets/order_status_timeline.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('sr');
  });

  testWidgets('order status timeline + audit retry smoke',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const OrderStatusTimeline(status: OrderStatus.rejected),
              OrderStatusAuditLogSection(
                orderId: 'ord-1',
                logsLoader: (id) => Future.error(Exception('DB error')),
              ),
            ],
          ),
        ),
      ),
    );

    // FutureBuilder should show our retry UI.
    await tester.pumpAndSettle();
    expect(find.text('Greška pri učitavanju istorije statusa.'), findsOneWidget);
    expect(find.text('Pokušaj ponovo'), findsOneWidget);

    // Verify stopped message exists.
    expect(find.textContaining('Tok porudzbine je prekinut'), findsOneWidget);

    // Prevent unused variable warning in some IDEs.
    binding;
  });
}

