import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/classified_report_model.dart';

/// Servis za prijavljivanje nepravilnosti, prevara i administratorsku moderaciju oglasa
class ClassifiedReportsService {
  ClassifiedReportsService({SupabaseClient? client}) : _customClient = client;
  ClassifiedReportsService.test() : _customClient = null;

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  /// Podnosi novu prijavu za oglas.
  /// Baca [Exception] sa korisničkom porukom ukoliko oglas ne postoji,
  /// korisnik nije prijavljen ili je već prijavio isti oglas.
  Future<bool> submitReport({
    required String adId,
    required String reason,
    String? details,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Morate biti prijavljeni da biste prijavili oglas.');
    }

    try {
      await _client.from('classified_ad_reports').insert({
        'ad_id': adId,
        'reporter_id': user.id,
        'reason': reason,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
        'status': 'pending',
      });
      return true;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception(
          'Već ste prijavili ovaj oglas. Naš tim ga trenutno pregleda.',
        );
      }
      throw Exception('Greška pri podnošenju prijave: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Neočekivana greška pri prijavljivanju oglasa: $e');
    }
  }

  /// Proverava da li je trenutno ulogovani korisnik već prijavio dati oglas.
  Future<bool> hasUserReported(String adId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final res = await _client
          .from('classified_ad_reports')
          .select('id')
          .eq('ad_id', adId)
          .eq('reporter_id', user.id)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  /// Preuzima listu prijava koje je podneo trenutni korisnik.
  Future<List<ClassifiedAdReportModel>> getUserReports() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final res = await _client
          .from('classified_ad_reports')
          .select()
          .eq('reporter_id', user.id)
          .order('created_at', ascending: false);

      return (res as List)
          .map((e) => ClassifiedAdReportModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// [Admin] Preuzima listu prijava za moderaciju sa povezanim oglasima i profilima prijavljivača.
  Future<List<ClassifiedAdReportModel>> getModerationReports({
    String? status,
    String? reason,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      dynamic query = _client.from('classified_ad_reports').select('''
        *,
        classified_ads(id, title, price, currency, images, status, reports_count, user_id),
        reporter:profiles!reporter_id(display_name, farm_name)
      ''');

      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }
      if (reason != null && reason.isNotEmpty) {
        query = query.eq('reason', reason);
      }

      final res = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (res as List)
          .map((e) => ClassifiedAdReportModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// [Admin] Vraća ukupan broj prijava koje su na čekanju ('pending').
  Future<int> getPendingReportsCount() async {
    try {
      final count = await _client
          .from('classified_ad_reports')
          .count(CountOption.exact)
          .eq('status', 'pending');
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// [Admin] Sprovođenje moderatorske akcije nad prijavom i oglasom preko RPC [moderate_classified_ad].
  ///
  /// Podržane akcije:
  /// - `dismiss`: Odbacuje prijavu kao neosnovanu.
  /// - `resolve_reviewed`: Označava prijavu pregledanom (oglas ostaje aktivan).
  /// - `deactivate_ad`: Uklanja/deaktivira oglas (status 'rejected') i obaveštava oglašivača.
  Future<bool> moderateReport({
    required String reportId,
    required String adId,
    required String action,
    String? note,
  }) async {
    try {
      final res = await _client.rpc(
        'moderate_classified_ad',
        params: {
          'p_report_id': reportId,
          'p_ad_id': adId,
          'p_action': action,
          if (note != null && note.trim().isNotEmpty) 'p_note': note.trim(),
        },
      );
      if (res is Map && res['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Greška pri sprovođenju moderatorske akcije: $e');
    }
  }
}
