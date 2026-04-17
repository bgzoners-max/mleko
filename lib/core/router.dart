import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
import '../screens/categories_screen.dart';
import '../screens/child_categories_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_screen.dart';
import '../screens/about_screen.dart';
import '../screens/landing_screen.dart';
import '../models/category.dart';
import '../providers/app_state.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AppState appState) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: appState,
    initialLocation: '/splash',
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
      if (loc == '/landing') return null;

      // Email just confirmed — steer to success screen before anything else
      if (appState.justConfirmedEmail && loc != '/auth/confirmed') {
        return '/auth/confirmed';
      }
      if (loc == '/auth/confirmed') return null;

      if (loc.startsWith('/login') || loc.startsWith('/register')) {
        if (appState.user != null) return '/';
        return null;
      }
      if (appState.user == null &&
          !loc.startsWith('/login') &&
          !loc.startsWith('/register') &&
          !loc.startsWith('/onboarding') &&
          loc != '/landing') {
        return '/landing';
      }

      // Gost (anonymous) može samo da gleda proizvode, ne i da naručuje
      // niti da postane prodavac.
      final isGuest = appState.user?.isGuest ?? false;
      if (isGuest) {
        if (loc.startsWith('/becoming-seller') ||
            loc.startsWith('/seller-settings') ||
            loc.startsWith('/settings') ||
            loc.startsWith('/add-product') ||
            loc.startsWith('/product/edit') ||
            loc.startsWith('/favorites') ||
            loc.startsWith('/favorite-sellers') ||
            loc.startsWith('/notifications') ||
            loc.startsWith('/conversations') ||
            loc.startsWith('/chat/') ||
            loc.startsWith('/buyer/')) {
          return '/login';
        }
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
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/becoming-seller',
        builder: (_, __) => const BecomingSellerScreen(),
      ),
      GoRoute(
        path: '/seller-settings',
        builder: (_, __) => const SellerSettingsScreen(),
      ),
      GoRoute(
        path: '/map-picker',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MapPickerScreen(
            initialLat: (extra?['lat'] as num?)?.toDouble(),
            initialLng: (extra?['lng'] as num?)?.toDouble(),
          );
        },
      ),
      GoRoute(
        path: '/add-product',
        builder: (_, __) => const AddEditProductScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          final scrollToReviews = state.uri.queryParameters['reviews'] == '1';
          return ProductDetailScreen(
            productId: id,
            scrollToReviews: scrollToReviews,
          );
        },
      ),
      GoRoute(
        path: '/checkout/:productId',
        builder: (_, state) {
          final id = state.pathParameters['productId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final initialQty = (extra?['quantity'] as num?)?.toDouble();
          return CheckoutScreen(productId: id, initialQuantity: initialQty);
        },
      ),
      GoRoute(
        path: '/checkout-seller/:sellerId',
        builder: (_, state) {
          final sellerId = state.pathParameters['sellerId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final productQuantities =
              extra?['productQuantities'] as Map<String, double>? ?? {};
          return CheckoutMultiScreen(
              sellerId: sellerId, productQuantities: productQuantities);
        },
      ),
      GoRoute(
        path: '/product/edit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return AddEditProductScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/seller/:sellerId/reviews',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final id = state.pathParameters['sellerId']!;
          return SellerReviewsScreen(sellerId: id);
        },
      ),
      GoRoute(
        path: '/seller/:sellerId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final id = state.pathParameters['sellerId']!;
          return SellerProfileScreen(sellerId: id);
        },
      ),
      GoRoute(
        path: '/buyer/:buyerId/reviews',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final id = state.pathParameters['buyerId']!;
          return BuyerReviewsHubScreen(buyerId: id);
        },
      ),
      GoRoute(
        path: '/buyer/:buyerId',
        builder: (_, state) {
          final id = state.pathParameters['buyerId']!;
          return BuyerProfileScreen(buyerId: id);
        },
      ),
      GoRoute(
        path: '/cart',
        redirect: (_, __) => '/orders',
      ),
      GoRoute(
        path: '/favorites',
        builder: (_, __) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (_, __) => const SupportScreen(),
      ),
      GoRoute(
        path: '/support/ticket/:id',
        builder: (_, state) => SupportTicketChatScreen(
          ticketId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/admin/tickets',
        builder: (_, __) => const AdminTicketsScreen(),
      ),
      GoRoute(
        path: '/admin/tickets/:id',
        builder: (_, state) =>
            AdminTicketDetailScreen(ticketId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/push-health',
        builder: (_, __) => const AdminPushHealthScreen(),
      ),
      GoRoute(
        path: '/favorite-sellers',
        builder: (_, __) => const FavoriteSellersScreen(),
      ),
      GoRoute(
        path: '/politika-privatnosti',
        builder: (_, __) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/uslovi-koriscenja',
        builder: (_, __) => const TermsScreen(),
      ),
      GoRoute(
        path: '/terms',
        redirect: (_, __) => '/uslovi-koriscenja',
      ),
      GoRoute(
        path: '/about',
        builder: (_, __) => const AboutScreen(),
      ),
      GoRoute(
        path: '/landing',
        builder: (_, __) => const LandingScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) => VerifyEmailScreen(
          email: (state.extra as String?) ?? '',
        ),
      ),
      GoRoute(
        path: '/auth/confirmed',
        builder: (_, __) => const AuthConfirmedScreen(),
      ),
      GoRoute(
        path: '/sellers-map',
        builder: (_, __) => const SellersMapScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (_, __) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/categories/:parentId',
        builder: (_, state) {
          final extra = state.extra;
          final parent = extra is Category
              ? extra
              : extra is Map<String, dynamic>
                  ? Category.fromJson(extra)
                  : null;
          if (parent == null) {
            return const CategoriesScreen();
          }
          return ChildCategoriesScreen(parentCategory: parent);
        },
      ),
      GoRoute(
        path: '/conversations',
        builder: (_, __) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, state) =>
            ChatScreen(conversationId: state.pathParameters['id']!),
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
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (_, state) => TabSearchOrProductsScreen(
                  initialCategory: state.uri.queryParameters['category'],
                  openSellerProducts:
                      state.uri.queryParameters['view'] == 'products',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (_, __) => const TabOrdersOrInboxScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
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

  static const _sellerDestinations = [
    (icon: Icons.cottage, label: 'Home'),
    (icon: Icons.inventory_2, label: 'Moji proizvodi'),
    (icon: Icons.receipt_long, label: 'Porudžbine'),
    (icon: Icons.person, label: 'Profil'),
  ];
  static const _buyerDestinations = [
    (icon: Icons.cottage, label: 'Home'),
    (icon: Icons.search, label: 'Pretraga'),
    (icon: Icons.receipt_long, label: 'Porudžbine'),
    (icon: Icons.person, label: 'Profil'),
  ];

  /// Branches: 0=Home, 1=Search/Proizvodi, 2=Orders, 3=Profile.
  int _destIndexToBranch(int i, bool isSeller) {
    return i;
  }

  int _branchToDestIndex(int branch, bool isSeller) {
    return branch.clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isSeller = appState.user?.isSeller ?? false;
    final dest = isSeller ? _sellerDestinations : _buyerDestinations;
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final selectedDestIndex =
        _branchToDestIndex(navigationShell.currentIndex, isSeller);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedDestIndex,
              onDestinationSelected: (i) {
                if (isSeller && i == 1) {
                  context.go('/search?view=products');
                  return;
                }
                navigationShell.goBranch(
                  _destIndexToBranch(i, isSeller),
                  initialLocation: true,
                );
              },
              labelType: NavigationRailLabelType.all,
              destinations: dest.asMap().entries.map((e) {
                final d = e.value;
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
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedDestIndex,
        onDestinationSelected: (i) {
          if (isSeller && i == 1) {
            context.go('/search?view=products');
            return;
          }
          navigationShell.goBranch(
            _destIndexToBranch(i, isSeller),
            initialLocation: true,
          );
        },
        destinations: dest.asMap().entries.map((e) {
          final d = e.value;
          return NavigationDestination(
            icon: Icon(d.icon),
            label: d.label,
          );
        }).toList(),
      ),
    );
  }
}
