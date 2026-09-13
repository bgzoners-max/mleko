import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/buyer_review_model.dart';
import 'package:mleko/models/category.dart';
import 'package:mleko/models/category_attribute_model.dart';
import 'package:mleko/models/conversation_model.dart';
import 'package:mleko/models/message_model.dart';
import 'package:mleko/models/order_item_model.dart';
import 'package:mleko/models/product_sort.dart';
import 'package:mleko/models/review_model.dart';
import 'package:mleko/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('parses buyer and seller from json and handles copyWith', () {
      final buyerJson = {
        'id': 'buyer-1',
        'email': 'buyer@example.com',
        'phone': '+38160123456',
        'display_name': 'Petar Petrović',
        'city': 'Beograd',
        'location': 'Knez Mihailova 1',
        'postal_code': '11000',
        'role': 'buyer',
        'is_guest': false,
        'is_admin': false,
        'created_at': '2026-01-01T12:00:00Z',
      };

      final buyer = UserModel.fromJson(buyerJson);
      expect(buyer.id, 'buyer-1');
      expect(buyer.email, 'buyer@example.com');
      expect(buyer.displayName, 'Petar Petrović');
      expect(buyer.address, 'Knez Mihailova 1');
      expect(buyer.isSeller, isFalse);
      expect(buyer.isAdmin, isFalse);

      final buyerJsonOut = buyer.toJson();
      expect(buyerJsonOut['email'], 'buyer@example.com');
      expect(buyerJsonOut['role'], 'buyer');
      expect(buyerJsonOut['location'], 'Knez Mihailova 1');

      final sellerJson = {
        'id': 'seller-1',
        'role': 'seller',
        'farm_name': 'Gazdinstvo Milanović',
        'location': 'Valjevo, Popučke',
        'is_verified': true,
        'phone_public': true,
        'seller_story': 'Prirodna proizvodnja meda i sira',
        'farm_gallery_urls': ['https://img.com/1.jpg'],
        'seller_tags': ['sir', 'med'],
        'seller_quick_replies': ['Hvala na porudžbini!', 'Isporuka u petak.'],
        'is_admin': true,
      };

      final seller = UserModel.fromJson(sellerJson);
      expect(seller.isSeller, isTrue);
      expect(seller.farmName, 'Gazdinstvo Milanović');
      expect(seller.isVerified, isTrue);
      expect(seller.phonePublic, isTrue);
      expect(seller.sellerStory, 'Prirodna proizvodnja meda i sira');
      expect(seller.farmGalleryUrls.length, 1);
      expect(seller.sellerTags, contains('sir'));
      expect(seller.sellerQuickReplies.length, 2);
      expect(seller.isAdmin, isTrue);

      final sellerJsonOut = seller.toJson();
      expect(sellerJsonOut['role'], 'seller');
      expect(sellerJsonOut['farm_name'], 'Gazdinstvo Milanović');
      expect(sellerJsonOut['seller_quick_replies'], isNotEmpty);

      final updated = seller.copyWith(
        displayName: 'Milan Milanović',
        isVerified: false,
        sellerTags: ['kajmak'],
      );
      expect(updated.displayName, 'Milan Milanović');
      expect(updated.isVerified, isFalse);
      expect(updated.sellerTags, ['kajmak']);
      expect(updated.farmName, 'Gazdinstvo Milanović');
    });
  });

  group('Category and CategoryGroup', () {
    test('parses Category and builds CategoryGroup', () {
      final json = {
        'id': 'cat-1',
        'name': 'Mlečni proizvodi',
        'slug': 'mlecni-proizvodi',
        'icon': '🥛',
        'order': 1,
        'parent_id': null,
        'section': 'hrana',
      };

      final cat = Category.fromJson(json);
      expect(cat.id, 'cat-1');
      expect(cat.name, 'Mlečni proizvodi');
      expect(cat.slug, 'mlecni-proizvodi');
      expect(cat.icon, '🥛');
      expect(cat.order, 1);
      expect(cat.parentId, isNull);
      expect(cat.section, 'hrana');

      final map = cat.toJson();
      expect(map['id'], 'cat-1');
      expect(map['name'], 'Mlečni proizvodi');
      expect(map['section'], 'hrana');

      const childCat = Category(
        id: 'cat-2',
        name: 'Kačkavalj',
        parentId: 'cat-1',
      );

      final groupWithChildren = CategoryGroup(parent: cat, children: const [childCat]);
      expect(groupWithChildren.selectable, [childCat]);

      const groupWithoutChildren = CategoryGroup(parent: childCat, children: []);
      expect(groupWithoutChildren.selectable, [childCat]);
    });
  });

  group('OrderItemModel', () {
    test('calculates totals and formats totalQuantityLabel', () {
      const item1 = OrderItemModel(
        productId: 'p-1',
        productName: 'Kravlji sir',
        quantityKg: 2.5,
        unitType: 'kg',
        unitPrice: 800,
      );
      expect(item1.totalPrice, 2000.0);

      const item2 = OrderItemModel(
        productId: 'p-2',
        productName: 'Sveže mleko',
        quantityKg: 3.0,
        unitType: 'L',
        unitPrice: 150,
      );

      const item3 = OrderItemModel(
        productId: 'p-3',
        productName: 'Jaja',
        quantityKg: 30,
        unitType: 'kom',
        unitPrice: 20,
      );

      const item4 = OrderItemModel(
        productId: 'p-4',
        productName: 'Začin',
        quantityKg: 0.2,
        unitType: 'g',
        unitPrice: 2,
      );

      final label = OrderItemModel.totalQuantityLabel([item1, item2, item3, item4]);
      expect(label, contains('2.5 kg'));
      expect(label, contains('3 L'));
      expect(label, contains('200 g'));
      expect(label, contains('30 kom'));

      final json = item1.toJson();
      expect(json['product_id'], 'p-1');
      expect(json['total_price'], 2000.0);

      final fromJson = OrderItemModel.fromJson(json);
      expect(fromJson.productId, 'p-1');
      expect(fromJson.quantityKg, 2.5);
      expect(fromJson.unitPrice, 800);

      expect(OrderItemModel.totalQuantityLabel([]), '');
    });
  });

  group('ConversationModel and MessageModel', () {
    test('parses ConversationModel and resolves last message', () {
      final json = {
        'id': 'conv-1',
        'buyer_id': 'buyer-1',
        'seller_id': 'seller-1',
        'order_id': 'ord-100',
        'created_at': '2026-02-01T10:00:00Z',
        'updated_at': '2026-02-01T11:00:00Z',
        'other_party_name': 'Marko',
        'other_party_image_url': 'https://img.com/avatar.jpg',
        'last_message_body': 'Da li šaljete brzom poštom?',
        'last_message_at': '2026-02-01T10:30:00Z',
        'unread_count': 2,
        'is_favorite': true,
        'hidden': false,
      };

      final conv = ConversationModel.fromJson(json);
      expect(conv.id, 'conv-1');
      expect(conv.buyerId, 'buyer-1');
      expect(conv.sellerId, 'seller-1');
      expect(conv.orderId, 'ord-100');
      expect(conv.otherPartyName, 'Marko');
      expect(conv.lastMessageBody, 'Da li šaljete brzom poštom?');
      expect(conv.unreadCount, 2);
      expect(conv.isFavorite, isTrue);
      expect(conv.hidden, isFalse);

      final fallbackJson = {
        'id': 'conv-2',
        'buyer_id': 'b-2',
        'seller_id': 's-2',
        'last_message': {'body': 'Poruka iz objekta', 'created_at': '2026-02-01T12:00:00Z'},
      };
      final conv2 = ConversationModel.fromJson(fallbackJson);
      expect(conv2.lastMessageBody, 'Poruka iz objekta');
    });

    test('parses MessageModel from json', () {
      final json = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'sender_id': 'user-1',
        'body': 'Zdravo, zanima me sir.',
        'image_url': 'https://img.com/sir.jpg',
        'read_at': '2026-02-01T10:15:00Z',
        'created_at': '2026-02-01T10:10:00Z',
      };

      final msg = MessageModel.fromJson(json);
      expect(msg.id, 'msg-1');
      expect(msg.conversationId, 'conv-1');
      expect(msg.senderId, 'user-1');
      expect(msg.body, 'Zdravo, zanima me sir.');
      expect(msg.imageUrl, 'https://img.com/sir.jpg');
      expect(msg.readAt, isNotNull);
    });
  });

  group('BuyerReviewModel and ReviewModel', () {
    test('parses BuyerReviewModel and checks reply editable status', () {
      final json = {
        'id': 'br-1',
        'seller_id': 's-1',
        'buyer_id': 'b-1',
        'order_id': 'ord-1',
        'rating': 5,
        'comment': 'Pouzdana mušterija, sve po dogovoru.',
        'created_at': '2026-03-01T10:00:00Z',
        'buyer_reply': 'Hvala puno na saradnji!',
        'buyer_reply_at': DateTime.now().toIso8601String(),
      };

      final review = BuyerReviewModel.fromJson(json);
      expect(review.id, 'br-1');
      expect(review.rating, 5);
      expect(review.comment, contains('Pouzdana mušterija'));
      expect(review.buyerReply, 'Hvala puno na saradnji!');
      expect(review.hasNoReply, isFalse);
      expect(review.isReplyEditable, isTrue);

      final noReplyReview = BuyerReviewModel(
        id: 'br-2',
        sellerId: 's-1',
        buyerId: 'b-2',
        rating: 4,
        createdAt: DateTime.now(),
      );
      expect(noReplyReview.hasNoReply, isTrue);
      expect(noReplyReview.isReplyEditable, isTrue);
    });

    test('parses ReviewModel and checks reply editable status', () {
      final json = {
        'id': 'rev-1',
        'buyer_id': 'b-1',
        'seller_id': 's-1',
        'product_id': 'prod-1',
        'rating': 5,
        'comment': 'Odličan sir!',
        'created_at': '2026-03-01T10:00:00Z',
        'seller_reply': 'Hvala lepo, svratite opet!',
        'seller_reply_at': DateTime.now().subtract(const Duration(hours: 48)).toIso8601String(),
      };

      final rev = ReviewModel.fromJson(json);
      expect(rev.id, 'rev-1');
      expect(rev.rating, 5);
      expect(rev.hasNoReply, isFalse);
      expect(rev.isReplyEditable, isFalse); // Starije od 24h
    });
  });

  group('ProductSort', () {
    test('returns correct localized labels', () {
      expect(ProductSort.dateDesc.label, 'Najnovije');
      expect(ProductSort.dateAsc.label, 'Najstarije');
      expect(ProductSort.priceAsc.label, 'Cena: najniža');
      expect(ProductSort.priceDesc.label, 'Cena: najviša');
      expect(ProductSort.location.label, 'Lokacija');
      expect(ProductSort.ratingDesc.label, 'Najbolje ocenjeni');
    });
  });

  group('CategoryAttribute', () {
    test('formats boolean, select and numbers with and without decimals', () {
      const boolAttr = CategoryAttribute(
        key: 'garancija',
        label: 'Garancija',
        type: AttributeType.boolean,
      );
      expect(boolAttr.formatValue(true), 'Da');
      expect(boolAttr.formatValue(false), 'Ne');

      const selectAttr = CategoryAttribute(
        key: 'gorivo',
        label: 'Gorivo',
        type: AttributeType.select,
        options: [
          CategoryAttributeOption(value: 'dizel', label: 'Dizel'),
          CategoryAttributeOption(value: 'benzin', label: 'Benzin'),
        ],
      );
      expect(selectAttr.formatValue('dizel'), 'Dizel');
      expect(selectAttr.formatValue('hibrid'), 'hibrid');

      const intNumberAttr = CategoryAttribute(
        key: 'kilometraza',
        label: 'Kilometraža',
        type: AttributeType.number,
        unit: 'km',
      );
      expect(intNumberAttr.formatValue(185000), '185.000 km');
      expect(intNumberAttr.formatValue(500), '500 km');

      const decimalNumberAttr = CategoryAttribute(
        key: 'povrsina',
        label: 'Površina',
        type: AttributeType.number,
        isDecimal: true,
        unit: 'ha',
      );
      expect(decimalNumberAttr.formatValue(1250.5), '1.250,5 ha');
      expect(decimalNumberAttr.formatValue(15.25), '15,25 ha');
      expect(decimalNumberAttr.formatValue(null), '');
    });
  });
}
