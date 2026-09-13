import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_settings_provider.dart';
import '../providers/app_state.dart';
import '../providers/cart_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/location_provider.dart';
import '../services/catalog/products_service.dart';
import '../services/communication/communication_services.dart';
import '../services/orders/order_services.dart';
import '../services/social/social_services.dart';
import '../services/auth/auth_services.dart';

import '../providers/classifieds_provider.dart';
import '../services/classifieds/classifieds_service.dart';
import '../services/classifieds/classified_reports_service.dart';

class AppProviders extends StatelessWidget {
  final Widget child;
  final AppState appState;
  final AppSettingsProvider appSettings;
  final CartProvider cartProvider;
  final CategoriesProvider categoriesProvider;
  final FavoritesProvider favoritesProvider;
  final LocationProvider locationProvider;
  final ClassifiedsProvider classifiedsProvider;
  final OrdersService ordersService;
  final ProductsService productsService;
  final ChatService chatService;
  final ReviewsService reviewsService;
  final UsersService usersService;
  final ClassifiedsService classifiedsService;
  final ClassifiedReportsService classifiedReportsService;

  const AppProviders({
    super.key,
    required this.child,
    required this.appState,
    required this.appSettings,
    required this.cartProvider,
    required this.categoriesProvider,
    required this.favoritesProvider,
    required this.locationProvider,
    required this.classifiedsProvider,
    required this.ordersService,
    required this.productsService,
    required this.chatService,
    required this.reviewsService,
    required this.usersService,
    required this.classifiedsService,
    required this.classifiedReportsService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<AppSettingsProvider>.value(value: appSettings),
        ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
        ChangeNotifierProvider<CategoriesProvider>.value(value: categoriesProvider),
        ChangeNotifierProvider<FavoritesProvider>.value(value: favoritesProvider),
        ChangeNotifierProvider<LocationProvider>.value(value: locationProvider),
        ChangeNotifierProvider<ClassifiedsProvider>.value(value: classifiedsProvider),
        Provider<OrdersService>.value(value: ordersService),
        Provider<ProductsService>.value(value: productsService),
        Provider<ChatService>.value(value: chatService),
        Provider<ReviewsService>.value(value: reviewsService),
        Provider<UsersService>.value(value: usersService),
        Provider<ClassifiedsService>.value(value: classifiedsService),
        Provider<ClassifiedReportsService>.value(value: classifiedReportsService),
      ],
      child: child,
    );
  }
}
