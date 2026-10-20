import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mleko/models/app_error.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/services/auth/auth_service.dart';
import 'package:mleko/services/auth/users_service.dart';

/// Fake gotrue (auth) klijent — beleži pozive i simulira ponašanje Supabase
/// Auth API-ja bez mreže. Neprepoznati pozivi padaju kroz [noSuchMethod].
class _FakeAuthClient implements GoTrueClient {
  _FakeAuthClient({User? user}) : _user = user;

  User? _user;
  Object? signInError;
  Object? signUpError;
  Object? resendError;
  Object? resetError;

  final List<Map<String, Object?>> signInCalls = [];
  final List<Map<String, Object?>> signUpCalls = [];
  final List<Map<String, Object?>> resendCalls = [];
  final List<Map<String, Object?>> resetCalls = [];
  int signOutCount = 0;

  @override
  User? get currentUser => _user;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    signInCalls.add({'email': email, 'password': password});
    if (signInError != null) throw signInError!;
    return AuthResponse();
  }

  @override
  Future<AuthResponse> signUp({
    String? email,
    String? phone,
    required String password,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    signUpCalls.add({
      'email': email,
      'password': password,
      'emailRedirectTo': emailRedirectTo,
      'data': data,
    });
    if (signUpError != null) throw signUpError!;
    return AuthResponse();
  }

  @override
  Future<ResendResponse> resend({
    String? email,
    String? phone,
    required OtpType type,
    String? emailRedirectTo,
    String? captchaToken,
  }) async {
    resendCalls.add({
      'email': email,
      'type': type,
      'emailRedirectTo': emailRedirectTo,
    });
    if (resendError != null) throw resendError!;
    return ResendResponse();
  }

  @override
  Future<void> resetPasswordForEmail(
    String email, {
    String? redirectTo,
    String? captchaToken,
  }) async {
    resetCalls.add({'email': email, 'redirectTo': redirectTo});
    if (resetError != null) throw resetError!;
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    signOutCount++;
    _user = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake Supabase klijent koji vraća [_FakeAuthClient] za `.auth`; ostali
/// pozivi padaju kroz [noSuchMethod] (testovi namerno ne dodiruju REST sloj).
class _FakeSupabaseClient implements SupabaseClient {
  _FakeSupabaseClient(this._auth);

  final _FakeAuthClient _auth;

  @override
  GoTrueClient get auth => _auth;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Sentinel {
  const _Sentinel();
}

const _sentinel = _Sentinel();

/// Fake UsersService — vraća profil po želji i beleži upsert pozive.
class _FakeUsersService implements UsersService {
  UserModel? profile;
  Object? getUserError;

  final List<Map<String, Object?>> upsertCalls = [];

  @override
  Future<UserModel?> getUser(String userId) async {
    if (getUserError != null) throw getUserError!;
    return profile;
  }

  @override
  Future<void> upsertProfile(
    String userId, {
    String? email,
    Object? displayName = _sentinel,
    Object? phone = _sentinel,
    Object? city = _sentinel,
    Object? postalCode = _sentinel,
    Object? address = _sentinel,
    String? role,
    bool? isGuest,
    Object? farmName = _sentinel,
    Object? location = _sentinel,
    Object? profileImageUrl = _sentinel,
    double? lat,
    double? lng,
    bool? phonePublic,
    Object? sellerStory = _sentinel,
    List<String>? farmGalleryUrls,
    List<String>? sellerTags,
    List<String>? sellerQuickReplies,
  }) async {
    upsertCalls.add({
      'userId': userId,
      'role': role,
      'isGuest': isGuest,
      'farmName': identical(farmName, _sentinel) ? null : farmName,
      'location': identical(location, _sentinel) ? null : location,
      'phone': identical(phone, _sentinel) ? null : phone,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// HTTP klijent koji presreće sve zahteve ka (lažnom) Supabase REST API-ju —
/// isti obrazac kao u order_query_mixin_test.dart.
class MockHttpHandlerClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request, String body)
      handler;
  MockHttpHandlerClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    String body = '';
    if (request is http.Request) {
      body = request.body;
    }
    final res = await handler(request, body);
    return http.StreamedResponse(
      Stream.value(utf8.encode(res.body)),
      res.statusCode,
      request: request,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        ...res.headers,
      },
    );
  }
}

/// Konstruiše gotrue `User` iz JSON-a (isti sloj koji koristi Supabase SDK).
User _supabaseUser({
  String id = 'user-1',
  String? email = 'test@example.com',
  bool anonymous = false,
  Map<String, dynamic>? metadata,
}) =>
    User.fromJson({
      'id': id,
      'email': email,
      'is_anonymous': anonymous,
      'user_metadata': metadata ?? const <String, dynamic>{},
      'aud': 'authenticated',
      'created_at': '2026-01-01T00:00:00Z',
    })!;

void main() {
  AuthService createService(
          {_FakeAuthClient? auth, _FakeUsersService? users}) =>
      AuthService(
        client: _FakeSupabaseClient(auth ?? _FakeAuthClient()),
        usersService: users ?? _FakeUsersService(),
      );

  group('AuthService — prijava i registracija', () {
    test('signInWithEmail prosleđuje kredencijale bez greške pri uspehu',
        () async {
      final auth = _FakeAuthClient();
      final service = createService(auth: auth);

      await service.signInWithEmail('test@example.com', 'lozinka123');

      expect(auth.signInCalls, [
        {'email': 'test@example.com', 'password': 'lozinka123'},
      ]);
    });

    test('signInWithEmail umotava grešku u AppError', () async {
      final auth = _FakeAuthClient()
        ..signInError = Exception('Invalid login credentials');
      final service = createService(auth: auth);

      await expectLater(
        service.signInWithEmail('a@b.rs', 'pogresna'),
        throwsA(isA<AppError>()),
      );
    });

    test('registerWithEmail šalje složeni metadata payload za prodavca',
        () async {
      final auth = _FakeAuthClient();
      final service = createService(auth: auth);

      await service.registerWithEmail(
        'nova@b.rs',
        'lozinka123',
        displayName: 'Jelena',
        phone: '0631111111',
        city: 'Niš',
        isSeller: true,
        farmName: 'Gazdinstvo Jelena',
        location: 'Palilula',
      );

      final call = auth.signUpCalls.single;
      expect(call['email'], 'nova@b.rs');
      expect(call['password'], 'lozinka123');
      expect(call['emailRedirectTo'], isNotNull);
      final data = call['data'] as Map<String, dynamic>;
      expect(data['role'], 'seller');
      expect(data['display_name'], 'Jelena');
      expect(data['phone'], '0631111111');
      expect(data['city'], 'Niš');
      expect(data['farm_name'], 'Gazdinstvo Jelena');
      expect(data['location'], 'Palilula');
    });

    test('registerWithEmail za kupca šalje role buyer', () async {
      final auth = _FakeAuthClient();
      final service = createService(auth: auth);

      await service.registerWithEmail('kupac@b.rs', 'lozinka',
          displayName: 'Marko');

      final data = auth.signUpCalls.single['data'] as Map<String, dynamic>;
      expect(data['role'], 'buyer');
    });

    test('registerWithEmail umotava grešku u AppError', () async {
      final auth = _FakeAuthClient()
        ..signUpError = Exception('User already registered');
      final service = createService(auth: auth);

      await expectLater(
        service.registerWithEmail('a@b.rs', 'lozinka'),
        throwsA(isA<AppError>()),
      );
    });

    test('resendConfirmationEmail šalje signup tip na prosleđeni email',
        () async {
      final auth = _FakeAuthClient();
      final service = createService(auth: auth);

      await service.resendConfirmationEmail('a@b.rs');

      final call = auth.resendCalls.single;
      expect(call['email'], 'a@b.rs');
      expect(call['type'], OtpType.signup);
    });

    test('sendPasswordReset prosleđuje email', () async {
      final auth = _FakeAuthClient();
      final service = createService(auth: auth);

      await service.sendPasswordReset('a@b.rs');

      expect(auth.resetCalls.single['email'], 'a@b.rs');
    });
  });

  group('AuthService — getCurrentUser', () {
    test('vraća null kada nema sesije', () async {
      final service = createService(auth: _FakeAuthClient());

      expect(await service.getCurrentUser(), isNull);
    });

    test('odjavljuje zaostalu anonimnu sesiju i vraća null', () async {
      final auth = _FakeAuthClient(user: _supabaseUser(anonymous: true));
      final service = createService(auth: auth);

      final user = await service.getCurrentUser();

      expect(user, isNull);
      expect(auth.signOutCount, 1);
    });

    test('vraća profil iz UsersService kada postoji', () async {
      final auth = _FakeAuthClient(user: _supabaseUser());
      final users = _FakeUsersService()
        ..profile = const UserModel(id: 'user-1', displayName: 'Marko');
      final service = createService(auth: auth, users: users);

      final user = await service.getCurrentUser();

      expect(user, isNotNull);
      expect(user!.id, 'user-1');
      expect(user.displayName, 'Marko');
    });

    test('konstruiše fallback iz user_metadata kada profil ne postoji',
        () async {
      final auth = _FakeAuthClient(
          user: _supabaseUser(metadata: {
        'display_name': 'Petar',
        'avatar_url': 'https://img.example/x.png',
      }));
      final users = _FakeUsersService()..profile = null;
      final service = createService(auth: auth, users: users);

      final user = await service.getCurrentUser();

      expect(user, isNotNull);
      expect(user!.displayName, 'Petar');
      expect(user.profileImageUrl, 'https://img.example/x.png');
      expect(user.isGuest, isFalse);
    });

    test('umotava grešku iz UsersService u AppError', () async {
      final auth = _FakeAuthClient(user: _supabaseUser());
      final users = _FakeUsersService()
        ..getUserError = Exception('profiles down');
      final service = createService(auth: auth, users: users);

      await expectLater(service.getCurrentUser(), throwsA(isA<AppError>()));
    });
  });

  group('AuthService — gost i prebacivanje u prodavca', () {
    test('signInAsGuest odjavljuje zaostali anonimni nalog', () async {
      final auth = _FakeAuthClient(user: _supabaseUser(anonymous: true));
      final service = createService(auth: auth);

      await service.signInAsGuest();

      expect(auth.signOutCount, 1);
    });

    test('signInAsGuest ne dira regularnu sesiju', () async {
      final auth = _FakeAuthClient(user: _supabaseUser(anonymous: false));
      final service = createService(auth: auth);

      await service.signInAsGuest();

      expect(auth.signOutCount, 0);
    });

    test('switchToSeller baca unauthorized kada korisnik nije prijavljen',
        () async {
      final users = _FakeUsersService();
      final service = createService(auth: _FakeAuthClient(), users: users);

      await expectLater(
        service.switchToSeller(farmName: 'F', location: 'L', phone: '064'),
        throwsA(isA<AppError>()),
      );
      expect(users.upsertCalls, isEmpty);
    });

    test('switchToSeller upisuje prodavački profil preko UsersService',
        () async {
      final auth = _FakeAuthClient(user: _supabaseUser(id: 'user-9'));
      final users = _FakeUsersService();
      final service = createService(auth: auth, users: users);

      await service.switchToSeller(
        farmName: 'Farma X',
        location: 'Vršac',
        phone: '0641234567',
      );

      final call = users.upsertCalls.single;
      expect(call['userId'], 'user-9');
      expect(call['role'], 'seller');
      expect(call['farmName'], 'Farma X');
      expect(call['location'], 'Vršac');
      expect(call['phone'], '0641234567');
      expect(call['isGuest'], isFalse);
    });
  });

  group('AuthService — anti-enumeration RPC pozivi (mock HTTP)', () {
    AuthService rpcService(MockHttpHandlerClient mock) => AuthService(
          client: SupabaseClient('https://fake.supabase.co', 'fake-key',
              httpClient: mock),
          usersService: _FakeUsersService(),
        );

    test('checkEmailExists vraća true kada RPC potvrdi', () async {
      final mock = MockHttpHandlerClient(
          (req, body) async => http.Response('true', 200));
      final service = rpcService(mock);

      expect(await service.checkEmailExists('Existing@Example.RS'), isTrue);
    });

    test('checkEmailExists vraća false kada RPC kaže false', () async {
      final mock = MockHttpHandlerClient(
          (req, body) async => http.Response('false', 200));
      final service = rpcService(mock);

      expect(await service.checkEmailExists('nepostojeci@example.rs'), isFalse);
    });

    test('checkEmailExists gutaje RPC grešku i vraća false (anti-enumeration)',
        () async {
      final mock = MockHttpHandlerClient((req, body) async => http.Response(
          jsonEncode({'code': '429', 'message': 'rate limit exceeded'}), 500));
      final service = rpcService(mock);

      expect(await service.checkEmailExists('a@example.rs'), isFalse);
    });

    test('checkPhoneExists vraća true kada RPC potvrdi', () async {
      final mock = MockHttpHandlerClient(
          (req, body) async => http.Response('true', 200));
      final service = rpcService(mock);

      expect(await service.checkPhoneExists('0631234567'), isTrue);
    });

    test(
        'checkPhoneExists vraća false pri rate-limit grešci (P0001/prekoračen)',
        () async {
      final mock = MockHttpHandlerClient((req, body) async => http.Response(
          jsonEncode({'code': 'P0001', 'message': 'prekoračen broj pokušaja'}),
          500));
      final service = rpcService(mock);

      expect(await service.checkPhoneExists('0631234567'), isFalse);
    });

    test('checkPhoneExists propaguje neočekivane greške kao AppError',
        () async {
      final mock = MockHttpHandlerClient((req, body) async =>
          http.Response(jsonEncode({'message': 'neočekivana greška'}), 500));
      final service = rpcService(mock);

      await expectLater(
        service.checkPhoneExists('0631234567'),
        throwsA(isA<AppError>()),
      );
    });
  });
}
