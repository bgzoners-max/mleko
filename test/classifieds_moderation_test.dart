import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/classified_report_model.dart';
import 'package:mleko/screens/admin/classifieds_moderation_screen.dart';
import 'package:mleko/services/classifieds/classified_reports_service.dart';

class FakeClassifiedReportsService extends ClassifiedReportsService {
  FakeClassifiedReportsService({
    required this.mockReports,
  }) : super.test();

  final List<ClassifiedAdReportModel> mockReports;
  final List<String> actionsCalled = [];

  @override
  Future<List<ClassifiedAdReportModel>> getModerationReports({
    String? status,
    String? reason,
    int limit = 50,
    int offset = 0,
  }) async {
    return mockReports.where((r) {
      if (status != null && r.status != status) return false;
      if (reason != null && r.reason != reason) return false;
      return true;
    }).toList();
  }

  @override
  Future<int> getPendingReportsCount() async {
    return mockReports.where((r) => r.isPending).length;
  }

  @override
  Future<bool> moderateReport({
    required String reportId,
    required String adId,
    required String action,
    String? note,
  }) async {
    actionsCalled.add('$action:$reportId:$adId');
    return true;
  }
}

void main() {
  group('ClassifiedAdReportModel moderation extensions', () {
    test('getters correctly reflect statuses and colors', () {
      final now = DateTime.now();

      final pendingReport = ClassifiedAdReportModel(
        id: 'r1',
        adId: 'ad1',
        reporterId: 'u1',
        reason: ClassifiedReportReason.fraudScam,
        status: 'pending',
        createdAt: now,
        adTitle: 'Traktor IMT 539',
        adPrice: 4500,
        adCurrency: 'EUR',
        adReportsCount: 2,
      );

      expect(pendingReport.isPending, isTrue);
      expect(pendingReport.isReviewed, isFalse);
      expect(pendingReport.isDismissed, isFalse);
      expect(pendingReport.isAdRemoved, isFalse);
      expect(pendingReport.statusLabel, 'Na čekanju');
      expect(pendingReport.statusColor, isNotNull);
      expect(pendingReport.adReportsCount, 2);

      final removedReport = pendingReport.copyWith(status: 'ad_removed');
      expect(removedReport.isAdRemoved, isTrue);
      expect(removedReport.statusLabel, 'Oglas uklonjen');

      final reviewedReport = pendingReport.copyWith(status: 'reviewed');
      expect(reviewedReport.isReviewed, isTrue);
      expect(reviewedReport.statusLabel, 'Pregledano');

      final dismissedReport = pendingReport.copyWith(status: 'dismissed');
      expect(dismissedReport.isDismissed, isTrue);
      expect(dismissedReport.statusLabel, 'Odbačeno');
    });

    test('serializes and deserializes joined classified_ads and reporter data', () {
      final json = {
        'id': 'rep-join-1',
        'ad_id': 'ad-100',
        'reporter_id': 'user-200',
        'reason': 'inappropriate',
        'details': 'Slike sadrže uvredljiv natpis',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'classified_ads': {
          'title': 'Kosačica BCS 622',
          'price': 1500,
          'currency': 'EUR',
          'images': ['https://example.com/kosa.jpg'],
          'status': 'active',
          'reports_count': 3,
          'user_id': 'seller-300',
        },
        'reporter': {
          'full_name': 'Petar Petrović',
        },
      };

      final model = ClassifiedAdReportModel.fromJson(json);
      expect(model.id, 'rep-join-1');
      expect(model.adTitle, 'Kosačica BCS 622');
      expect(model.adPrice, 1500.0);
      expect(model.adCurrency, 'EUR');
      expect(model.adImages, contains('https://example.com/kosa.jpg'));
      expect(model.adReportsCount, 3);
      expect(model.sellerId, 'seller-300');
      expect(model.reporterName, 'Petar Petrović');
    });
  });

  group('ClassifiedsModerationScreen Widget Tests', () {
    final testReports = [
      ClassifiedAdReportModel(
        id: 'rep-1',
        adId: 'ad-1',
        reporterId: 'u-1',
        reason: ClassifiedReportReason.fraudScam,
        details: 'Korisnik traži kaparu preko SMS-a.',
        status: 'pending',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        adTitle: 'Zetor Proxima 85',
        adPrice: 18000,
        adCurrency: 'EUR',
        adReportsCount: 2,
        reporterName: 'Jovan J.',
      ),
      ClassifiedAdReportModel(
        id: 'rep-2',
        adId: 'ad-2',
        reporterId: 'u-2',
        reason: ClassifiedReportReason.spamDuplicate,
        status: 'ad_removed',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        adTitle: 'Balirka Claas Markant',
        adPrice: 3200,
        adCurrency: 'EUR',
        adReportsCount: 1,
      ),
    ];

    Widget buildTestWidget({required ClassifiedReportsService service}) {
      return MaterialApp(
        home: ClassifiedsModerationScreen(
          reportsService: service,
        ),
      );
    }

    testWidgets('renders tabs, KPI section, and reports list', (tester) async {
      final fakeService = FakeClassifiedReportsService(mockReports: testReports);

      await tester.pumpWidget(buildTestWidget(service: fakeService));
      await tester.pumpAndSettle();

      // Provera naslova
      expect(find.text('Moderacija oglasa'), findsOneWidget);

      // Provera tabova
      expect(find.text('Na čekanju'), findsWidgets);
      expect(find.text('Uklonjeni'), findsWidgets);
      expect(find.text('Pregledani'), findsWidgets);
      expect(find.text('Sve prijave'), findsOneWidget);

      // Provera KPI kartica i brojača
      expect(find.text('1'), findsWidgets); // 1 pending, 1 removed

      // Provera prikaza prvog oglasa u tabu 'Na čekanju'
      expect(find.text('Zetor Proxima 85'), findsOneWidget);
      expect(find.text('18000 EUR'), findsOneWidget);
      expect(find.text('2 prijave za oglas'), findsOneWidget);
      expect(find.text('Prijavio: Jovan J.'), findsOneWidget);
      expect(find.text('"Korisnik traži kaparu preko SMS-a."'), findsOneWidget);

      // Provera akcionih dugmadi za oglas na čekanju
      expect(find.text('Pogledaj oglas'), findsOneWidget);
      expect(find.text('Ukloni oglas'), findsOneWidget);
      expect(find.text('Ispravan'), findsOneWidget);
      expect(find.text('Odbaci prijavu'), findsOneWidget);
    });

    testWidgets('switching tabs filters reports by status', (tester) async {
      final fakeService = FakeClassifiedReportsService(mockReports: testReports);

      await tester.pumpWidget(buildTestWidget(service: fakeService));
      await tester.pumpAndSettle();

      // U tabu 'Na čekanju' je Zetor
      expect(find.text('Zetor Proxima 85'), findsOneWidget);
      expect(find.text('Balirka Claas Markant'), findsNothing);

      // Prebacivanje na tab 'Uklonjeni'
      await tester.tap(find.widgetWithText(Tab, 'Uklonjeni'));
      await tester.pumpAndSettle();

      // U tabu 'Uklonjeni' je Balirka
      expect(find.text('Balirka Claas Markant'), findsOneWidget);
      expect(find.text('Zetor Proxima 85'), findsNothing);
    });

    testWidgets('tapping Ukloni oglas opens dialog with notification message', (tester) async {
      final fakeService = FakeClassifiedReportsService(mockReports: testReports);

      await tester.pumpWidget(buildTestWidget(service: fakeService));
      await tester.pumpAndSettle();

      // Klik na dugme 'Ukloni oglas' na kartici
      final removeBtn = find.widgetWithText(FilledButton, 'Ukloni oglas');
      expect(removeBtn, findsOneWidget);
      await tester.tap(removeBtn);
      await tester.pumpAndSettle();

      // Otvara se modalni dijalog
      expect(find.text('Poruka oglašivaču (notifikacija):'), findsOneWidget);
      expect(find.text('Odustani'), findsOneWidget);

      // Potvrdi uklanjanje u dijalogu klikom na FilledButton unutar AlertDialog-a
      final confirmBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Ukloni oglas'),
      );
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Provera da je pozvana akcija deactivate_ad
      expect(fakeService.actionsCalled, contains('deactivate_ad:rep-1:ad-1'));
    });

    testWidgets('empty state renders when no reports match', (tester) async {
      final fakeService = FakeClassifiedReportsService(mockReports: []);

      await tester.pumpWidget(buildTestWidget(service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Nema prijava za prikaz'), findsOneWidget);
      expect(find.text('Sve prijave u ovoj kategoriji su obrađene.'), findsOneWidget);
    });
  });
}
