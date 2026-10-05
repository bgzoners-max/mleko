import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/core/responsive.dart';
import 'package:mleko/core/theme.dart';
import 'package:mleko/providers/app_settings_provider.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/screens/seller/seller_settings_screen.dart';
import 'package:mleko/models/category.dart';
import 'package:mleko/services/auth/auth_service.dart';
import 'package:mleko/services/auth/users_service.dart';
import 'package:mleko/services/orders/orders_service.dart';
import 'package:mleko/widgets/beta_announcement_banner.dart';
import 'package:mleko/widgets/home/category_grid.dart';
import 'package:mleko/widgets/home/market_mode_switcher.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Breakpoints Token and Calculation Tests', () {
    testWidgets('Validates compact phone breakpoint (320dp)', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late BuildContext testContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              testContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(Breakpoints.isCompactPhone(testContext), isTrue);
      expect(Breakpoints.isPhone(testContext), isTrue);
      expect(Breakpoints.isTablet(testContext), isFalse);
      expect(Breakpoints.isDesktop(testContext), isFalse);
      expect(Breakpoints.horizontalPadding(testContext), equals(16.0));
      expect(Breakpoints.productGridColumns(testContext), equals(2));
    });

    testWidgets('Validates standard mobile breakpoint (390dp)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late BuildContext testContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              testContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(Breakpoints.isCompactPhone(testContext), isFalse);
      expect(Breakpoints.isPhone(testContext), isTrue);
      expect(Breakpoints.isTablet(testContext), isFalse);
      expect(Breakpoints.isDesktop(testContext), isFalse);
      expect(Breakpoints.horizontalPadding(testContext), equals(16.0));
      expect(Breakpoints.productGridColumns(testContext), equals(2));
    });

    testWidgets('Validates tablet breakpoint (768dp)', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late BuildContext testContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              testContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(Breakpoints.isCompactPhone(testContext), isFalse);
      expect(Breakpoints.isPhone(testContext), isFalse);
      expect(Breakpoints.isTablet(testContext), isTrue);
      expect(Breakpoints.isDesktop(testContext), isFalse);
      expect(Breakpoints.horizontalPadding(testContext), equals(24.0));
      expect(Breakpoints.productGridColumns(testContext), equals(3));
    });

    testWidgets('Validates desktop breakpoint (1440dp)', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late BuildContext testContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              testContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(Breakpoints.isCompactPhone(testContext), isFalse);
      expect(Breakpoints.isPhone(testContext), isFalse);
      expect(Breakpoints.isTablet(testContext), isFalse);
      expect(Breakpoints.isDesktop(testContext), isTrue);
      expect(Breakpoints.isWideDesktop(testContext), isTrue);
      expect(Breakpoints.horizontalPadding(testContext), equals(32.0));
      expect(Breakpoints.productGridColumns(testContext), equals(5));
      expect(Breakpoints.maxContentWidth(testContext), equals(1200.0));
    });

    testWidgets('Validates standard desktop breakpoint (1280dp)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late BuildContext testContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              testContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(Breakpoints.isDesktop(testContext), isTrue);
      expect(Breakpoints.isWideDesktop(testContext), isFalse);
      expect(Breakpoints.productGridColumns(testContext), equals(4));
    });
  });

  group('Global Theme BottomSheet Constraints Tests', () {
    test('LightTheme specifies modalMaxWidth constraints for bottom sheets', () {
      final constraints = appTheme.bottomSheetTheme.constraints;
      expect(constraints, isNotNull);
      expect(constraints!.maxWidth, equals(Breakpoints.modalMaxWidth));
    });

    test('DarkTheme specifies modalMaxWidth constraints for bottom sheets', () {
      final constraints = appDarkTheme.bottomSheetTheme.constraints;
      expect(constraints, isNotNull);
      expect(constraints!.maxWidth, equals(Breakpoints.modalMaxWidth));
    });
  });

  group('Price & Currency Row Overflow Resilience', () {
    testWidgets('3:2 flex ratio prevents RenderFlex overflow on narrow 320dp screen with large text scale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Mock the exact Row layout from AddEditClassifiedAdScreen
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(1.3), // 130% accessibility text scale
            ),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: '999999999',
                        decoration: const InputDecoration(labelText: 'Cena'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: 'RSD',
                        items: const [
                          DropdownMenuItem(
                            value: 'RSD',
                            child: Text(
                              'RSD (din)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'EUR',
                            child: Text(
                              'EUR (€)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: (_) {},
                        decoration: const InputDecoration(labelText: 'Valuta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('RSD (din)'), findsOneWidget);
    });
  });

  group('Seller Settings Screen TabBar Responsiveness', () {
    testWidgets('TabBar has isScrollable enabled to prevent squished tabs on small devices',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState(
        ordersService: OrdersService(),
        authService: AuthService(),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<AppSettingsProvider>.value(
              value: AppSettingsProvider(),
            ),
            Provider<UsersService>.value(value: UsersService()),
          ],
          child: const MaterialApp(
            home: SellerSettingsScreen(),
          ),
        ),
      );

      await tester.pump();

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.isScrollable, isTrue);
      expect(tabBar.tabAlignment, equals(TabAlignment.start));
    });
  });

  group('Font Scaling Responsiveness Tests', () {
    testWidgets('CategoryGrid renders 2-line labels without overflow under 1.5x font scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final categories = [
        const Category(id: '1', name: 'Mlečni proizvodi', icon: 'milk'),
        const Category(id: '2', name: 'Suvomesnati proizvodi', icon: 'meat'),
        const Category(id: '3', name: 'Voće i povrće', icon: 'vegetables'),
        const Category(id: '4', name: 'Med i pčelinji proizvodi', icon: 'honey'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: CategoryGrid(
                  topCategories: categories,
                  isWide: false,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Mlečni proizvodi'), findsOneWidget);
      expect(find.text('Suvomesnati proizvodi'), findsOneWidget);
    });

    testWidgets('MarketModeSwitcher adapts without overflow under 1.5x font scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: MarketModeSwitcher(
                currentMode: MarketMode.foodMarket,
                onModeChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Mali Oglasi'), findsOneWidget);
      expect(find.text('Pijaca Hrane'), findsOneWidget);
    });

    testWidgets('AppBar title with BetaBadge does not overflow under 1.5x font scale on 360dp phone',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              appBar: AppBar(
                titleSpacing: 10,
                title: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco_outlined, size: 24),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Domaći market',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ),
                    SizedBox(width: 6),
                    BetaBadge(showInfoIcon: false),
                  ],
                ),
                actions: [
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () {},
                  ),
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {},
                  ),
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    icon: const Icon(Icons.location_on_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Domaći market'), findsOneWidget);
    });
  });
}
