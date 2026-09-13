import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/constants/serbian_districts.dart';
import 'package:mleko/models/classified_ad_model.dart';
import 'package:mleko/utils/classified_attributes_engine.dart';
import 'package:mleko/widgets/classifieds/classified_ad_card.dart';

void main() {
  group('SerbianDistricts & Geographic Mapping', () {
    test('all contains major Serbian districts with correct metadata', () {
      expect(SerbianDistricts.all.isNotEmpty, isTrue);
      expect(SerbianDistricts.all.any((d) => d.id == 'beogradski'), isTrue);
      expect(SerbianDistricts.all.any((d) => d.id == 'juznobacki'), isTrue);
      expect(SerbianDistricts.all.any((d) => d.id == 'zlatiborski'), isTrue);
      expect(SerbianDistricts.all.any((d) => d.id == 'nisavski'), isTrue);
      expect(SerbianDistricts.all.any((d) => d.id == 'sumadijski'), isTrue);
    });

    test('findDistrictById returns correct district', () {
      final district = SerbianDistricts.findDistrictById('zlatiborski');
      expect(district, isNotNull);
      expect(district!.name, 'Zlatiborski okrug');
      expect(district.region, 'Šumadija i Zapadna Srbija');
      expect(district.cities, contains('Užice'));
      expect(district.cities, contains('Zlatibor'));
      expect(district.cities, contains('Čajetina'));
    });

    test('findDistrictForCity resolves city to its parent district', () {
      final zla = SerbianDistricts.findDistrictForCity('Zlatibor');
      expect(zla, isNotNull);
      expect(zla!.id, 'zlatiborski');

      final ns = SerbianDistricts.findDistrictForCity('Novi Sad');
      expect(ns, isNotNull);
      expect(ns!.id, 'juznobacki');

      final bg = SerbianDistricts.findDistrictForCity('Zemun');
      expect(bg, isNotNull);
      expect(bg!.id, 'beogradski');

      final unknown = SerbianDistricts.findDistrictForCity('NepoznatGrad123');
      expect(unknown, isNull);
    });
  });

  group('ClassifiedAttributesEngine - Real Estate Schemas', () {
    test('returns apartment attributes for stanovi categories', () {
      final attrs = ClassifiedAttributesEngine.getAttributesForCategory('stanovi');
      expect(attrs.any((a) => a.key == 'area_m2'), isTrue);
      expect(attrs.any((a) => a.key == 'rooms'), isTrue);
      expect(attrs.any((a) => a.key == 'floor'), isTrue);
      expect(attrs.any((a) => a.key == 'heating'), isTrue);
      expect(attrs.any((a) => a.key == 'registered'), isTrue);
    });

    test('returns house and homestead attributes for kuce_domacinstva', () {
      final attrs = ClassifiedAttributesEngine.getAttributesForCategory('seoska_domacinstva');
      expect(attrs.any((a) => a.key == 'area_m2'), isTrue);
      expect(attrs.any((a) => a.key == 'land_area_ari'), isTrue);
      expect(attrs.any((a) => a.key == 'homestead_ready'), isTrue);
    });

    test('returns land attributes for poljoprivredno_zemljiste and placevi', () {
      final landAttrs = ClassifiedAttributesEngine.getAttributesForCategory('njive_oranice');
      expect(landAttrs.any((a) => a.key == 'land_area_ari'), isTrue);
      expect(landAttrs.any((a) => a.key == 'water_access'), isTrue);
      expect(landAttrs.any((a) => a.key == 'road_access'), isTrue);

      final plotAttrs = ClassifiedAttributesEngine.getAttributesForCategory('gradjevinski_placevi');
      expect(plotAttrs.any((a) => a.key == 'land_area_ari'), isTrue);
      expect(plotAttrs.any((a) => a.key == 'electricity_access'), isTrue);
    });

    test('findAttributeByKey resolves real estate attributes metadata', () {
      final areaAttr = ClassifiedAttributesEngine.findAttributeByKey('area_m2');
      expect(areaAttr, isNotNull);
      expect(areaAttr!.unit, 'm²');

      final landAttr = ClassifiedAttributesEngine.findAttributeByKey('land_area_ari');
      expect(landAttr, isNotNull);
      expect(landAttr!.unit, 'ar');
    });
  });

  group('ClassifiedAdModel - Real Estate Calculations', () {
    test('calculates pricePerM2 accurately', () {
      final ad = ClassifiedAdModel(
        id: 'ad-re-1',
        userId: 'user-1',
        title: 'Trosoban stan kod Arene',
        price: 150000.0,
        currency: 'EUR',
        categoryId: 'stanovi',
        city: 'Novi Beograd',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attributes: {
          'area_m2': 75.0,
          'rooms': '3.0',
          'floor': '4',
          'transaction_type': 'prodaja',
        },
      );

      expect(ad.isRealEstate, isTrue);
      expect(ad.realEstateAreaM2, 75.0);
      expect(ad.realEstateRooms, '3.0');
      expect(ad.realEstateFloor, '4');
      expect(ad.pricePerM2, 2000.0);
      expect(ad.pricePerAr, isNull);
    });

    test('calculates pricePerAr for land and parcels', () {
      final ad = ClassifiedAdModel(
        id: 'ad-re-2',
        userId: 'user-1',
        title: 'Plac na Kosmaju',
        price: 30000.0,
        currency: 'EUR',
        categoryId: 'gradjevinski_placevi',
        city: 'Sopot',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attributes: {
          'land_area_ari': 20.0,
          'transaction_type': 'prodaja',
        },
      );

      expect(ad.isRealEstate, isTrue);
      expect(ad.realEstateLandAreaAri, 20.0);
      expect(ad.pricePerAr, 1500.0);
      expect(ad.pricePerM2, isNull);
    });
  });

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            height: 480,
            child: child,
          ),
        ),
      ),
    );
  }

  group('ClassifiedAdCard - Real Estate Widget Rendering', () {
    testWidgets('renders unit price pill and specs line for apartment', (tester) async {
      final ad = ClassifiedAdModel(
        id: 'ad-re-widget-1',
        userId: 'user-1',
        title: 'Moderan stan u centru',
        price: 120000.0,
        currency: 'EUR',
        categoryId: 'stanovi',
        city: 'Novi Sad',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        updatedAt: DateTime.now(),
        attributes: {
          'area_m2': 60.0,
          'rooms': '2.5',
          'floor': '2',
          'transaction_type': 'prodaja',
        },
      );

      await tester.pumpWidget(buildTestWidget(ClassifiedAdCard(ad: ad)));
      await tester.pumpAndSettle();

      // Provera naslova i cene
      expect(find.text('Moderan stan u centru'), findsOneWidget);
      expect(find.text('120.000'), findsOneWidget);

      // Provera automatski izračunate cene po kvadratu (~2000 EUR/m²)
      expect(find.text('2000 EUR/m²'), findsOneWidget);

      // Provera specifikacija nekretnine (m², sobe, sprat)
      expect(find.text('60 m²'), findsOneWidget);
      expect(find.text('2.5 sobe'), findsOneWidget);
      expect(find.text('2. sprat'), findsOneWidget);

      // Provera bedža transakcije (PRODAJA)
      expect(find.text('PRODAJA'), findsOneWidget);
    });

    testWidgets('renders price per ar and transaction badge for rental or land', (tester) async {
      final ad = ClassifiedAdModel(
        id: 'ad-re-widget-2',
        userId: 'user-1',
        title: 'Vikendica na Tari uz reku',
        price: 450.0,
        currency: 'EUR',
        categoryId: 'vikendice',
        city: 'Bajina Bašta',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now(),
        attributes: {
          'area_m2': 45.0,
          'land_area_ari': 10.0,
          'transaction_type': 'izdavanje',
        },
      );

      await tester.pumpWidget(buildTestWidget(ClassifiedAdCard(ad: ad)));
      await tester.pumpAndSettle();

      expect(find.text('Vikendica na Tari uz reku'), findsOneWidget);
      expect(find.text('450'), findsOneWidget);

      // Provera cene po m² (450 / 45 = 10 EUR/m²)
      expect(find.text('10 EUR/m²'), findsOneWidget);

      // Provera bedža transakcije
      expect(find.text('IZDAVANJE'), findsOneWidget);
      expect(find.text('45 m²'), findsOneWidget);
      expect(find.text('10 ar'), findsOneWidget);
    });
  });
}

