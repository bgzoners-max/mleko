import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/widgets/home/favorite_farms_drawer.dart';

class _MockAppState extends ChangeNotifier implements AppState {
  @override
  UserModel? user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('showFavoriteFarmsDrawer opens slide-over drawer on desktop', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final appState = _MockAppState();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showFavoriteFarmsDrawer(context),
                child: const Text('Otvori'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Otvori'));
    await tester.pumpAndSettle();

    expect(find.text('Omiljena gazdinstva'), findsOneWidget);
    expect(find.text('Gazdinstva koja pratite i njihova ponuda'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Zatvaranje na klik
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Gazdinstva koja pratite i njihova ponuda'), findsNothing);
  });
}
