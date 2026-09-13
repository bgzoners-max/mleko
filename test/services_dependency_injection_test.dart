import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/services/auth/auth_service.dart';
import 'package:mleko/services/auth/users_service.dart';
import 'package:mleko/services/communication/chat_service.dart';
import 'package:mleko/services/communication/push_service.dart';
import 'package:mleko/services/catalog/products_service.dart';
import 'package:mleko/services/orders/orders_service.dart';
import 'package:mleko/services/social/reviews_service.dart';

void main() {
  group('Service DI Constructors and Singletons', () {
    test('default constructors return singleton/consistent instances', () {
      final chat1 = ChatService();
      final chat2 = ChatService();
      expect(identical(chat1, chat2), isTrue);

      final users1 = UsersService();
      final users2 = UsersService();
      expect(identical(users1, users2), isTrue);

      final orders1 = OrdersService();
      final orders2 = OrdersService();
      expect(identical(orders1, orders2), isTrue);

      final products1 = ProductsService();
      final products2 = ProductsService();
      expect(identical(products1, products2), isTrue);

      final reviews1 = ReviewsService();
      final reviews2 = ReviewsService();
      expect(identical(reviews1, reviews2), isTrue);

      final push1 = PushService();
      final push2 = PushService();
      expect(identical(push1, push2), isTrue);
    });

    test('AuthService accepts injected UsersService and custom client', () {
      final customUsers = UsersService();
      final auth = AuthService(usersService: customUsers);
      expect(auth, isNotNull);
    });

    test('Services accept nullable client parameter without runtime errors', () {
      final chat = ChatService(client: null);
      expect(chat, isNotNull);

      final push = PushService(client: null);
      expect(push, isNotNull);

      final orders = OrdersService(client: null);
      expect(orders, isNotNull);

      final products = ProductsService(client: null);
      expect(products, isNotNull);

      final users = UsersService(client: null);
      expect(users, isNotNull);

      final reviews = ReviewsService(client: null);
      expect(reviews, isNotNull);
    });
  });
}
