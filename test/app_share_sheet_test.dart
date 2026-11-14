import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/widgets/app_share_sheet.dart';

void main() {
  testWidgets('showAppShareSheet renders share options on mobile', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showAppShareSheet(
                  context,
                  title: 'Domaći kravlji sir',
                  url: 'https://www.domacimarket.rs/p/12345',
                  shareText: 'Domaći sir sa Zlatibora',
                );
              },
              child: const Text('Podeli'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Podeli'));
    await tester.pumpAndSettle();

    expect(find.text('Podeli ponudu'), findsOneWidget);
    expect(find.text('Domaći kravlji sir'), findsOneWidget);
    expect(find.text('https://www.domacimarket.rs/p/12345'), findsOneWidget);
    expect(find.text('Kopiraj link'), findsOneWidget);
    expect(find.text('Viber'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Više opcija'), findsOneWidget);
  });

  testWidgets('showAppShareSheet renders custom sheetTitle and URL dialog on desktop',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showAppShareSheet(
                  context,
                  title: 'Gazdinstvo Petrović',
                  url: 'https://www.domacimarket.rs/seller/seller-1',
                  shareText: 'Pogledaj gazdinstvo Petrović',
                  sheetTitle: 'Podeli profil',
                );
              },
              child: const Text('Podeli'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Podeli'));
    await tester.pumpAndSettle();

    expect(find.text('Podeli profil'), findsOneWidget);
    expect(find.text('Gazdinstvo Petrović'), findsOneWidget);
    expect(
      find.text('https://www.domacimarket.rs/seller/seller-1'),
      findsOneWidget,
    );
  });

  testWidgets('shareProduct and shareSellerProfile build expected share links',
      (tester) async {
    final now = DateTime.now();
    final product = ProductModel(
      id: 'prod-42',
      sellerId: 'sel-7',
      category: 'sir',
      name: 'Kajmak zlatiborski',
      pricePerKg: 1400,
      minOrderKg: 0.5,
      availableKg: 10,
      description: '',
      imageUrls: const [],
      pickupOptions: const [],
      location: 'Čajetina',
      createdAt: now,
    );
    const seller = UserModel(
      id: 'sel-7',
      email: 'sel@example.com',
      role: UserRole.seller,
      farmName: 'Gazdinstvo Kovačević',
      city: 'Čajetina',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => shareProduct(context, product),
                  child: const Text('Test proizvod'),
                ),
              ),
              Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => shareSellerProfile(context, seller),
                  child: const Text('Test profil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Test proizvod'));
    await tester.pumpAndSettle();
    expect(find.text('Podeli proizvod'), findsOneWidget);
    expect(find.text('https://www.domacimarket.rs/p/prod-42'), findsOneWidget);
    Navigator.of(tester.element(find.text('Podeli proizvod'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Test profil'));
    await tester.pumpAndSettle();
    expect(find.text('Podeli profil'), findsOneWidget);
    expect(find.text('https://www.domacimarket.rs/seller/sel-7'), findsOneWidget);
  });
}
