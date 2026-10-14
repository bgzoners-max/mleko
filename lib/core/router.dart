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
import '../screens/auth/auth_confirm_screen.dart';
import '../screens/auth/auth_confirmed_screen.dart';
import '../screens/home_screen.dart';
import '../screens/tab_search_or_products_screen.dart';
import '../screens/tab_orders_or_inbox_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/checkout_multi_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/seller/becoming_seller_screen.dart';
import '../screens/seller/seller_dashboard_screen.dart';
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
import '../providers/app_state.dart';
import '../widgets/navigation/main_shell.dart';
import '../widgets/app_back_button.dart';
import 'router_guard.dart';
import 'router_transitions.dart';

export '../widgets/navigation/main_shell.dart';
export 'router_guard.dart';
export 'router_transitions.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Pomoćna funkcija za premium tranzicije između ekrana i ažuriranje SEO metapodataka.
///
/// Poštuje sistemsko smanjenje animacija (pristupačnost): kada je na uređaju
/// uključeno "Remove animations" / "Reduce motion", vraća običnu stranicu
/// bez Fade+Slide+Scale tranzicije.
GoRouter createRouter(AppState appState) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: appState,
    initialLocation: kIsWeb ? '/' : '/splash',
    redirect: (context, state) => routerRedirect(context, state, appState),
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Stranica nije pronađena'),
        leading: const AppBackButton(fallbackRoute: '/'),
        actions: const [AppHomeButton()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Tražena stranica ne postoji ili je premeštena.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Početna stranica'),
              ),
            ],
          ),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: TabSearchOrProductsScreen(
            initialCategory: state.uri.queryParameters['category'],
            initialQuery: state.uri.queryParameters['q'],
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
        path: '/seller-dashboard',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const SellerDashboardScreen(),
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
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const EditProfileScreen(),
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
        path: '/auth/confirm',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: AuthConfirmScreen(
            tokenHash: state.uri.queryParameters['token_hash'],
            type: state.uri.queryParameters['type'],
            next: state.uri.queryParameters['next'],
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
        path: '/chat/:id',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: ChatScreen(conversationId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/ad/:id',
        redirect: (context, state) {
          final id = state.pathParameters['id'];
          final query = state.uri.hasQuery ? '?${state.uri.query}' : '';
          return '/classifieds/ad/$id$query';
        },
      ),
      GoRoute(
        path: '/p/:id',
        redirect: (context, state) {
          final id = state.pathParameters['id'];
          final query = state.uri.hasQuery ? '?${state.uri.query}' : '';
          return '/product/$id$query';
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
          // TAB 1: Pocetna (buyer/seller home + product/checkout/cart/search detalji)
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
          // TAB 2: Oglasi (ranije skriveni u MarketMode switcheru)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/classifieds',
                pageBuilder: (context, state) {
                  final categoryId = state.uri.queryParameters['category'];
                  return buildPageTransition(
                    state: state,
                    child: ClassifiedsFeedScreen(
                        initialCategoryId: categoryId),
                  );
                },
              ),
            ],
          ),
          // TAB 3: Porudzbine / Inbox (prodavac: inbox, kupac: porudzbine)
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
          // TAB 4: Poruke
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/conversations',
                pageBuilder: (context, state) => buildPageTransition(
                  state: state,
                  child: const ConversationsScreen(),
                ),
              ),
            ],
          ),
          // TAB 5: Profil
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
