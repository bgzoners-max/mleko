import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/screens/orders_screen.dart';
import 'package:mleko/screens/profile_screen.dart';
import 'package:mleko/services/orders/orders_service.dart';
import 'package:mleko/widgets/guest_notice_banner.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('GuestNoticeBanner renders SizedBox.shrink for everyone', (tester) async {
    final appState = AppState(ordersService: OrdersService());
    appState.setUserForTesting(null);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(
          home: Scaffold(
            body: GuestNoticeBanner(),
          ),
        ),
      ),
    );

    expect(find.text('Prijavljeni ste kao gost'), findsNothing);
    expect(find.text('Prijavi se'), findsNothing);
    expect(find.text('Registruj se'), findsNothing);
  });

  testWidgets('ProfileScreen shows login prompt instead of personal data when user is null', (tester) async {
    final appState = AppState(ordersService: OrdersService());
    appState.setUserForTesting(null);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    expect(find.textContaining('potrebno je da se prijavite'), findsOneWidget);
    expect(find.text('Prijavi se'), findsOneWidget);
    expect(find.text('Moji oglasi'), findsNothing);
    expect(find.text('Postavi novi oglas'), findsNothing);
    expect(find.byIcon(Icons.person_outline), findsNothing);
  });

  testWidgets('OrdersScreen shows login prompt instead of order query when user is null', (tester) async {
    final ordersService = OrdersService();
    final appState = AppState(ordersService: ordersService);
    appState.setUserForTesting(null);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          Provider<OrdersService>.value(value: ordersService),
        ],
        child: const MaterialApp(
          home: OrdersScreen(),
        ),
      ),
    );

    expect(find.textContaining('potrebno je da se prijavite'), findsOneWidget);
    expect(find.text('Prijavi se'), findsOneWidget);
  });
}
