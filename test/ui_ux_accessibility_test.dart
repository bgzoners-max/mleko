import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/core/theme.dart';
import 'package:mleko/widgets/app_empty_state.dart';
import 'package:mleko/widgets/app_shimmer.dart';
import 'package:mleko/widgets/skeletons/category_skeletons.dart';
import 'package:mleko/widgets/skeletons/communication_skeletons.dart';
import 'package:mleko/widgets/skeletons/order_skeletons.dart';
import 'package:mleko/widgets/skeletons/product_skeletons.dart';
import 'package:mleko/widgets/skeletons/profile_skeletons.dart';

void main() {
  group('5.4 WCAG 2.1 AA Touch Target & Font Scaling', () {
    test('computeMinTouchTarget guarantees minimum 44x44 dp', () {
      final compactTarget = computeMinTouchTarget(compact: true, fontScale: 1.0);
      final normalTarget = computeMinTouchTarget(compact: false, fontScale: 1.0);

      expect(compactTarget, greaterThanOrEqualTo(44.0));
      expect(normalTarget, greaterThanOrEqualTo(48.0));
    });

    test('computeMinTouchTarget scales up when fontScale is increased', () {
      final baseTarget = computeMinTouchTarget(compact: true, fontScale: 1.0);
      final scaledTarget = computeMinTouchTarget(compact: true, fontScale: 1.25);
      final maxScaledTarget = computeMinTouchTarget(compact: true, fontScale: 1.5);

      expect(scaledTarget, greaterThan(baseTarget));
      expect(maxScaledTarget, greaterThanOrEqualTo(scaledTarget));
    });

    test('ThemeData button themes reflect fontScale and minTouchTarget', () {
      final themeNormal = buildAppTheme(compact: true, fontScale: 1.0);
      final themeScaled = buildAppTheme(compact: true, fontScale: 1.3);

      final normalBtnSize = themeNormal.elevatedButtonTheme.style?.minimumSize?.resolve({});
      final scaledBtnSize = themeScaled.elevatedButtonTheme.style?.minimumSize?.resolve({});

      expect(normalBtnSize?.width, greaterThanOrEqualTo(44.0));
      expect(normalBtnSize?.height, greaterThanOrEqualTo(44.0));

      expect(scaledBtnSize?.width, greaterThan(normalBtnSize!.width));
      expect(scaledBtnSize?.height, greaterThan(normalBtnSize.height));

      final darkNormal = buildAppDarkTheme(compact: true, fontScale: 1.0);
      final darkScaled = buildAppDarkTheme(compact: true, fontScale: 1.3);
      final darkNormalSize = darkNormal.elevatedButtonTheme.style?.minimumSize?.resolve({});
      final darkScaledSize = darkScaled.elevatedButtonTheme.style?.minimumSize?.resolve({});

      expect(darkNormalSize?.width, greaterThanOrEqualTo(44.0));
      expect(darkScaledSize?.width, greaterThan(darkNormalSize!.width));
    });
  });

  group('5.1 & 5.2 Shimmer Theme-Adaptation & Skeletons in Light & Dark Mode', () {
    testWidgets('AppShimmer adapts base and highlight colors to brightness', (tester) async {
      late Color lightBase;
      late Color darkBase;

      await tester.pumpWidget(
        Theme(
          data: ThemeData(brightness: Brightness.light),
          child: Builder(
            builder: (ctx) {
              lightBase = AppShimmer.getBaseColor(ctx);
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        Theme(
          data: ThemeData(brightness: Brightness.dark),
          child: Builder(
            builder: (ctx) {
              darkBase = AppShimmer.getBaseColor(ctx);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(lightBase, equals(Colors.grey.shade300));
      expect(darkBase, equals(Colors.grey.shade800));
    });

    testWidgets('All skeleton widgets render cleanly in light and dark mode', (tester) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        final theme = ThemeData(brightness: brightness);

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: ProductListSkeleton(itemCount: 2),
            ),
          ),
        );
        expect(find.byType(ProductListSkeleton), findsOneWidget);

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: OrderListSkeleton(itemCount: 2),
            ),
          ),
        );
        expect(find.byType(OrderListSkeleton), findsOneWidget);

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: CategoryGridSkeleton(itemCount: 2),
            ),
          ),
        );
        expect(find.byType(CategoryGridSkeleton), findsOneWidget);

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: ConversationListSkeleton(itemCount: 2),
            ),
          ),
        );
        expect(find.byType(ConversationListSkeleton), findsOneWidget);

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: BuyerProfileSkeleton(),
            ),
          ),
        );
        expect(find.byType(BuyerProfileSkeleton), findsOneWidget);
      }
    });
  });

  group('5.3 AppEmptyState with Serbian copy and actionable CTA', () {
    testWidgets('Renders icon, title, subtitle and triggers CTA', (tester) async {
      bool ctaPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'Korpa je još prazna',
              subtitle: 'Dodaj nekoliko domaćih proizvoda iz svog kraja.',
              ctaLabel: 'Istraži proizvode',
              ctaIcon: Icons.search,
              onCtaPressed: () {
                ctaPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Korpa je još prazna'), findsOneWidget);
      expect(find.text('Dodaj nekoliko domaćih proizvoda iz svog kraja.'), findsOneWidget);
      expect(find.text('Istraži proizvode'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      await tester.tap(find.text('Istraži proizvode'));
      await tester.pump();

      expect(ctaPressed, isTrue);
    });
  });
}
