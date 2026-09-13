import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/classified_ad_model.dart';
import 'package:mleko/models/classified_report_model.dart';
import 'package:mleko/widgets/classifieds/report_classified_ad_dialog.dart';

void main() {
  group('ClassifiedReportReason', () {
    test('contains all expected reasons', () {
      expect(ClassifiedReportReason.all, contains(ClassifiedReportReason.fraudScam));
      expect(ClassifiedReportReason.all, contains(ClassifiedReportReason.spamDuplicate));
      expect(ClassifiedReportReason.all, contains(ClassifiedReportReason.inappropriate));
      expect(ClassifiedReportReason.all, contains(ClassifiedReportReason.wrongCategory));
      expect(ClassifiedReportReason.all, contains(ClassifiedReportReason.soldUnavailable));
      expect(ClassifiedReportReason.all, contains(ClassifiedReportReason.other));
      expect(ClassifiedReportReason.all.length, 6);
    });

    test('labelFor returns non-empty descriptive label for each reason', () {
      for (final reason in ClassifiedReportReason.all) {
        final label = ClassifiedReportReason.labelFor(reason);
        expect(label, isNotEmpty);
        expect(label, isNot(equals(reason)));
      }
    });

    test('iconFor returns appropriate icon for each reason', () {
      for (final reason in ClassifiedReportReason.all) {
        final icon = ClassifiedReportReason.iconFor(reason);
        expect(icon, isNotNull);
      }
    });
  });

  group('ClassifiedAdReportModel', () {
    test('serializes and deserializes correctly', () {
      final now = DateTime.now();
      final report = ClassifiedAdReportModel(
        id: 'rep-123',
        adId: 'ad-456',
        reporterId: 'user-789',
        reason: ClassifiedReportReason.fraudScam,
        details: 'Korisnik traži uplatu unapred preko neproverene aplikacije.',
        status: 'pending',
        createdAt: now,
      );

      final json = report.toJson();
      expect(json['id'], 'rep-123');
      expect(json['ad_id'], 'ad-456');
      expect(json['reporter_id'], 'user-789');
      expect(json['reason'], 'fraud_scam');
      expect(json['details'], 'Korisnik traži uplatu unapred preko neproverene aplikacije.');
      expect(json['status'], 'pending');
      expect(json['created_at'], now.toIso8601String());

      final parsed = ClassifiedAdReportModel.fromJson(json);
      expect(parsed.id, 'rep-123');
      expect(parsed.adId, 'ad-456');
      expect(parsed.reporterId, 'user-789');
      expect(parsed.reason, ClassifiedReportReason.fraudScam);
      expect(parsed.details, 'Korisnik traži uplatu unapred preko neproverene aplikacije.');
      expect(parsed.status, 'pending');
    });

    test('handles null details and default status gracefully', () {
      final json = {
        'id': 'rep-999',
        'ad_id': 'ad-888',
        'reporter_id': 'user-777',
        'reason': 'other',
        'created_at': DateTime.now().toIso8601String(),
      };

      final parsed = ClassifiedAdReportModel.fromJson(json);
      expect(parsed.details, isNull);
      expect(parsed.status, 'pending');
      expect(parsed.reason, ClassifiedReportReason.other);
    });
  });

  group('ReportClassifiedAdDialog Widget', () {
    final testAd = ClassifiedAdModel(
      id: 'ad-rep-test',
      userId: 'seller-1',
      title: 'Kombajn Zmaj 142',
      price: 12000,
      currency: 'EUR',
      categoryId: 'kombajni',
      city: 'Sombor',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Widget buildTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('renders all report reasons and text field', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SingleChildScrollView(
            child: ReportClassifiedAdDialog(ad: testAd),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prijavi oglas'), findsOneWidget);
      expect(find.text('Kombajn Zmaj 142'), findsOneWidget);
      expect(find.text('Izaberite razlog prijave:'), findsOneWidget);

      // Provera prisustva razloga
      expect(find.text(ClassifiedReportReason.labelFor(ClassifiedReportReason.fraudScam)), findsOneWidget);
      expect(find.text(ClassifiedReportReason.labelFor(ClassifiedReportReason.spamDuplicate)), findsOneWidget);
      expect(find.text(ClassifiedReportReason.labelFor(ClassifiedReportReason.inappropriate)), findsOneWidget);
      expect(find.text(ClassifiedReportReason.labelFor(ClassifiedReportReason.wrongCategory)), findsOneWidget);
      expect(find.text(ClassifiedReportReason.labelFor(ClassifiedReportReason.soldUnavailable)), findsOneWidget);
      expect(find.text(ClassifiedReportReason.labelFor(ClassifiedReportReason.other)), findsOneWidget);

      // Provera dugmadi
      expect(find.text('Odustani'), findsOneWidget);
      expect(find.text('Pošalji prijavu'), findsOneWidget);
    });

    testWidgets('allows selecting different reasons and typing details', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          SingleChildScrollView(
            child: ReportClassifiedAdDialog(ad: testAd),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Klik na drugi razlog (npr. spam)
      final spamLabel = ClassifiedReportReason.labelFor(ClassifiedReportReason.spamDuplicate);
      await tester.tap(find.text(spamLabel));
      await tester.pumpAndSettle();

      // Unos teksta u detalje
      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);
      await tester.enterText(inputField, 'Isti oglas je postavljen tri puta.');
      await tester.pumpAndSettle();

      expect(find.text('Isti oglas je postavljen tri puta.'), findsOneWidget);
    });
  });
}
