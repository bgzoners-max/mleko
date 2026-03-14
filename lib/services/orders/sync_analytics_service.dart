import 'package:shared_preferences/shared_preferences.dart';

class SyncAnalyticsSnapshot {
  final int totalRuns;
  final int totalAttempted;
  final int totalSynced;
  final int totalDuplicates;
  final int totalFailed;
  final DateTime? lastRunAt;
  final String? lastSource;
  final int lastDurationMs;
  final int lastAttempted;
  final int lastSynced;
  final int lastDuplicates;
  final int lastFailed;
  final bool lastSkippedOffline;

  const SyncAnalyticsSnapshot({
    required this.totalRuns,
    required this.totalAttempted,
    required this.totalSynced,
    required this.totalDuplicates,
    required this.totalFailed,
    required this.lastRunAt,
    required this.lastSource,
    required this.lastDurationMs,
    required this.lastAttempted,
    required this.lastSynced,
    required this.lastDuplicates,
    required this.lastFailed,
    required this.lastSkippedOffline,
  });
}

class SyncAnalyticsService {
  static const _kPrefix = 'mleko_sync_analytics_';
  static const _kTotalRuns = '${_kPrefix}total_runs';
  static const _kTotalAttempted = '${_kPrefix}total_attempted';
  static const _kTotalSynced = '${_kPrefix}total_synced';
  static const _kTotalDuplicates = '${_kPrefix}total_duplicates';
  static const _kTotalFailed = '${_kPrefix}total_failed';
  static const _kLastRunAt = '${_kPrefix}last_run_at';
  static const _kLastSource = '${_kPrefix}last_source';
  static const _kLastDurationMs = '${_kPrefix}last_duration_ms';
  static const _kLastAttempted = '${_kPrefix}last_attempted';
  static const _kLastSynced = '${_kPrefix}last_synced';
  static const _kLastDuplicates = '${_kPrefix}last_duplicates';
  static const _kLastFailed = '${_kPrefix}last_failed';
  static const _kLastSkippedOffline = '${_kPrefix}last_skipped_offline';

  Future<void> recordRun({
    required String source,
    required int attempted,
    required int synced,
    required int duplicates,
    required int failed,
    required Duration duration,
    required bool skippedOffline,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_kTotalRuns, (prefs.getInt(_kTotalRuns) ?? 0) + 1);
    await prefs.setInt(
        _kTotalAttempted, (prefs.getInt(_kTotalAttempted) ?? 0) + attempted);
    await prefs.setInt(
        _kTotalSynced, (prefs.getInt(_kTotalSynced) ?? 0) + synced);
    await prefs.setInt(_kTotalDuplicates,
        (prefs.getInt(_kTotalDuplicates) ?? 0) + duplicates);
    await prefs.setInt(_kTotalFailed, (prefs.getInt(_kTotalFailed) ?? 0) + failed);

    await prefs.setString(_kLastRunAt, DateTime.now().toIso8601String());
    await prefs.setString(_kLastSource, source);
    await prefs.setInt(_kLastDurationMs, duration.inMilliseconds);
    await prefs.setInt(_kLastAttempted, attempted);
    await prefs.setInt(_kLastSynced, synced);
    await prefs.setInt(_kLastDuplicates, duplicates);
    await prefs.setInt(_kLastFailed, failed);
    await prefs.setBool(_kLastSkippedOffline, skippedOffline);
  }

  Future<SyncAnalyticsSnapshot> getSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRunRaw = prefs.getString(_kLastRunAt);
    return SyncAnalyticsSnapshot(
      totalRuns: prefs.getInt(_kTotalRuns) ?? 0,
      totalAttempted: prefs.getInt(_kTotalAttempted) ?? 0,
      totalSynced: prefs.getInt(_kTotalSynced) ?? 0,
      totalDuplicates: prefs.getInt(_kTotalDuplicates) ?? 0,
      totalFailed: prefs.getInt(_kTotalFailed) ?? 0,
      lastRunAt: lastRunRaw != null ? DateTime.tryParse(lastRunRaw) : null,
      lastSource: prefs.getString(_kLastSource),
      lastDurationMs: prefs.getInt(_kLastDurationMs) ?? 0,
      lastAttempted: prefs.getInt(_kLastAttempted) ?? 0,
      lastSynced: prefs.getInt(_kLastSynced) ?? 0,
      lastDuplicates: prefs.getInt(_kLastDuplicates) ?? 0,
      lastFailed: prefs.getInt(_kLastFailed) ?? 0,
      lastSkippedOffline: prefs.getBool(_kLastSkippedOffline) ?? false,
    );
  }
}
