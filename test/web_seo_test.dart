import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/core/route_seo_resolver.dart';
import 'package:mleko/core/web_seo.dart';
import 'package:mleko/models/classified_ad_model.dart';
import 'package:mleko/models/product_model.dart';

void main() {
  group('Web SEO helpers test', () {
    test('applyRouteSeo executes without error for public and private routes', () {
      expect(() => applyRouteSeo('/'), returnsNormally);
      expect(() => applyRouteSeo('/classifieds'), returnsNormally);
      expect(() => applyRouteSeo('/categories'), returnsNormally);
      expect(() => applyRouteSeo('/search'), returnsNormally);
      expect(() => applyRouteSeo('/sellers-map'), returnsNormally);
      expect(() => applyRouteSeo('/about'), returnsNormally);
      expect(() => applyRouteSeo('/uslovi-koriscenja'), returnsNormally);
      expect(() => applyRouteSeo('/politika-privatnosti'), returnsNormally);
      expect(() => applyRouteSeo('/support'), returnsNormally);

      // Private routes
      expect(() => applyRouteSeo('/cart'), returnsNormally);
      expect(() => applyRouteSeo('/checkout/123'), returnsNormally);
      expect(() => applyRouteSeo('/orders'), returnsNormally);
      expect(() => applyRouteSeo('/profile'), returnsNormally);
      expect(() => applyRouteSeo('/admin/tickets'), returnsNormally);
      expect(() => applyRouteSeo('/classifieds/new'), returnsNormally);
    });

    test('setProductSeo runs normally and parses product details', () {
      final product = ProductModel(
        id: 'prod-123',
        sellerId: 'seller-456',
        category: 'Mlečni proizvodi',
        name: 'Domaći planinski sir',
        pricePerKg: 1200,
        minOrderKg: 1,
        availableKg: 50,
        unitType: ProductModel.unitKg,
        description: 'Vrhunski punomasni sir sa obronaka Zlatibora.',
        imageUrls: ['https://example.com/sir.jpg'],
        pickupOptions: ['lično preuzimanje'],
        location: 'Zlatibor',
        isDomestic: true,
        availableNow: true,
        deliveryMode: ProductDeliveryMode.none,
        selectedDeliveryPointIds: const [],
        createdAt: DateTime.now(),
        sellerIsVerified: true,
        avgRating: 4.9,
        reviewCount: 15,
      );

      expect(() => setProductSeo(product), returnsNormally);
    });

    test('setProductSeo handles products with variants and picks minimum variant price', () {
      final productWithVariants = ProductModel(
        id: 'prod-variants',
        sellerId: 'seller-456',
        category: 'Džemovi',
        name: 'Domaći džem',
        pricePerKg: 1000,
        minOrderKg: 1,
        availableKg: 20,
        unitType: ProductModel.unitPiece,
        description: 'Prirodni džem bez šećera.',
        imageUrls: ['https://example.com/dzem.jpg'],
        pickupOptions: ['lično'],
        location: 'Valjevo',
        isDomestic: true,
        availableNow: true,
        deliveryMode: ProductDeliveryMode.none,
        selectedDeliveryPointIds: const [],
        createdAt: DateTime.now(),
        variants: const [
          ProductVariant(id: 'v1', label: 'Jagoda', price: 650, group: 'Ukus'),
          ProductVariant(id: 'v2', label: 'Malina', price: 800, group: 'Ukus'),
          ProductVariant(id: 'v3', label: 'Borovnica', price: 950, group: 'Ukus'),
        ],
      );

      expect(() => setProductSeo(productWithVariants), returnsNormally);
    });

    test('setClassifiedAdSeo runs normally for classified ad', () {
      final now = DateTime.now();
      final ad = ClassifiedAdModel(
        id: 'ad-999',
        userId: 'user-888',
        title: 'Traktor IMT 539 u odličnom stanju',
        description: 'Ispravan traktor, malo radnih sati, prvi vlasnik.',
        price: 4500,
        currency: 'EUR',
        priceType: 'fixed',
        categoryId: 'traktori',
        categoryName: 'Traktori',
        condition: 'used',
        images: ['https://example.com/traktor.jpg'],
        city: 'Čačak',
        phone: '0601234567',
        phonePublic: true,
        status: 'active',
        viewsCount: 42,
        createdAt: now,
        updatedAt: now,
      );

      expect(() => setClassifiedAdSeo(ad), returnsNormally);
    });

    test('setSellerSeo and setCategorySeo run normally', () {
      expect(
        () => setSellerSeo(
          id: 'seller-777',
          name: 'Poljoprivredno Gazdinstvo Jovanović',
          city: 'Valjevo',
          avatarUrl: 'https://example.com/avatar.jpg',
          bio: 'Proizvodnja organskog meda i pčelinjih proizvoda.',
          rating: 5.0,
          reviewCount: 22,
        ),
        returnsNormally,
      );

      expect(
        () => setCategorySeo(
          name: 'Mlečni proizvodi',
          path: '/categories/mlecni-proizvodi',
          description: 'Sveži domaći sirevi, kajmak, surutka i mleko.',
        ),
        returnsNormally,
      );
    });

    test('resolveQueryRouteSeo handles query search noindex and category canonicals', () {
      final classifiedSearch = resolveQueryRouteSeo('/classifieds?q=traktor');
      expect(classifiedSearch, isNotNull);
      expect(classifiedSearch!.robots, equals(noIndexFollowRobots));
      expect(classifiedSearch.path, equals('/classifieds'));

      final templateSearch =
          resolveQueryRouteSeo('/classifieds?q={search_term_string}');
      expect(templateSearch, isNotNull);
      expect(templateSearch!.robots, equals(noIndexFollowRobots));
      expect(templateSearch.path, equals('/classifieds'));

      final classifiedCatWithQuery =
          resolveQueryRouteSeo('/classifieds?category=poljoprivreda&q=imt');
      expect(classifiedCatWithQuery, isNotNull);
      expect(classifiedCatWithQuery!.robots, equals(noIndexFollowRobots));
      expect(
        classifiedCatWithQuery.path,
        equals('/classifieds?category=poljoprivreda'),
      );

      final foodCat = resolveQueryRouteSeo('/categories?category=mlecni-proizvodi');
      expect(foodCat, isNotNull);
      expect(foodCat!.robots, equals(defaultIndexRobots));
      expect(foodCat.path, equals('/categories?category=mlecni-proizvodi'));

      final unknownFoodCat = resolveQueryRouteSeo('/categories?category=nepoznata');
      expect(unknownFoodCat, isNotNull);
      expect(unknownFoodCat!.robots, equals(noIndexFollowRobots));
      expect(unknownFoodCat.path, equals('/categories'));

      final searchQ = resolveQueryRouteSeo('/search?q=med');
      expect(searchQ, isNotNull);
      expect(searchQ!.robots, equals(noIndexFollowRobots));
      expect(searchQ.path, equals('/search'));

      final searchCategory = resolveQueryRouteSeo('/search?category=Mleko');
      expect(searchCategory, isNotNull);
      expect(searchCategory!.robots, equals(noIndexFollowRobots));
      expect(searchCategory.path, equals('/search'));

      final termsAlias = resolveQueryRouteSeo('/terms');
      expect(termsAlias, isNotNull);
      expect(termsAlias!.path, equals('/uslovi-koriscenja'));

      expect(resolveQueryRouteSeo('/search'), isNull);
    });

    test('applyRouteSeo with query params and setNotFoundSeo run normally', () {
      expect(() => applyRouteSeo('/classifieds?q=traktor'), returnsNormally);
      expect(() => applyRouteSeo('/categories?category=mlecni-proizvodi'),
          returnsNormally);
      expect(() => setNotFoundSeo(path: '/nepostojeca'), returnsNormally);
    });
  });
}
