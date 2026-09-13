import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/core/notification_types.dart';
import 'package:mleko/models/classified_subscription_model.dart';
import 'package:mleko/models/notification_model.dart';

void main() {
  group('ClassifiedSubscriptionModel', () {
    test('parses from and to JSON correctly', () {
      final json = {
        'id': 'sub-123',
        'user_id': 'user-456',
        'category_id': 'traktori',
        'category_name': 'Traktori',
        'category_icon_name': 'agriculture',
        'search_query': 'IMT 539',
        'max_price': 5000.0,
        'currency': 'EUR',
        'created_at': '2026-09-10T12:00:00.000Z',
      };

      final model = ClassifiedSubscriptionModel.fromJson(json);

      expect(model.id, 'sub-123');
      expect(model.userId, 'user-456');
      expect(model.categoryId, 'traktori');
      expect(model.categoryName, 'Traktori');
      expect(model.categoryIconName, 'agriculture');
      expect(model.searchQuery, 'IMT 539');
      expect(model.maxPrice, 5000.0);
      expect(model.currency, 'EUR');
      expect(model.createdAt.toUtc(), DateTime.parse('2026-09-10T12:00:00.000Z'));

      final outJson = model.toJson();
      expect(outJson['id'], 'sub-123');
      expect(outJson['user_id'], 'user-456');
      expect(outJson['category_id'], 'traktori');
      expect(outJson['search_query'], 'IMT 539');
      expect(outJson['max_price'], 5000.0);
      expect(outJson['currency'], 'EUR');
    });

    test('criteriaSummary generates clean text for different combinations', () {
      final onlyCat = ClassifiedSubscriptionModel(
        id: '1',
        userId: 'u1',
        categoryId: 'traktori',
        categoryName: 'Traktori',
        createdAt: DateTime.now(),
      );
      expect(onlyCat.criteriaSummary, 'Svi novi oglasi u kategoriji');

      final withQuery = ClassifiedSubscriptionModel(
        id: '2',
        userId: 'u1',
        categoryId: 'traktori',
        categoryName: 'Traktori',
        searchQuery: 'IMT',
        createdAt: DateTime.now(),
      );
      expect(withQuery.criteriaSummary, 'Reč: „IMT”');

      final withPrice = ClassifiedSubscriptionModel(
        id: '3',
        userId: 'u1',
        categoryId: 'traktori',
        categoryName: 'Traktori',
        maxPrice: 6500,
        currency: 'EUR',
        createdAt: DateTime.now(),
      );
      expect(withPrice.criteriaSummary, 'Do 6500 EUR');

      final withBoth = ClassifiedSubscriptionModel(
        id: '4',
        userId: 'u1',
        categoryId: 'traktori',
        categoryName: 'Traktori',
        searchQuery: 'IMT 539',
        maxPrice: 5000,
        currency: 'EUR',
        createdAt: DateTime.now(),
      );
      expect(withBoth.criteriaSummary, 'Reč: „IMT 539” • Do 5000 EUR');
    });
  });

  group('Classified Notifications', () {
    test('NotificationModel parses classified_ad_id properly', () {
      final json = {
        'id': 'notif-1',
        'user_id': 'u1',
        'title': 'Novi oglas u kategoriji Traktori',
        'body': 'Korisnik je postavio oglas: IMT 539 de luxe',
        'type': 'new_classified_ad',
        'classified_ad_id': 'ad-999',
        'is_read': false,
        'created_at': '2026-09-10T15:30:00.000Z',
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.id, 'notif-1');
      expect(notif.type, 'new_classified_ad');
      expect(notif.classifiedAdId, 'ad-999');
      expect(notif.isRead, isFalse);
    });

    test('notificationTypeIsClassifiedRelated helper works correctly', () {
      expect(notificationTypeIsClassifiedRelated('new_classified_ad'), isTrue);
      expect(notificationTypeIsClassifiedRelated('classified_saved_search'), isTrue);
      expect(notificationTypeIsClassifiedRelated('new_order'), isFalse);
      expect(notificationTypeIsClassifiedRelated('new_message'), isFalse);
      expect(notificationTypeIsClassifiedRelated(null), isFalse);
    });
  });
}
