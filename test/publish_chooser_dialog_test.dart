import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/services/services.dart';
import 'package:mleko/widgets/navigation/publish_chooser_dialog.dart';
import 'package:provider/provider.dart';

void main() {
  Widget buildTestWidget({
    required AppState appState,
    bool isBottomSheet = false,
  }) {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        home: Scaffold(
          body: PublishChooserDialog(isBottomSheet: isBottomSheet),
        ),
      ),
    );
  }

  group('PublishChooserDialog', () {
    testWidgets('renders dialog title and both publishing options',
        (tester) async {
      final appState = AppState(ordersService: OrdersService());

      await tester.pumpWidget(buildTestWidget(appState: appState));

      // Verify title & subtitle
      expect(find.text('Šta želite da ponudite?'), findsOneWidget);
      expect(
        find.text(
            'Izaberite gde pripada vaša ponuda kako bi vas pravi kupci pronašli:'),
        findsOneWidget,
      );

      // Verify Food Option
      expect(find.text('Pijaca & Gazdinstva'), findsOneWidget);
      expect(find.text('Domaća hrana'), findsOneWidget);
      expect(find.text('Dodaj hranu na Pijacu'), findsOneWidget);

      // Verify Classifieds Option
      expect(find.text('Mali oglasnik'), findsOneWidget);
      expect(find.text('Mali oglasi (Sve ostalo)'), findsOneWidget);
      expect(find.text('Postavi mali oglas'), findsOneWidget);
    });

    testWidgets('renders in BottomSheet layout properly', (tester) async {
      final appState = AppState(ordersService: OrdersService());

      await tester.pumpWidget(
        buildTestWidget(appState: appState, isBottomSheet: true),
      );

      expect(find.text('Šta želite da ponudite?'), findsOneWidget);
      expect(find.text('Domaća hrana'), findsOneWidget);
      expect(find.text('Mali oglasi (Sve ostalo)'), findsOneWidget);
    });

    testWidgets(
        'food option mentions food items and classifieds mentions electronics/watches/pets',
        (tester) async {
      final appState = AppState(ordersService: OrdersService());

      await tester.pumpWidget(buildTestWidget(appState: appState));

      // Check food keywords
      expect(
        find.textContaining('Sir, kajmak, mleko, med'),
        findsOneWidget,
      );

      // Check classifieds keywords
      expect(
        find.textContaining('Satovi, laptopovi, mobilni telefoni'),
        findsOneWidget,
      );
    });

    testWidgets(
        'calling showPublishChooserDialog opens dialog with both options',
        (tester) async {
      final appState = AppState(ordersService: OrdersService());

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showPublishChooserDialog(context),
                  child: const Text('Postavi oglas'),
                ),
              ),
            ),
          ),
        ),
      );

      final postButton = find.widgetWithText(ElevatedButton, 'Postavi oglas');
      expect(postButton, findsOneWidget);

      await tester.tap(postButton);
      await tester.pumpAndSettle();

      expect(find.byType(PublishChooserDialog), findsOneWidget);
      expect(find.text('Šta želite da ponudite?'), findsOneWidget);
      expect(find.text('Domaća hrana'), findsOneWidget);
      expect(find.text('Mali oglasi (Sve ostalo)'), findsOneWidget);
    });
  });
}
