import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mleko/core/router_guard.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/providers/app_state.dart';

class _FakeGoRouterState extends Fake implements GoRouterState {
  @override
  final Uri uri;

  _FakeGoRouterState(String path) : uri = Uri.parse(path);
}

class _FakeBuildContext extends Fake implements BuildContext {}

class _FakeAppState extends Fake implements AppState {
  @override
  UserModel? user;

  @override
  bool authChecked = true;

  @override
  bool isLoading = false;

  @override
  bool justConfirmedEmail = false;
}

void main() {
  late _FakeAppState appState;
  final context = _FakeBuildContext();

  setUp(() {
    appState = _FakeAppState();
  });

  group('RouterGuard - routerRedirect', () {
    test('public unauthenticated routes return null', () {
      final publicRoutes = [
        '/',
        '/splash',
        '/onboarding',
        '/verify-email',
        '/terms',
        '/uslovi-koriscenja',
        '/politika-privatnosti',
        '/about',
        '/vodic-za-proizvodjace',
        '/support',
        '/search',
        '/search?q=sir',
        '/product/prod-123',
        '/p/p123',
        '/ad/ad456',
        '/categories',
        '/sellers-map',
        '/cart',
        '/settings',
        '/auth/confirm',
        '/classifieds',
        '/classifieds/traktori',
        '/seller/seller-123',
      ];

      for (final route in publicRoutes) {
        final result = routerRedirect(context, _FakeGoRouterState(route), appState);
        expect(result, isNull, reason: 'Route $route should be accessible by anyone');
      }
    });

    test('redirects to /auth/confirmed when email was just confirmed', () {
      appState.justConfirmedEmail = true;

      final res1 = routerRedirect(context, _FakeGoRouterState('/'), appState);
      expect(res1, '/auth/confirmed');

      final res2 = routerRedirect(context, _FakeGoRouterState('/auth/confirmed'), appState);
      expect(res2, isNull);
    });

    test('redirects to splash when auth is not checked or loading', () {
      appState.authChecked = false;

      final res = routerRedirect(context, _FakeGoRouterState('/orders'), appState);
      expect(res, '/splash?returnTo=%2Forders');

      appState
        ..authChecked = true
        ..isLoading = true;

      final resLoading = routerRedirect(context, _FakeGoRouterState('/profile'), appState);
      expect(resLoading, '/splash?returnTo=%2Fprofile');
    });

    test('handles /splash with returnTo: stays while loading, redirects once auth is checked', () {
      appState
        ..authChecked = false
        ..isLoading = false;

      final resPending = routerRedirect(
        context,
        _FakeGoRouterState('/splash?returnTo=%2Fprofile'),
        appState,
      );
      expect(resPending, isNull);

      appState.authChecked = true;
      final resReady = routerRedirect(
        context,
        _FakeGoRouterState('/splash?returnTo=%2Fprofile'),
        appState,
      );
      expect(resReady, '/profile');
    });

    test('redirects guest to /login?returnTo=... on protected routes', () {
      appState
        ..authChecked = true
        ..isLoading = false
        ..user = null; // guest

      final protectedRoutes = [
        '/orders',
        '/profile',
        '/classifieds/new',
        '/classifieds/edit/123',
        '/classifieds/my',
        '/classifieds/saved-searches',
      ];

      for (final route in protectedRoutes) {
        final encoded = Uri.encodeComponent(route);
        final res = routerRedirect(context, _FakeGoRouterState(route), appState);
        expect(res, '/login?returnTo=$encoded');
      }
    });

    test('redirects logged-in non-guest user from login and register to /', () {
      appState.user = const UserModel(
        id: 'user-1',
        email: 'user@test.rs',
        role: UserRole.buyer,
        isGuest: false,
      );

      final loginRes = routerRedirect(context, _FakeGoRouterState('/login'), appState);
      expect(loginRes, '/');

      final regRes = routerRedirect(context, _FakeGoRouterState('/register'), appState);
      expect(regRes, '/');
    });

    test('admin routes guard: non-admin is redirected to /', () {
      appState.user = const UserModel(
        id: 'user-1',
        email: 'user@test.rs',
        role: UserRole.buyer,
        isAdmin: false,
      );

      final res = routerRedirect(context, _FakeGoRouterState('/admin/push-health'), appState);
      expect(res, '/');
    });

    test('admin routes guard: admin user is allowed', () {
      appState.user = const UserModel(
        id: 'admin-1',
        email: 'admin@domacimarket.rs',
        role: UserRole.buyer,
        isAdmin: true,
      );

      final res = routerRedirect(context, _FakeGoRouterState('/admin/push-health'), appState);
      expect(res, isNull);
    });

    test('seller reviews route: only owning seller is allowed', () {
      appState.user = const UserModel(
        id: 'seller-mine',
        role: UserRole.seller,
      );

      // Own reviews -> allowed
      final ownRes = routerRedirect(
        context,
        _FakeGoRouterState('/seller/seller-mine/reviews'),
        appState,
      );
      expect(ownRes, isNull);

      // Other seller's reviews -> redirected to their public profile
      final otherRes = routerRedirect(
        context,
        _FakeGoRouterState('/seller/seller-other/reviews'),
        appState,
      );
      expect(otherRes, '/seller/seller-other');
    });

    test('buyer reviews route: only owning buyer is allowed', () {
      appState.user = const UserModel(
        id: 'buyer-mine',
        role: UserRole.buyer,
      );

      // Own reviews -> allowed
      final ownRes = routerRedirect(
        context,
        _FakeGoRouterState('/buyer/buyer-mine/reviews'),
        appState,
      );
      expect(ownRes, isNull);

      // Other buyer's reviews -> redirected to their public profile
      final otherRes = routerRedirect(
        context,
        _FakeGoRouterState('/buyer/buyer-other/reviews'),
        appState,
      );
      expect(otherRes, '/buyer/buyer-other');
    });
  });
}
