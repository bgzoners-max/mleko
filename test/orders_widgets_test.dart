import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/order_model.dart';
import 'package:mleko/services/social/reviews_service.dart';
import 'package:mleko/widgets/orders/can_review_order_button.dart';
import 'package:mleko/widgets/orders/orders_status_filter_bar.dart';
import 'package:provider/provider.dart';

class _FakeReviewsService implements ReviewsService {
  _FakeReviewsService(this.canReview);

  final bool canReview;
  final List<String> canReviewCalls = [];

  @override
  Future<bool> canReviewOrder(String buyerId, String orderId) async {
    canReviewCalls.add('$buyerId:$orderId');
    return canReview;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

OrderModel _order({bool? isReviewed}) => OrderModel(
      id: 'o1',
      buyerId: 'b1',
      sellerId: 's1',
      note: '',
      buyerCity: 'Beograd',
      buyerPhone: '0601234567',
      createdAt: DateTime(2026, 1, 2),
      isReviewed: isReviewed,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OrdersSegmentedControl', () {
    testWidgets('prikazuje sva tri segmenta i javlja promenu selekcije',
        (tester) async {
      int? changed;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OrdersSegmentedControl(
            segmentIndex: 0,
            onSegmentChanged: (i) => changed = i,
          ),
        ),
      ));

      expect(find.text('U toku'), findsOneWidget);
      expect(find.text('Arhiva'), findsOneWidget);
      expect(find.text('Prodavci'), findsOneWidget);

      await tester.tap(find.text('Arhiva'));
      await tester.pumpAndSettle();

      expect(changed, 1);
    });
  });

  group('OrderStatusFilterChips', () {
    testWidgets('prikazuje svih pet filtera i javlja izbor', (tester) async {
      int? changed;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OrderStatusFilterChips(
            statusChipIndex: 0,
            onStatusChipChanged: (i) => changed = i,
          ),
        ),
      ));

      expect(find.text('Sve'), findsOneWidget);
      expect(find.text('Čeka prodavca'), findsOneWidget);
      expect(find.text('Prihvaćene'), findsOneWidget);
      expect(find.text('Poslate'), findsOneWidget);
      expect(find.text('Odbijene'), findsOneWidget);

      await tester.tap(find.text('Odbijene'));
      await tester.pumpAndSettle();

      expect(changed, 4);
    });

    testWidgets('označava aktivan filter kao selektovan', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OrderStatusFilterChips(
            statusChipIndex: 2,
            onStatusChipChanged: (_) {},
          ),
        ),
      ));

      final chip = tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Prihvaćene'));
      expect(chip.selected, isTrue);
      final sveChip =
          tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Sve'));
      expect(sveChip.selected, isFalse);
    });
  });

  group('CanReviewOrderButton', () {
    Future<void> pumpButton(
      WidgetTester tester, {
      required bool? isReviewed,
      required _FakeReviewsService reviewsService,
    }) async {
      await tester.pumpWidget(
        Provider<ReviewsService>.value(
          value: reviewsService,
          child: MaterialApp(
              home: Scaffold(
                  body: Center(
            child: CanReviewOrderButton(
              userId: 'b1',
              order: _order(isReviewed: isReviewed),
              onPressed: () {},
            ),
          ))),
        ),
      );
    }

    testWidgets(
        'sakriva se kada je recenzija već ostavljena (isReviewed: true)',
        (tester) async {
      final reviews = _FakeReviewsService(false);
      await pumpButton(tester, isReviewed: true, reviewsService: reviews);
      await tester.pumpAndSettle();

      expect(find.text('Ostavi recenziju'), findsNothing);
      // Ne poziva servis — flag je poznat iz batch podataka.
      expect(reviews.canReviewCalls, isEmpty);
    });

    testWidgets('prikazuje dugme bez poziva servisa (isReviewed: false)',
        (tester) async {
      var pressed = false;
      final reviews = _FakeReviewsService(false);
      await tester.pumpWidget(
        Provider<ReviewsService>.value(
          value: reviews,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: CanReviewOrderButton(
                  userId: 'b1',
                  order: _order(isReviewed: false),
                  onPressed: () => pressed = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ostavi recenziju'), findsOneWidget);
      expect(reviews.canReviewCalls, isEmpty);

      await tester.tap(find.text('Ostavi recenziju'));
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });

    testWidgets('proverava servis kada flag nije poznat (isReviewed: null)',
        (tester) async {
      final reviews = _FakeReviewsService(true);
      await pumpButton(tester, isReviewed: null, reviewsService: reviews);
      await tester.pumpAndSettle();

      expect(find.text('Ostavi recenziju'), findsOneWidget);
      expect(reviews.canReviewCalls, ['b1:o1']);
    });

    testWidgets('sakriva se kada servis kaže da recenzija postoji',
        (tester) async {
      final reviews = _FakeReviewsService(false);
      await pumpButton(tester, isReviewed: null, reviewsService: reviews);
      await tester.pumpAndSettle();

      expect(find.text('Ostavi recenziju'), findsNothing);
      expect(reviews.canReviewCalls, ['b1:o1']);
    });
  });
}
