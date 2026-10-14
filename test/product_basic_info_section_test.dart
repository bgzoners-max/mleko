import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/category.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/widgets/seller/product_basic_info_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TextEditingController nameCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController minOrderCtrl;
  late TextEditingController orderStepCtrl;
  late TextEditingController availableCtrl;

  setUp(() {
    nameCtrl = TextEditingController(text: 'Domaći sir');
    priceCtrl = TextEditingController(text: '800');
    minOrderCtrl = TextEditingController(text: '1');
    orderStepCtrl = TextEditingController(text: '0.5');
    availableCtrl = TextEditingController(text: '20');
  });

  tearDown(() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    minOrderCtrl.dispose();
    orderStepCtrl.dispose();
    availableCtrl.dispose();
  });

  Widget buildWidget({required Size screenSize}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: Scaffold(
          body: SingleChildScrollView(
            child: ProductBasicInfoSection(
              groups: const [
                CategoryGroup(
                  parent: Category(id: 'mleko', name: 'Mlečni proizvodi'),
                  children: [
                    Category(id: 'sir', name: 'Sir', parentId: 'mleko'),
                    Category(id: 'kajmak', name: 'Kajmak', parentId: 'mleko'),
                  ],
                ),
              ],
              category: 'Sir',
              onCategoryChanged: (_) {},
              unitType: ProductModel.unitKg,
              onUnitTypeChanged: (_) {},
              nameController: nameCtrl,
              priceController: priceCtrl,
              minOrderController: minOrderCtrl,
              orderStepController: orderStepCtrl,
              availableController: availableCtrl,
              quantityHintBuilder: (text, unit) => 'Prikaz: $text $unit',
              onChanged: () {},
            ),
          ),
        ),
      ),
    );
  }

  group('ProductBasicInfoSection Responsive Layout', () {
    testWidgets('renders all fields stacked vertically on mobile without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildWidget(screenSize: const Size(390, 844)));
      await tester.pumpAndSettle();

      final minOrderFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.controller == minOrderCtrl,
      );
      final orderStepFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.controller == orderStepCtrl,
      );
      final availableFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.controller == availableCtrl,
      );

      expect(minOrderFinder, findsOneWidget);
      expect(orderStepFinder, findsOneWidget);
      expect(availableFinder, findsOneWidget);

      final minOrderTop = tester.getTopLeft(minOrderFinder).dy;
      final orderStepTop = tester.getTopLeft(orderStepFinder).dy;
      final availableTop = tester.getTopLeft(availableFinder).dy;

      expect(minOrderTop < orderStepTop, isTrue);
      expect(orderStepTop < availableTop, isTrue);
    });

    testWidgets('renders 3 quantity fields side by side in a Row on desktop', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildWidget(screenSize: const Size(1280, 900)));
      await tester.pumpAndSettle();

      final minOrderFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.controller == minOrderCtrl,
      );
      final orderStepFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.controller == orderStepCtrl,
      );
      final availableFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.controller == availableCtrl,
      );

      expect(minOrderFinder, findsOneWidget);
      expect(orderStepFinder, findsOneWidget);
      expect(availableFinder, findsOneWidget);

      // On desktop, all 3 quantity fields share the same top vertical position
      final minOrderTop = tester.getTopLeft(minOrderFinder).dy;
      final orderStepTop = tester.getTopLeft(orderStepFinder).dy;
      final availableTop = tester.getTopLeft(availableFinder).dy;

      expect(minOrderTop, equals(orderStepTop));
      expect(minOrderTop, equals(availableTop));

      // Also name and price share the same top vertical position on desktop
      final nameFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.controller == nameCtrl,
      );
      final priceFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.controller == priceCtrl,
      );
      final nameTop = tester.getTopLeft(nameFinder).dy;
      final priceTop = tester.getTopLeft(priceFinder).dy;
      expect(nameTop, equals(priceTop));
    });
  });
}
