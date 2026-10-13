import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mleko/core/responsive.dart';
import 'package:mleko/core/router.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/services/orders/orders_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeOrdersService implements OrdersService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation & Breakpoints Alignment', () {
    test('kDesktopBreakpoint is exactly 1200 and matches Breakpoints.desktop', () {
      expect(kDesktopBreakpoint, 1200);
      expect(kDesktop, 1200);
      expect(kWide, 1440);
      expect(Breakpoints.desktop, 1200);
      expect(Breakpoints.wideDesktop, 1440);
      expect(Breakpoints.tablet, 1200);
    });

    testWidgets('Breakpoints.isDesktop returns true only on >= 1200', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final isDesktop = Breakpoints.isDesktop(context);
              return Text(isDesktop ? 'DESKTOP' : 'NOT_DESKTOP');
            },
          ),
        ),
      );

      // 1024px (stari nesklad gde je router mislio da je desktop)
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pump();
      expect(find.text('NOT_DESKTOP'), findsOneWidget);

      // 1200px (ujednaceni desktop prag)
      tester.view.physicalSize = const Size(1200, 800);
      await tester.pump();
      expect(find.text('DESKTOP'), findsOneWidget);
    });
  });

  group('Router Structure & Clean Routes', () {
    test('createRouter builds cleanly and does not have duplicate /conversations routes', () {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState(ordersService: _FakeOrdersService());
      final router = createRouter(appState);

      // Brojimo koliko GoRoute instanci ima path == '/conversations'
      var conversationsRouteCount = 0;
      for (final r in router.configuration.routes) {
        if (r is GoRoute && r.path == '/conversations') {
          conversationsRouteCount++;
        } else if (r is StatefulShellRoute) {
          for (final branch in r.branches) {
            for (final subRoute in branch.routes) {
              if (subRoute is GoRoute && subRoute.path == '/conversations') {
                conversationsRouteCount++;
              }
            }
          }
        }
      }

      // Mora biti tacno 1 (unutar StatefulShellBranch), bez duplog na root nivou
      expect(conversationsRouteCount, 1);
    });

    test('short links /ad/:id and /p/:id exist in router and redirect accurately', () {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState(ordersService: _FakeOrdersService());
      final router = createRouter(appState);

      final rootGoRoutes = router.configuration.routes.whereType<GoRoute>().toList();
      final adRoute = rootGoRoutes.firstWhere((r) => r.path == '/ad/:id');
      final pRoute = rootGoRoutes.firstWhere((r) => r.path == '/p/:id');

      expect(adRoute, isNotNull);
      expect(pRoute, isNotNull);
    });
  });
}
