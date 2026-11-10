import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mleko/widgets/home/map_card.dart';

void main() {
  testWidgets('MapCard centers and constrains to 520px on desktop viewport', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: MapCard(),
          ),
        ),
      ),
    );

    expect(find.text('LOKALNA GAZDINSTVA'), findsOneWidget);
    expect(find.text('Zavirite u komšiluk na mapi'), findsOneWidget);
    expect(find.byIcon(Icons.explore_outlined), findsOneWidget);

    final constrainedFinder = find.byWidgetPredicate(
      (widget) => widget is ConstrainedBox && widget.constraints.maxWidth == 520.0,
    );
    expect(constrainedFinder, findsOneWidget);

    final cardSize = tester.getSize(constrainedFinder);
    expect(cardSize.width, equals(520.0));
  });

  testWidgets('MapCard fills width with 16px margins on mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MapCard(),
        ),
      ),
    );

    expect(find.text('LOKALNA GAZDINSTVA'), findsOneWidget);

    final desktopConstrainedFinder = find.byWidgetPredicate(
      (widget) => widget is ConstrainedBox && widget.constraints.maxWidth == 520.0,
    );
    expect(desktopConstrainedFinder, findsNothing);

    final paddingFinder = find.byWidgetPredicate(
      (widget) => widget is Padding && widget.padding == const EdgeInsets.symmetric(horizontal: 16),
    );
    expect(paddingFinder, findsOneWidget);
  });

  testWidgets('MapCard respects custom maxWidth override', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MapCard(maxWidth: 480.0),
        ),
      ),
    );

    final constrainedFinder = find.byWidgetPredicate(
      (widget) => widget is ConstrainedBox && widget.constraints.maxWidth == 480.0,
    );
    expect(constrainedFinder, findsOneWidget);
  });

  testWidgets('Tapping MapCard navigates to /sellers-map', (tester) async {
    bool navigated = false;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: MapCard()),
        ),
        GoRoute(
          path: '/sellers-map',
          builder: (_, __) {
            navigated = true;
            return const Scaffold(body: Text('Sellers Map Screen'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Zavirite u komšiluk na mapi'));
    await tester.pumpAndSettle();

    expect(navigated, isTrue);
    expect(find.text('Sellers Map Screen'), findsOneWidget);
  });
}

