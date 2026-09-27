import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/categories_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/auth_confirmed_screen.dart';
import '../screens/home_screen.dart';
import '../screens/tab_search_or_products_screen.dart';
import '../screens/tab_orders_or_inbox_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/checkout_multi_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/seller/becoming_seller_screen.dart';
import '../screens/seller/add_edit_product_screen.dart';
import '../screens/seller/seller_profile_screen.dart';
import '../screens/seller/seller_reviews_screen.dart';
import '../screens/buyer_profile_screen.dart';
import '../screens/buyer/buyer_reviews_hub_screen.dart';
import '../screens/seller/seller_settings_screen.dart';
import '../screens/seller/map_picker_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/favorite_sellers_screen.dart';
import '../screens/sellers_map_screen.dart';
import '../screens/conversations_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/support_screen.dart';
import '../screens/support_ticket_chat_screen.dart';
import '../screens/admin/admin_tickets_screen.dart';
import '../screens/admin/admin_ticket_detail_screen.dart';
import '../screens/admin/admin_push_health_screen.dart';
import '../screens/admin/classifieds_moderation_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/child_categories_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_screen.dart';
import '../screens/about_screen.dart';
import '../screens/classifieds/classifieds_feed_screen.dart';
import '../screens/classifieds/classified_ad_detail_screen.dart';
import '../screens/classifieds/add_edit_classified_ad_screen.dart';
import '../screens/classifieds/my_classified_ads_screen.dart';
import '../screens/classifieds/saved_searches_screen.dart';
import '../models/category.dart';
import '../providers/app_settings_provider.dart';
import '../providers/app_state.dart';
import '../providers/classifieds_provider.dart';
import 'responsive.dart';
import 'web_seo.dart';
import '../widgets/theme_toggle_switch.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Pomoćna funkcija za premium tranzicije između ekrana i ažuriranje SEO metapodataka.
Page<T> buildPageTransition<T>({
  required GoRouterState state,
  required Widget child,
}) {
  applyRouteSeo(state.uri.path);
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Suptilna "Shared Axis" tranzicija (Fade + Slide + Scale)
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );

      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.03), // Blagi pomak odozdo
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      final scaleAnimation = Tween<double>(
        begin: 0.98, // Blago skaliranje
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

GoRouter createRouter(AppState appState) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: appState,
    initialLocation: kIsWeb ? '/' : '/splash',
    redirect: (context, state) {
      final loc = state.uri.path;
      if (appState.isLoading) return null;
      if (appState.user == null && !appState.authChecked) return null;

      if (loc == '/splash') return null;
      if (loc.startsWith('/onboarding')) return null;
      if (loc == '/verify-email') return null;
      if (loc == '/terms' ||
          loc == '/uslovi-koriscenja' ||
          loc == '/politika-privatnosti') {
        return null;
      }
      if (loc == '/about') return null;
      if (loc == '/support') return null;

      // Email just confirmed — steer to success screen before anything else
      if (appState.justConfirmedEmail && loc != '/auth/confirmed') {
        return '/auth/confirmed';
      }
      if (loc == '/auth/confirmed') return null;

      if (loc.startsWith('/login') || loc.startsWith('/register')) {
        if (appState.user != null && !appState.user!.isGuest) return '/';
        return null;
      }

      // Javne rute koje posetilac bez naloga (gost) može slobodno da pregleda
      final isPublicClassifiedRoute = loc.startsWith('/classifieds') &&
          !loc.startsWith('/classifieds/new') &&
          !loc.startsWith('/classifieds/edit') &&
          !loc.startsWith('/classifieds/my') &&
          !loc.startsWith('/classifieds/saved-searches');

      final isPublicRoute = loc == '/' ||
          loc.startsWith('/search') ||
          loc.startsWith('/product/') ||
          loc.startsWith('/categories') ||
          loc == '/sellers-map' ||
          loc == '/cart' ||
          loc == '/settings' ||
          isPublicClassifiedRoute ||
          (loc.startsWith('/seller/') && !loc.endsWith('/reviews'));

      if (isPublicRoute) {
        return null;
      }

      // Sve ostale rute (profil, porudžbine, dodavanje oglasa itd.) zahtevaju prijavu
      final isGuest = appState.user == null || appState.user!.isGuest;
      if (isGuest) {
        return '/login';
      }

      // Admin stranice — samo korisnici sa is_admin = true
      if (loc.startsWith('/admin/')) {
        final u = appState.user;
        if (u == null || !u.isAdmin) return '/';
      }

      // Stranica recenzija — samo vlasnik prodavnice (kupci i gosti na javni profil).
      final sellerReviewsMatch =
          RegExp(r'^/seller/([^/]+)/reviews$').firstMatch(loc);
      if (sellerReviewsMatch != null) {
        final sid = sellerReviewsMatch.group(1)!;
        final u = appState.user;
        if (u == null || u.isGuest || !u.isSeller || u.id != sid) {
          return '/seller/$sid';
        }
      }

      final buyerReviewsMatch =
          RegExp(r'^/buyer/([^/]+)/reviews$').firstMatch(loc);
      if (buyerReviewsMatch != null) {
        final bid = buyerReviewsMatch.group(1)!;
        final u = appState.user;
        if (u == null || u.isGuest || u.isSeller || u.id != bid) {
          return '/buyer/$bid';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: TabSearchOrProductsScreen(
            initialCategory: state.uri.queryParameters['category'],
            openSellerProducts: state.uri.queryParameters['view'] == 'products',
          ),
        ),
      ),
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/becoming-seller',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const BecomingSellerScreen(),
        ),
      ),
      GoRoute(
        path: '/seller-settings',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const SellerSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/map-picker',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return buildPageTransition(
            state: state,
            child: MapPickerScreen(
              initialLat: (extra?['lat'] as num?)?.toDouble(),
              initialLng: (extra?['lng'] as num?)?.toDouble(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/add-product',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const AddEditProductScreen(),
        ),
      ),
      GoRoute(
        path: '/product/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final scrollToReviews = state.uri.queryParameters['reviews'] == '1';
          return buildPageTransition(
            state: state,
            child: ProductDetailScreen(
              productId: id,
              scrollToReviews: scrollToReviews,
            ),
          );
        },
      ),
      GoRoute(
        path: '/checkout/:productId',
        pageBuilder: (context, state) {
          final id = state.pathParameters['productId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final initialQty = (extra?['quantity'] as num?)?.toDouble();
          return buildPageTransition(
            state: state,
            child: CheckoutScreen(productId: id, initialQuantity: initialQty),
          );
        },
      ),
      GoRoute(
        path: '/checkout-seller/:sellerId',
        pageBuilder: (context, state) {
          final sellerId = state.pathParameters['sellerId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final productQuantities =
              extra?['productQuantities'] as Map<String, double>? ?? {};
          return buildPageTransition(
            state: state,
            child: CheckoutMultiScreen(
                sellerId: sellerId, productQuantities: productQuantities),
          );
        },
      ),
      GoRoute(
        path: '/product/edit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return buildPageTransition(
            state: state,
            child: AddEditProductScreen(productId: id),
          );
        },
      ),
      GoRoute(
        path: '/seller/:sellerId/reviews',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['sellerId']!;
          return buildPageTransition(
            state: state,
            child: SellerReviewsScreen(sellerId: id),
          );
        },
      ),
      GoRoute(
        path: '/seller/:sellerId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['sellerId']!;
          return buildPageTransition(
            state: state,
            child: SellerProfileScreen(sellerId: id),
          );
        },
      ),
      GoRoute(
        path: '/buyer/:buyerId/reviews',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['buyerId']!;
          return buildPageTransition(
            state: state,
            child: BuyerReviewsHubScreen(buyerId: id),
          );
        },
      ),
      GoRoute(
        path: '/buyer/:buyerId',
        pageBuilder: (context, state) {
          final id = state.pathParameters['buyerId']!;
          return buildPageTransition(
            state: state,
            child: BuyerProfileScreen(buyerId: id),
          );
        },
      ),
      GoRoute(
        path: '/cart',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const CartScreen(),
        ),
      ),
      GoRoute(
        path: '/favorites',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const FavoritesScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/support',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const SupportScreen(),
        ),
      ),
      GoRoute(
        path: '/support/ticket/:id',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: SupportTicketChatScreen(
            ticketId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/admin/tickets',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const AdminTicketsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/tickets/:id',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: AdminTicketDetailScreen(ticketId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/admin/push-health',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const AdminPushHealthScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/classifieds',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const ClassifiedsModerationScreen(),
        ),
      ),
      GoRoute(
        path: '/favorite-sellers',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const FavoriteSellersScreen(),
        ),
      ),
      GoRoute(
        path: '/politika-privatnosti',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const PrivacyPolicyScreen(),
        ),
      ),
      GoRoute(
        path: '/uslovi-koriscenja',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const TermsScreen(),
        ),
      ),
      GoRoute(
        path: '/terms',
        redirect: (_, __) => '/uslovi-koriscenja',
      ),
      GoRoute(
        path: '/about',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const AboutScreen(),
        ),
      ),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: VerifyEmailScreen(
            email: (state.extra as String?) ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/auth/confirmed',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const AuthConfirmedScreen(),
        ),
      ),
      GoRoute(
        path: '/sellers-map',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const SellersMapScreen(),
        ),
      ),
      GoRoute(
        path: '/categories',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const CategoriesScreen(),
        ),
      ),
      GoRoute(
        path: '/categories/:parentId',
        pageBuilder: (context, state) {
          final parentId = state.pathParameters['parentId'];
          final extra = state.extra;
          var parent = extra is Category
              ? extra
              : extra is Map<String, dynamic>
                  ? Category.fromJson(extra)
                  : null;
          if (parent == null && parentId != null) {
            final categories = context.read<CategoriesProvider>().categories;
            parent = categories?.where((c) => c.id == parentId).firstOrNull;
          }
          if (parent == null) {
            return buildPageTransition(
              state: state,
              child: const CategoriesScreen(),
            );
          }
          return buildPageTransition(
            state: state,
            child: ChildCategoriesScreen(parentCategory: parent),
          );
        },
      ),
      GoRoute(
        path: '/conversations',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const ConversationsScreen(),
        ),
      ),
      GoRoute(
        path: '/chat/:id',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: ChatScreen(conversationId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/classifieds',
        pageBuilder: (context, state) {
          final categoryId = state.uri.queryParameters['category'];
          return buildPageTransition(
            state: state,
            child: ClassifiedsFeedScreen(initialCategoryId: categoryId),
          );
        },
      ),
      GoRoute(
        path: '/classifieds/ad/:id',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: ClassifiedAdDetailScreen(adId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/classifieds/new',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const AddEditClassifiedAdScreen(),
        ),
      ),
      GoRoute(
        path: '/classifieds/edit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: AddEditClassifiedAdScreen(adId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/classifieds/my',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const MyClassifiedAdsScreen(),
        ),
      ),
      GoRoute(
        path: '/classifieds/saved-searches',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const SavedSearchesScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Buyer shell
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) => buildPageTransition(
                  state: state,
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                pageBuilder: (context, state) => buildPageTransition(
                  state: state,
                  child: const TabOrdersOrInboxScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => buildPageTransition(
                  state: state,
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  static const _destinations = [
    (icon: Icons.cottage, label: 'Početna'),
    (icon: Icons.receipt_long, label: 'Porudžbine'),
    (icon: Icons.person, label: 'Profil'),
  ];

  static const _guestDestinations = [
    (icon: Icons.cottage, label: 'Početna'),
    (icon: Icons.login_rounded, label: 'Prijavi se'),
  ];

  void _onDestinationSelected(BuildContext context, int i, {required bool isGuest}) {
    if (isGuest) {
      if (i == 0) {
        context.read<AppSettingsProvider>().setMarketMode(MarketMode.foodMarket);
        context.read<ClassifiedsProvider>().clearFilters();
        navigationShell.goBranch(0, initialLocation: true);
        context.go('/');
      } else {
        context.push('/login');
      }
      return;
    }

    if (i == 0) {
      context.read<AppSettingsProvider>().setMarketMode(MarketMode.foodMarket);
      context.read<ClassifiedsProvider>().clearFilters();
      navigationShell.goBranch(0, initialLocation: true);
      context.go('/');
    } else {
      navigationShell.goBranch(i, initialLocation: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final isGuest = user == null || user.isGuest;
    final destinations = isGuest ? _guestDestinations : _destinations;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= Breakpoints.phone;
    final selectedDestIndex = isGuest
        ? 0
        : navigationShell.currentIndex.clamp(0, destinations.length - 1);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedDestIndex,
              onDestinationSelected: (i) =>
                  _onDestinationSelected(context, i, isGuest: isGuest),
              labelType: NavigationRailLabelType.all,
              trailing: const Padding(
                padding: EdgeInsets.only(top: 24),
                child: ThemeToggleSwitch(),
              ),
              destinations: destinations.map((d) {
                return NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                );
              }).toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: navigationShell,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedDestIndex,
        onDestinationSelected: (i) =>
            _onDestinationSelected(context, i, isGuest: isGuest),
        destinations: destinations.map((d) {
          return NavigationDestination(
            icon: Icon(d.icon),
            label: d.label,
          );
        }).toList(),
      ),
    );
  }
}
