import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/category.dart';
import 'package:mleko/models/home_products_data.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/services/services.dart';
import 'package:mleko/widgets/home/home_narrow_top_section.dart';
import 'package:mleko/widgets/home/home_side_panel.dart';
import 'package:mleko/widgets/home/map_card.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
      'HomeNarrowTopSection places full-width MapCard above balanced HomeSidePanel on tablet',
      (tester) async {
    final now = DateTime.now();
    final categories = List.generate(
      8,
      (i) => Category(id: 'c$i', name: 'Kategorija $i', order: i),
    );
    final products = List.generate(
      3,
      (i) => ProductModel(
        id: 'p$i',
        sellerId: 's1',
        category: 'sir',
        name: 'Proizvod $i',
        pricePerKg: 500 + i * 100.0,
        minOrderKg: 0.5,
        availableKg: 10,
        description: '',
        imageUrls: const [],
        pickupOptions: const [],
        location: 'Novi Sad',
        createdAt: now,
      ),
    );

    final data = (
      products: products,
      salesCounts: <String, int>{},
      ratings: <String, ({double avg, int count})>{},
    );
    final controller = StreamController<HomeProductsData>.broadcast();

    tester.view.physicalSize = const Size(1000, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AppState(ordersService: OrdersService()),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: HomeNarrowTopSection(
                topCategories: categories,
                isTabletLayout: true,
                isLargeTablet: false,
                compactSpacing: 6,
                sectionSpacing: 12,
                stream: controller.stream,
                latestHomeData: data,
                isSeller: false,
                selectedRegion: null,
                categoryHeader: const Text('Kategorije hrane'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final mapFinder = find.byType(MapCard);
    final sidePanelFinder = find.byType(HomeSidePanel);

    expect(mapFinder, findsOneWidget);
    expect(sidePanelFinder, findsOneWidget);
    expect(find.byType(SidePanelCard), findsNWidgets(2));
    expect(find.text('Otvori mapu'), findsOneWidget);

    final mapRect = tester.getRect(mapFinder);
    final panelRect = tester.getRect(sidePanelFinder);

    expect(mapRect.bottom, lessThanOrEqualTo(panelRect.top));
    expect(mapRect.width, closeTo(panelRect.width, 1.0));

    await controller.close();
  });
}

