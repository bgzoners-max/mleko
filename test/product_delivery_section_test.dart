import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/widgets/seller/product_delivery_section.dart';

void main() {
  testWidgets('ProductDeliverySection renders farmLocation banner and no dropdown', (tester) async {
    final descController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProductDeliverySection(
              farmLocation: 'Valjevo',
              pickupOptions: const ['Lično'],
              onPickupOptionToggled: (_) {},
              deliveryPointsLoading: false,
              sellerDeliveryPoints: const [],
              deliveryMode: ProductDeliveryMode.none,
              onDeliveryModeChanged: (_) {},
              selectedDeliveryPointIds: const {},
              onDeliveryPointToggled: (_) {},
              descriptionController: descController,
              isDomestic: true,
              onDomesticChanged: (_) {},
              availableNow: true,
              onAvailableNowChanged: (_) {},
              onEditDeliveryLocations: () {},
            ),
          ),
        ),
      ),
    );

    // Verify farm location banner exists
    expect(find.textContaining('Matična lokacija gazdinstva:'), findsOneWidget);
    expect(find.textContaining('Valjevo'), findsOneWidget);
    expect(find.textContaining('(automatski iz profila)'), findsOneWidget);

    // Verify manual DropdownButtonFormField is NOT present
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('Način preuzimanja *'), findsOneWidget);
  });

  testWidgets('ProductDeliverySection triggers onEditDeliveryLocations when tapped', (tester) async {
    final descController = TextEditingController();
    var editLocationsCalled = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProductDeliverySection(
              farmLocation: 'Valjevo',
              pickupOptions: const ['Lično'],
              onPickupOptionToggled: (_) {},
              deliveryPointsLoading: false,
              sellerDeliveryPoints: const [],
              deliveryMode: ProductDeliveryMode.none,
              onDeliveryModeChanged: (_) {},
              selectedDeliveryPointIds: const {},
              onDeliveryPointToggled: (_) {},
              descriptionController: descController,
              isDomestic: true,
              onDomesticChanged: (_) {},
              availableNow: true,
              onAvailableNowChanged: (_) {},
              onEditDeliveryLocations: () => editLocationsCalled++,
            ),
          ),
        ),
      ),
    );

    final editButton = find.text('Uredi lokacije');
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pump();

    expect(editLocationsCalled, equals(1));

    // When points list is empty, helper button also exists
    final addPointsButton = find.text('Dodaj punktove dostave');
    expect(addPointsButton, findsOneWidget);
    await tester.ensureVisible(addPointsButton);
    await tester.pumpAndSettle();
    await tester.tap(addPointsButton);
    await tester.pump();

    expect(editLocationsCalled, equals(2));
  });
}

