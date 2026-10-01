import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/providers/unread_notifications_provider.dart';
import 'package:mleko/services/auth/auth_service.dart';
import 'package:mleko/services/orders/orders_service.dart';

class _FakeAuthService extends Fake implements AuthService {
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  User? get currentSupabaseUser => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppState Auth Race & Debounce Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isCurrentAuthEvent rejects stale auth versions', () {
      final appState = AppState(
        ordersService: OrdersService(),
        authService: _FakeAuthService(),
      );

      final currentVer = appState.authEventVersion;

      // Stale authVersion should be rejected
      expect(
        appState.isCurrentAuthEvent(currentVer - 1, expectedUserId: null),
        isFalse,
      );

      // Mismatched expected user ID should be rejected
      expect(
        appState.isCurrentAuthEvent(currentVer, expectedUserId: 'mismatched-user-999'),
        isFalse,
      );
    });

    test('scheduleLoadUnreadCount cancels prior debounce timer and resets delay', () async {
      final appState = AppState(
        ordersService: OrdersService(),
        authService: _FakeAuthService(),
      );

      // Schedule first debounce
      appState.scheduleLoadUnreadCountForTesting(const Duration(milliseconds: 500));
      final timer1 = appState.unreadDebounceTimer;
      expect(timer1, isNotNull);
      expect(timer1!.isActive, isTrue);

      // Rapid subsequent event cancels timer1 and creates a new active timer
      appState.scheduleLoadUnreadCountForTesting(const Duration(milliseconds: 500));
      final timer2 = appState.unreadDebounceTimer;
      expect(timer2, isNotNull);
      expect(timer2!.isActive, isTrue);
      expect(timer1.isActive, isFalse, reason: 'Previous debounce timer must be cancelled');

      // Cleanup
      timer2.cancel();
    });

    test('setUserForTesting updates user and notifies listeners', () {
      final appState = AppState(
        ordersService: OrdersService(),
        authService: _FakeAuthService(),
      );

      var notified = 0;
      appState.addListener(() => notified++);

      const testUser = UserModel(
        id: 'usr-1',
        email: 'test@example.com',
        displayName: 'Marko Marković',
        isGuest: false,
      );

      appState.setUserForTesting(testUser);
      expect(appState.user?.id, equals('usr-1'));
      expect(appState.user?.displayName, equals('Marko Marković'));
      expect(notified, equals(1));

      // Setting to null (logout)
      appState.setUserForTesting(null);
      expect(appState.user, isNull);
      expect(notified, equals(2));
    });

    test('unread fasada delegira ka UnreadNotificationsProvider', () {
      final unread = UnreadNotificationsProvider();
      final appState = AppState(
        ordersService: OrdersService(),
        authService: _FakeAuthService(),
        unreadNotificationsProvider: unread,
      );

      var notified = 0;
      appState.addListener(() => notified++);

      // increment kroz fasadu -> vidljivo i na fasadi i na provideru
      appState.incrementUnreadCount();
      expect(appState.unreadNotificationCount, equals(1));
      expect(unread.unreadCount, equals(1));
      expect(notified, equals(1));

      // direktna promena na provideru -> fasada prosledjuje notify
      unread.incrementCount();
      expect(appState.unreadNotificationCount, equals(2));
      expect(notified, equals(2));

      appState.resetUnreadCount();
      expect(appState.unreadNotificationCount, equals(0));
      expect(unread.unreadCount, equals(0));

      // bind/unbind kroz fasadu ne baca bez Supabase (samo state deo se testira)
      unread.resetCount();
    });

    test('email verification flag management works correctly', () {
      final appState = AppState(
        ordersService: OrdersService(),
        authService: _FakeAuthService(),
      );

      var notified = 0;
      appState.addListener(() => notified++);

      appState.markPendingEmailVerification();
      // Does not notify yet
      expect(appState.justConfirmedEmail, isFalse);

      appState.clearJustConfirmedEmail();
      expect(notified, equals(1));
      expect(appState.justConfirmedEmail, isFalse);
    });
  });
}
