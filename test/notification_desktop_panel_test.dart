import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/notification_model.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/services/orders/orders_service.dart';
import 'package:mleko/widgets/notifications/notification_desktop_panel.dart';
import 'package:provider/provider.dart';

void main() {
  group('NotificationDesktopPanel', () {
    testWidgets('renders empty state when list is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationDesktopPanel(
              list: const [],
              onDelete: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Sva obaveštenja'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Nemate obaveštenja'), findsOneWidget);
    });

    testWidgets('renders notification items and triggers delete', (tester) async {
      final notif = NotificationModel(
        id: 'n-1',
        userId: 'u-1',
        type: 'new_order',
        title: 'Nova porudžbina',
        body: 'Kupac je poručio 2 kg sira.',
        createdAt: DateTime.now(),
      );

      NotificationModel? deleted;
      final appState = AppState(ordersService: OrdersService());

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Scaffold(
              body: NotificationDesktopPanel(
                list: [notif],
                onDelete: (n) => deleted = n,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Sva obaveštenja'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Nova porudžbina'), findsOneWidget);
      expect(find.text('Kupac je poručio 2 kg sira.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(deleted?.id, 'n-1');
    });
  });
}
