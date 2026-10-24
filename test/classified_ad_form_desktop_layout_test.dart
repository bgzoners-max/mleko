import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/classifieds/add_edit/classified_ad_form.dart';
import 'package:mleko/widgets/classifieds/add_edit/classified_description_field.dart';
import 'package:mleko/widgets/classifieds/add_edit/classified_seller_type_section.dart';
import 'package:mleko/widgets/classifieds/add_edit/classified_promotion_section.dart';
import 'package:mleko/widgets/classifieds/add_edit/classified_submit_button.dart';

void main() {
  Widget buildTestWidget({required Size screenSize}) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: 'Test oglas');
    final priceController = TextEditingController(text: '1000');
    final cityController = TextEditingController(text: 'Beograd');
    final phoneController = TextEditingController(text: '0641234567');
    final descController = TextEditingController(text: 'Opis oglasa');

    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: Scaffold(
          body: SingleChildScrollView(
            child: ClassifiedAdForm(
              formKey: formKey,
              isTablet: false,
              theme: ThemeData.light(),
              colorScheme: const ColorScheme.light(),
              isPickingImages: false,
              onPickImages: () {},
              existingImages: const [],
              newImageBytes: const <Uint8List>[],
              onRemoveExisting: (_) {},
              onRemoveNew: (_) {},
              incomingCount: 0,
              titleController: titleController,
              selectedCategoryId: 'test_cat',
              selectedCategoryName: 'Test Kategorija',
              onOpenCategoryPicker: () {},
              isConditionApplicable: true,
              condition: 'used',
              onConditionChanged: (_) {},
              priceType: 'fixed',
              currency: 'RSD',
              priceController: priceController,
              onPriceTypeChanged: (_) {},
              onCurrencyChanged: (_) {},
              selectedCategoryBreadcrumbs: const [],
              attributes: const {},
              onAttributeChanged: (_, __) {},
              cityController: cityController,
              phoneController: phoneController,
              phonePublic: true,
              onPhonePublicChanged: (_) {},
              descController: descController,
              sellerType: 'fizicko',
              onSellerTypeChanged: (_) {},
              isUrgent: false,
              onUrgentChanged: (_) {},
              loading: false,
              isEdit: false,
              onSubmit: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('ClassifiedAdForm renders 3 balanced columns on desktop (width >= 960)', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestWidget(screenSize: const Size(1280, 900)));
    await tester.pumpAndSettle();

    // Verify Form child is Row with 3 columns on desktop
    final formWidget = tester.widget<Form>(find.byType(Form));
    expect(formWidget.child, isA<Row>());
    final rowWidget = formWidget.child as Row;

    // Verify 3 Expanded columns inside the Row
    final expandedChildren = rowWidget.children.whereType<Expanded>().toList();
    expect(expandedChildren.length, equals(3));
    expect(expandedChildren[0].flex, equals(10)); // Leva
    expect(expandedChildren[1].flex, equals(11)); // Srednja
    expect(expandedChildren[2].flex, equals(10)); // Desna

    // Verify Desna kolona contains Description, SellerType, Promotion, and SubmitButton at the end
    expect(find.byType(ClassifiedDescriptionField), findsOneWidget);
    expect(find.byType(ClassifiedSellerTypeSection), findsOneWidget);
    expect(find.byType(ClassifiedPromotionSection), findsOneWidget);
    expect(find.byType(ClassifiedSubmitButton), findsOneWidget);
  });

  testWidgets('ClassifiedAdForm renders 1 column on mobile (width < 960)', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestWidget(screenSize: const Size(400, 800)));
    await tester.pumpAndSettle();

    // Verify no IntrinsicHeight on mobile
    expect(find.byType(IntrinsicHeight), findsNothing);

    // Verify SubmitButton still exists
    expect(find.byType(ClassifiedSubmitButton), findsOneWidget);
  });
}
