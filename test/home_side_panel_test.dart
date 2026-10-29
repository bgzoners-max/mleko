import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/home_products_data.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/services/orders/orders_service.dart';
import 'package:mleko/widgets/home/home_side_panel.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('TopProductsList formats sales as 10+ prodaja when count >= 10 and hides exact number below 10', (tester) async {
    final now = DateTime.now();
    final p1 = ProductModel(
      id: 'p1',
      sellerId: 's1',
      category: 'sir',
      name: 'Kajmak domaći',
      pricePerKg: 1200,
      minOrderKg: 0.5,
      availableKg: 20,
      description: '',
      imageUrls: const [],
      pickupOptions: const [],
      location: 'Čačak',
      createdAt: now,
    );

    final p2 = ProductModel(
      id: 'p2',
      sellerId: 's1',
      category: 'sir',
      name: 'Mladi sir',
      pricePerKg: 600,
      minOrderKg: 1,
      availableKg: 30,
      description: '',
      imageUrls: const [],
      pickupOptions: const [],
      location: 'Čačak',
      createdAt: now,
    );

    final data = (
      products: [p1, p2],
      salesCounts: {'p1': 14, 'p2': 3},
      ratings: <String, ({double avg, int count})>{},
    );

    final controller = StreamController<HomeProductsData>.broadcast();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState(ordersService: OrdersService())),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TopProductsList(
              homeProductsStream: controller.stream,
              initialData: data,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // p1 ima 14 prodaja -> mora prikazati '10+ prodaja'
    expect(find.text('10+ prodaja'), findsOneWidget);
    expect(find.text('14 prodaja'), findsNothing);

    // p2 ima 3 prodaje -> NE sme prikazati '3 prodaja', već cenu '600 din./kg'
    expect(find.text('3 prodaja'), findsNothing);
    expect(find.text('600 din./kg'), findsOneWidget);

    await controller.close();
  });

  testWidgets(
      'HomeSidePanel displays "Izdvajamo za vas" when no products have >= 10 sales (cold start)',
      (tester) async {
    final now = DateTime.now();
    final p1 = ProductModel(
      id: 'p1',
      sellerId: 's1',
      category: 'sir',
      name: 'Kajmak domaći',
      pricePerKg: 1200,
      minOrderKg: 0.5,
      availableKg: 20,
      description: '',
      imageUrls: const [],
      pickupOptions: const [],
      location: 'Čačak',
      createdAt: now,
    );

    final data = (
      products: [p1],
      salesCounts: {'p1': 4}, // < 10 prodaja (tek postavljeni proizvodi)
      ratings: <String, ({double avg, int count})>{},
    );

    final controller = StreamController<HomeProductsData>.broadcast();

    // Desktop/wide viewport
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => AppState(ordersService: OrdersService())),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: HomeSidePanel(
              homeProductsStream: controller.stream,
              initialData: data,
              isSeller: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Treba da prikazuje 'Izdvajamo za vas' a NE 'Najprodavaniji proizvodi'
    expect(find.text('Izdvajamo za vas'), findsOneWidget);
    expect(find.text('Najprodavaniji proizvodi'), findsNothing);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsNothing);

    await controller.close();
  });

  testWidgets(
      'HomeSidePanel displays "Najprodavaniji proizvodi" when at least one product has >= 10 sales',
      (tester) async {
    final now = DateTime.now();
    final p1 = ProductModel(
      id: 'p1',
      sellerId: 's1',
      category: 'sir',
      name: 'Kajmak domaći',
      pricePerKg: 1200,
      minOrderKg: 0.5,
      availableKg: 20,
      description: '',
      imageUrls: const [],
      pickupOptions: const [],
      location: 'Čačak',
      createdAt: now,
    );

    final data = (
      products: [p1],
      salesCounts: {'p1': 15}, // >= 10 prodaja
      ratings: <String, ({double avg, int count})>{},
    );

    final controller = StreamController<HomeProductsData>.broadcast();

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => AppState(ordersService: OrdersService())),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: HomeSidePanel(
              homeProductsStream: controller.stream,
              initialData: data,
              isSeller: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Treba da prikazuje 'Najprodavaniji proizvodi' sa ikonicom trending_up
    expect(find.text('Najprodavaniji proizvodi'), findsOneWidget);
    expect(find.text('Izdvajamo za vas'), findsNothing);
    expect(find.byIcon(Icons.trending_up), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsNothing);

    await controller.close();
  });

  testWidgets(
      'HomeSidePanel displays "Izdvajamo za vas" in TabBar on mobile when cold start',
      (tester) async {
    final now = DateTime.now();
    final p1 = ProductModel(
      id: 'p1',
      sellerId: 's1',
      category: 'sir',
      name: 'Kajmak domaći',
      pricePerKg: 1200,
      minOrderKg: 0.5,
      availableKg: 20,
      description: '',
      imageUrls: const [],
      pickupOptions: const [],
      location: 'Čačak',
      createdAt: now,
    );

    final data = (
      products: [p1],
      salesCounts: {'p1': 0},
      ratings: <String, ({double avg, int count})>{},
    );

    final controller = StreamController<HomeProductsData>.broadcast();

    // Mobile viewport
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => AppState(ordersService: OrdersService())),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: HomeSidePanel(
              homeProductsStream: controller.stream,
              initialData: data,
              isSeller: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tab bar treba da sadrži 'Izdvajamo za vas' i 'Omiljena gazdinstva'
    expect(find.widgetWithText(Tab, 'Izdvajamo za vas'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Najprodavaniji proizvodi'), findsNothing);
    expect(find.widgetWithText(Tab, 'Omiljena gazdinstva'), findsOneWidget);

    await controller.close();
  });
}
