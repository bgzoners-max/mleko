import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mleko/models/app_error.dart';
import 'package:mleko/services/social/reviews_service.dart';

http.Response _jsonResponse(String body, [int status = 200]) =>
    http.Response(body, status,
        headers: {'content-type': 'application/json; charset=utf-8'});

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

Map<String, dynamic> reviewJson(String id,
        {String buyerId = 'b1',
        String sellerId = 's1',
        int rating = 5,
        String comment = 'Odličan proizvod!'}) =>
    {
      'id': id,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'product_id': 'p1',
      'order_id': 'o1',
      'rating': rating,
      'comment': comment,
      'created_at': '2026-01-02T10:00:00Z',
      'seller_reply': null,
    };

void main() {
  ReviewsService serviceFor(MockHttpHandlerClient mock) => ReviewsService(
      client: SupabaseClient('https://fake.supabase.co', 'fake-key',
          httpClient: mock));

  group('ReviewsService — čitanje recenzija', () {
    test('getReviewsForSeller mapira redove i sortira opadajuće', () async {
      http.BaseRequest? reviewsReq;
      final mock = MockHttpHandlerClient((req, body) async {
        reviewsReq = req;
        return _jsonResponse(jsonEncode([
          reviewJson('r1', rating: 5),
          reviewJson('r2', sellerId: 's1', rating: 3, comment: 'Solidno'),
        ]));
      });
      final service = serviceFor(mock);

      final reviews = await service.getReviewsForSeller('s1');

      expect(reviews.length, 2);
      expect(reviews.first.id, 'r1');
      expect(reviews.first.rating, 5);
      expect(reviews.first.comment, 'Odličan proizvod!');
      expect(reviews.last.rating, 3);
      expect(reviewsReq!.url.path, contains('/reviews'));
      expect(reviewsReq!.url.query, contains('seller_id=eq.s1'));
      expect(reviewsReq!.url.query, contains('order=created_at.desc'));
    });

    test('getReviewsByBuyer filtrira po kupcu', () async {
      http.BaseRequest? reviewsReq;
      final mock = MockHttpHandlerClient((req, body) async {
        reviewsReq = req;
        return _jsonResponse(jsonEncode([reviewJson('r1')]));
      });
      final service = serviceFor(mock);

      final reviews = await service.getReviewsByBuyer('b1');

      expect(reviews.length, 1);
      expect(reviewsReq!.url.query, contains('buyer_id=eq.b1'));
    });

    test('getReviewsForProduct filtrira po proizvodu', () async {
      http.BaseRequest? reviewsReq;
      final mock = MockHttpHandlerClient((req, body) async {
        reviewsReq = req;
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      await service.getReviewsForProduct('p1');

      expect(reviewsReq!.url.query, contains('product_id=eq.p1'));
    });

    test('greška pri čitanju se umotava u AppError', () async {
      final mock = MockHttpHandlerClient((req, body) async =>
          _jsonResponse(jsonEncode({'message': 'boom'}), 500));
      final service = serviceFor(mock);

      await expectLater(
          service.getReviewsForSeller('s1'), throwsA(isA<AppError>()));
    });
  });

  group('ReviewsService — statistike i proseci', () {
    test('getSellerStats parsira RPC odgovor', () async {
      String? rpcFn;
      final mock = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rpc/')) {
          rpcFn = req.url.path.split('/rpc/').last;
          return _jsonResponse(jsonEncode({
            'orders_count': 42,
            'avg_rating': 4.67,
            'review_count': 18,
            'avg_response_hours': 2.5,
          }));
        }
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      final stats = await service.getSellerStats('s1');

      expect(rpcFn, 'get_seller_stats');
      expect(stats.ordersCount, 42);
      expect(stats.avgRating, 4.67);
      expect(stats.reviewCount, 18);
      expect(stats.avgResponseHours, 2.5);
    });

    test('getSellerStats vraća prazan model kada RPC vrati null', () async {
      final mock =
          MockHttpHandlerClient((req, body) async => _jsonResponse('null'));
      final service = serviceFor(mock);

      final stats = await service.getSellerStats('s1');

      expect(stats.ordersCount, 0);
      expect(stats.reviewCount, 0);
      expect(stats.avgRating, isNull);
    });

    test('computeAverage — čista logika (čista logika proseka)', () {
      expect(ReviewsService.computeAverage([5, 4]), 4.5);
      expect(ReviewsService.computeAverage([3]), 3.0);
      expect(ReviewsService.computeAverage(const <int>[]), isNull);
      expect(ReviewsService.computeAverage([1, 2, 3, 4, 5]), 3.0);
    });

    test('getAverageRatingForSeller delegira na seller stats', () async {
      final mock = MockHttpHandlerClient((req, body) async => _jsonResponse(
          jsonEncode(
              {'orders_count': 1, 'avg_rating': 4.0, 'review_count': 1})));
      final service = serviceFor(mock);

      expect(await service.getAverageRatingForSeller('s1'), 4.0);
    });

    test('getAverageRatingForProduct koristi agregatnu tabelu kada postoji',
        () async {
      final mock = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('product_review_summary')) {
          return _jsonResponse(
              jsonEncode({'avg_rating': 4.67, 'review_count': 3}));
        }
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      expect(await service.getAverageRatingForProduct('p1'), 4.67);
    });

    test('getAverageRatingForProduct pada na RPC kada agregat ne postoji',
        () async {
      final requests = <http.BaseRequest>[];
      final mock = MockHttpHandlerClient((req, body) async {
        requests.add(req);
        if (req.url.path.contains('product_review_summary')) {
          return _jsonResponse('[]');
        }
        if (req.url.path.contains('/rpc/')) {
          return _jsonResponse(
              jsonEncode({'avg_rating': 3.5, 'review_count': 2}));
        }
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      expect(await service.getAverageRatingForProduct('p1'), 3.5);
      expect(requests.any((r) => r.url.path.contains('get_product_stats')),
          isTrue);
    });

    test('getAverageRatingForProduct vraća null za nula recenzija', () async {
      final mock = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('product_review_summary')) {
          return _jsonResponse(
              jsonEncode({'avg_rating': null, 'review_count': 0}));
        }
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      expect(await service.getAverageRatingForProduct('p1'), isNull);
    });
  });

  group('ReviewsService — recenziranje porudžbina', () {
    test('canReviewOrder vraća true kada recenzija ne postoji', () async {
      final mock = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/reviews')) return _jsonResponse('[]');
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      expect(await service.canReviewOrder('b1', 'o1'), isTrue);
    });

    test('canReviewOrder vraća false kada recenzija već postoji', () async {
      final mock = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/reviews')) {
          return _jsonResponse(jsonEncode({'id': 'r1'}));
        }
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      expect(await service.canReviewOrder('b1', 'o1'), isFalse);
    });

    test('getReviewableOrder vraća record iz RPC odgovora', () async {
      final mock = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rpc/')) {
          return _jsonResponse(jsonEncode({
            'order_id': 'o1',
            'product_id': 'p1',
            'product_name': 'Domaći sir',
          }));
        }
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      final order = await service.getReviewableOrder('b1', 's1');

      expect(order, isNotNull);
      expect(order!.orderId, 'o1');
      expect(order.productId, 'p1');
      expect(order.productName, 'Domaći sir');
    });

    test('getReviewableOrder vraća null za nepotpun RPC odgovor', () async {
      final mock = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rpc/')) {
          // Nedostaje product_name.
          return _jsonResponse(
              jsonEncode({'order_id': 'o1', 'product_id': 'p1'}));
        }
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      expect(await service.getReviewableOrder('b1', 's1'), isNull);
    });

    test('addReview upisuje kompletan payload', () async {
      String? insertBody;
      String? insertPath;
      final mock = MockHttpHandlerClient((req, body) async {
        insertBody = body;
        insertPath = req.url.path;
        return _jsonResponse('[]', 201);
      });
      final service = serviceFor(mock);

      await service.addReview(
        buyerId: 'b1',
        sellerId: 's1',
        orderId: 'o1',
        rating: 5,
        productId: 'p1',
        comment: 'Svaka čast!',
      );

      expect(insertPath, contains('/reviews'));
      final json = jsonDecode(insertBody!) as Map<String, dynamic>;
      expect(json['buyer_id'], 'b1');
      expect(json['seller_id'], 's1');
      expect(json['order_id'], 'o1');
      expect(json['product_id'], 'p1');
      expect(json['rating'], 5);
      expect(json['comment'], 'Svaka čast!');
    });
  });

  group('ReviewsService — recenzije kupaca i odgovori', () {
    test('getReviewsForBuyer mapira buyer_reviews redove', () async {
      http.BaseRequest? req_;
      final mock = MockHttpHandlerClient((req, body) async {
        req_ = req;
        if (req.url.path.contains('buyer_reviews')) {
          return _jsonResponse(jsonEncode([
            {
              'id': 'br1',
              'seller_id': 's1',
              'buyer_id': 'b1',
              'order_id': 'o1',
              'rating': 5,
              'comment': 'Kupac uredan',
              'created_at': '2026-01-02T10:00:00Z',
              'buyer_reply': null,
            }
          ]));
        }
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      final reviews = await service.getReviewsForBuyer('b1');

      expect(reviews.length, 1);
      expect(reviews.first.id, 'br1');
      expect(reviews.first.rating, 5);
      expect(req_!.url.query, contains('buyer_id=eq.b1'));
    });

    test('getReviewsForBuyer vraća praznu listu kada tabela ne postoji (42P01)',
        () async {
      final mock = MockHttpHandlerClient((req, body) async => _jsonResponse(
          jsonEncode({'code': '42P01', 'message': 'not found'}), 404));
      final service = serviceFor(mock);

      expect(await service.getReviewsForBuyer('b1'), isEmpty);
    });

    test('getAverageRatingForBuyer računa prosek iz recenzija', () async {
      final mock = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('buyer_reviews')) {
          return _jsonResponse(jsonEncode([
            {
              'id': 'br1',
              'seller_id': 's1',
              'buyer_id': 'b1',
              'rating': 5,
              'comment': '',
              'created_at': '2026-01-02T10:00:00Z',
            },
            {
              'id': 'br2',
              'seller_id': 's2',
              'buyer_id': 'b1',
              'rating': 4,
              'comment': '',
              'created_at': '2026-01-03T10:00:00Z',
            },
          ]));
        }
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      expect(await service.getAverageRatingForBuyer('b1'), 4.5);
    });

    test('canSellerReviewBuyer: true za isporučenu porudžbinu bez recenzije',
        () async {
      final mock = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/orders')) {
          return _jsonResponse(jsonEncode({'id': 'o1', 'status': 'delivered'}));
        }
        if (req.url.path.contains('buyer_reviews')) return _jsonResponse('[]');
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      expect(await service.canSellerReviewBuyer('s1', 'o1'), isTrue);
    });

    test('canSellerReviewBuyer: false kada porudžbina nije završena', () async {
      final mock = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/orders')) {
          return _jsonResponse(jsonEncode({'id': 'o1', 'status': 'sent'}));
        }
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      expect(await service.canSellerReviewBuyer('s1', 'o1'), isFalse);
    });

    test('canSellerReviewBuyer: false kada recenzija već postoji', () async {
      final mock = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/orders')) {
          return _jsonResponse(jsonEncode({'id': 'o1', 'status': 'archived'}));
        }
        if (req.url.path.contains('buyer_reviews')) {
          return _jsonResponse(jsonEncode({'id': 'br1'}));
        }
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      expect(await service.canSellerReviewBuyer('s1', 'o1'), isFalse);
    });

    test('addBuyerReview upisuje payload u buyer_reviews', () async {
      String? insertBody;
      String? insertPath;
      final mock = MockHttpHandlerClient((req, body) async {
        insertBody = body;
        insertPath = req.url.path;
        return _jsonResponse('[]', 201);
      });
      final service = serviceFor(mock);

      await service.addBuyerReview(
        sellerId: 's1',
        buyerId: 'b1',
        orderId: 'o1',
        rating: 5,
        comment: 'Hvala!',
      );

      expect(insertPath, contains('buyer_reviews'));
      final json = jsonDecode(insertBody!) as Map<String, dynamic>;
      expect(json['seller_id'], 's1');
      expect(json['buyer_id'], 'b1');
      expect(json['order_id'], 'o1');
      expect(json['rating'], 5);
    });

    test('addSellerReply zove RPC sa ispravnim parametrima', () async {
      String? rpcFn;
      String? rpcBody;
      final mock = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rpc/')) {
          rpcFn = req.url.path.split('/rpc/').last;
          rpcBody = body;
        }
        return _jsonResponse('[]', 200);
      });
      final service = serviceFor(mock);

      await service.addSellerReply(reviewId: 'r1', reply: 'Hvala na pohvali!');

      expect(rpcFn, 'add_seller_reply');
      expect(rpcBody, contains('"p_review_id":"r1"'));
      expect(rpcBody, contains('Hvala na pohvali'));
    });

    test('addBuyerReply zove RPC sa ispravnim parametrima', () async {
      String? rpcFn;
      String? rpcBody;
      final mock = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rpc/')) {
          rpcFn = req.url.path.split('/rpc/').last;
          rpcBody = body;
        }
        return _jsonResponse('[]', 200);
      });
      final service = serviceFor(mock);

      await service.addBuyerReply(buyerReviewId: 'br1', reply: 'Dogovoreno!');

      expect(rpcFn, 'add_buyer_reply');
      expect(rpcBody, contains('"p_review_id":"br1"'));
    });
  });
}
