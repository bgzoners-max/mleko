import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/app_error.dart';
import 'package:mleko/models/category.dart';
import 'package:mleko/providers/categories_provider.dart';
import 'package:mleko/services/services.dart';

class _SuccessSupabaseService implements SupabaseService {
  final List<Category> categories;
  _SuccessSupabaseService(this.categories);

  @override
  Future<List<Category>> getAllCategories() async => categories;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingSupabaseService implements SupabaseService {
  final Exception error;
  _FailingSupabaseService(this.error);

  @override
  Future<List<Category>> getAllCategories() async => throw error;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CategoriesProvider DI and error propagation', () {
    test('successful load populates categories and groups', () async {
      final testCategories = [
        const Category(
          id: 'cat-1',
          name: 'Mlečni proizvodi',
          slug: 'mlecni-proizvodi',
          section: 'hrana',
          icon: 'restaurant',
          order: 1,
        ),
      ];
      final provider = CategoriesProvider(
        service: _SuccessSupabaseService(testCategories),
      );

      expect(provider.isLoaded, isFalse);
      expect(provider.categories, isNull);

      await provider.load();

      expect(provider.isLoaded, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.categories?.length, equals(1));
      expect(provider.categoryNames, equals(['Mlečni proizvodi']));
      expect(provider.topCategories.length, equals(1));
    });

    test('failing load captures error as AppError with user-friendly message', () async {
      final provider = CategoriesProvider(
        service: _FailingSupabaseService(Exception('Network timeout')),
      );

      await provider.load();

      expect(provider.isLoaded, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNotNull);
      expect(provider.error, isA<AppError>());
      expect(provider.error?.userMessage, equals('Greška pri učitavanju kategorija.'));
      expect(provider.categories, isNull);
    });

    test('refresh resets state and re-executes load', () async {
      final testCategories = [
        const Category(
          id: 'cat-1',
          name: 'Sveže voće',
          slug: 'sveze-voce',
          section: 'sveze',
          icon: 'apple',
          order: 1,
        ),
      ];
      final provider = CategoriesProvider(
        service: _SuccessSupabaseService(testCategories),
      );

      await provider.load();
      expect(provider.categories?.length, equals(1));

      await provider.refresh();
      expect(provider.isLoaded, isTrue);
      expect(provider.categories?.length, equals(1));
    });

    test('refresh while load is in-flight supersedes stale result', () async {
      final slowCompleter = Completer<List<Category>>();
      var calls = 0;
      final svc = _ControllableSupabaseService(() {
        calls++;
        if (calls == 1) return slowCompleter.future;
        return Future.value([
          const Category(
            id: 'cat-new',
            name: 'Novi sir',
            slug: 'novi-sir',
            section: 'hrana',
            icon: 'restaurant',
            order: 1,
          ),
        ]);
      });

      final provider = CategoriesProvider(service: svc);
      final firstLoad = provider.load();
      await provider.refresh();

      slowCompleter.complete([
        const Category(
          id: 'cat-old',
          name: 'Stari sir',
          slug: 'stari-sir',
          section: 'hrana',
          icon: 'restaurant',
          order: 1,
        ),
      ]);
      await firstLoad;

      expect(calls, equals(2));
      expect(provider.categories?.single.id, equals('cat-new'));
    });
  });
}

class _ControllableSupabaseService implements SupabaseService {
  final Future<List<Category>> Function() handler;
  _ControllableSupabaseService(this.handler);

  @override
  Future<List<Category>> getAllCategories() => handler();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

