import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mleko/widgets/app_back_button.dart';

void main() {
  testWidgets('AppBackButton calls fallbackRoute with context.go when cannot pop',
      (tester) async {
    String currentRoute = '/details';

    final router = GoRouter(
      initialLocation: '/details',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Text('Home Screen'),
          ),
        ),
        GoRoute(
          path: '/details',
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              leading: const AppBackButton(fallbackRoute: '/'),
            ),
            body: const Text('Details Screen'),
          ),
        ),
      ],
    );

    router.routerDelegate.addListener(() {
      currentRoute = router.state.matchedLocation;
    });

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Details Screen'), findsOneWidget);
    expect(find.byType(AppBackButton), findsOneWidget);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(find.text('Home Screen'), findsOneWidget);
    expect(currentRoute, '/');
  });

  testWidgets('AppBackButton pops when navigation stack has history',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/details'),
                child: const Text('Go To Details'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/details',
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              leading: const AppBackButton(fallbackRoute: '/fallback'),
            ),
            body: const Text('Details Screen'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Go To Details'));
    await tester.pumpAndSettle();

    expect(find.text('Details Screen'), findsOneWidget);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(find.text('Go To Details'), findsOneWidget);
  });

  testWidgets('AppHomeButton always navigates to /', (tester) async {
    final router = GoRouter(
      initialLocation: '/some/nested/page',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Text('Root Home Page'),
          ),
        ),
        GoRoute(
          path: '/some/nested/page',
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              actions: const [AppHomeButton()],
            ),
            body: const Text('Nested Page'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nested Page'), findsOneWidget);
    expect(find.byType(AppHomeButton), findsOneWidget);

    await tester.tap(find.byType(AppHomeButton));
    await tester.pumpAndSettle();

    expect(find.text('Root Home Page'), findsOneWidget);
  });
}
