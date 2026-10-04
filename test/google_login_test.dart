import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/providers/app_settings_provider.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/services/auth/auth_service.dart';
import 'package:mleko/services/orders/orders_service.dart';
import 'package:mleko/widgets/auth/google_icon.dart';
import 'package:mleko/widgets/auth/login_form.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget() {
    final auth = AuthService();
    final appState = AppState(
      ordersService: OrdersService(),
      authService: auth,
    );
    final appSettings = AppSettingsProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<AppSettingsProvider>.value(value: appSettings),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LoginForm(),
          ),
        ),
      ),
    );
  }

  testWidgets('GoogleLogo widget renders cleanly with CustomPaint',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: GoogleLogo(size: 24),
          ),
        ),
      ),
    );
    expect(find.byType(GoogleLogo), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('LoginForm renders "Nastavi putem Google-a" button and GoogleLogo',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Nastavi putem Google-a'), findsOneWidget);
    expect(find.byType(GoogleLogo), findsOneWidget);
  });
}
