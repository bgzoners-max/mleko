import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Podaci o zvaničnom srednjem kursu EUR/RSD (Narodna banka Srbije).
class EurRateInfo {
  const EurRateInfo({
    required this.middle,
    this.date,
    this.listNumber,
    this.source = defaultSource,
    this.provider = defaultProvider,
    this.isFallback = false,
  });

  static const double defaultFallbackMiddle = 117.65;
  static const String defaultSource = 'Narodna banka Srbije (NBS)';
  static const String defaultProvider = 'kurs.resenje.org';

  static const EurRateInfo fallback = EurRateInfo(
    middle: defaultFallbackMiddle,
    isFallback: true,
  );

  final double middle;
  final String? date;
  final int? listNumber;
  final String source;
  final String provider;
  final bool isFallback;

  /// Datum u domaćem formatu (`23.11.2026.`), ili `null` ako datum nije poznat.
  String? get formattedDate {
    if (date == null || date!.trim().isEmpty) return null;
    final parts = date!.trim().split('-');
    if (parts.length == 3) {
      return '${parts[2]}.${parts[1]}.${parts[0]}.';
    }
    return date;
  }

  /// Kratak prikaz kursa sa izvorom za utility traku.
  String get shortLabel {
    final formatted = middle.toStringAsFixed(2).replaceAll('.', ',');
    if (isFallback) {
      return 'NBS (orijentaciono): 1 € ≈ $formatted RSD';
    }
    return 'NBS: 1 € = $formatted RSD';
  }

  /// Pun opis izvora i datuma važenja za tooltip.
  String get sourceTooltip {
    final formatted = middle.toStringAsFixed(4).replaceAll('.', ',');
    if (isFallback) {
      return 'Orijentacioni srednji kurs (1 € ≈ $formatted RSD). Izvor: $source.';
    }
    final datePart = formattedDate != null ? ', $formattedDate' : '';
    final listPart = listNumber != null ? 'lista br. $listNumber' : '';
    final meta = [if (listPart.isNotEmpty) listPart, if (datePart.isNotEmpty) datePart.substring(2)]
        .join(', ');
    final metaText = meta.isNotEmpty ? ' ($meta)' : '';
    return 'Zvanični srednji kurs: 1 € = $formatted RSD$metaText · Izvor: $source ($provider)';
  }

  factory EurRateInfo.fromJson(Map<String, dynamic> json) {
    final rawMiddle = (json['middle'] as num?)?.toDouble() ??
        (json['exchange_middle'] as num?)?.toDouble();
    final isValid = rawMiddle != null && rawMiddle > 50 && rawMiddle < 300;
    return EurRateInfo(
      middle: isValid ? rawMiddle : defaultFallbackMiddle,
      date: json['date'] as String?,
      listNumber: (json['listNumber'] as num?)?.toInt() ??
          (json['number'] as num?)?.toInt(),
      source: (json['source'] as String?)?.trim().isNotEmpty == true
          ? (json['source'] as String).trim()
          : defaultSource,
      provider: (json['provider'] as String?)?.trim().isNotEmpty == true
          ? (json['provider'] as String).trim()
          : defaultProvider,
      isFallback: !isValid || (json['isFallback'] as bool? ?? false),
    );
  }

  Map<String, dynamic> toJson() => {
        'middle': middle,
        'date': date,
        'listNumber': listNumber,
        'source': source,
        'provider': provider,
        'isFallback': isFallback,
      };
}

/// Servis za učitavanje i lokalno keširanje zvaničnog srednjeg kursa EUR/RSD (NBS)
/// preko našeg Cloudflare Pages endpointa `/api/eur-rate`.
class ExchangeRateService {
  ExchangeRateService._();

  static final ExchangeRateService instance = ExchangeRateService._();

  static const String _cacheKey = 'cached_nbs_eur_rate_v1';
  static const Duration _cacheTtl = Duration(hours: 6);
  static const String _productionEndpoint =
      'https://www.domacimarket.rs/api/eur-rate';

  final ValueNotifier<EurRateInfo> rateNotifier =
      ValueNotifier<EurRateInfo>(EurRateInfo.fallback);

  DateTime? _lastFetchedAt;
  Future<EurRateInfo>? _inFlight;

  EurRateInfo get current => rateNotifier.value;
  double get currentRate => rateNotifier.value.middle;

  Uri _resolveEndpoint() {
    if (kIsWeb) {
      final base = Uri.base;
      if (base.scheme == 'http' || base.scheme == 'https') {
        return base.resolve('/api/eur-rate');
      }
    }
    return Uri.parse(_productionEndpoint);
  }

  /// Učitava kurs iz lokalnog keša ili sa `/api/eur-rate` (najviše jednom u 6 sati).
  Future<EurRateInfo> ensureLoaded({bool forceRefresh = false}) {
    if (!forceRefresh &&
        _lastFetchedAt != null &&
        DateTime.now().difference(_lastFetchedAt!) < _cacheTtl &&
        !rateNotifier.value.isFallback) {
      return Future<EurRateInfo>.value(rateNotifier.value);
    }

    if (_inFlight != null) return _inFlight!;
    _inFlight = _loadInternal(forceRefresh: forceRefresh).whenComplete(() {
      _inFlight = null;
    });
    return _inFlight!;
  }

  Future<EurRateInfo> _loadInternal({required bool forceRefresh}) async {
    if (!forceRefresh) {
      final cached = await _readFromCache();
      if (cached != null) {
        rateNotifier.value = cached;
        _lastFetchedAt = DateTime.now();
        return cached;
      }
    }

    try {
      final response = await http
          .get(
            _resolveEndpoint(),
            headers: const {'accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final info = EurRateInfo.fromJson(decoded);
          rateNotifier.value = info;
          _lastFetchedAt = DateTime.now();
          if (!info.isFallback) {
            await _writeToCache(info);
          }
          return info;
        }
      }
    } catch (_) {
      // Zadrži postojeći keš ili fallback bez rušenja UI-ja
    }

    return rateNotifier.value;
  }

  Future<EurRateInfo?> _readFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final fetchedAtRaw = decoded['fetched_at'] as String?;
      final data = decoded['data'];
      if (fetchedAtRaw == null || data is! Map<String, dynamic>) return null;
      final fetchedAt = DateTime.tryParse(fetchedAtRaw);
      if (fetchedAt == null ||
          DateTime.now().difference(fetchedAt) >= _cacheTtl) {
        return null;
      }
      final info = EurRateInfo.fromJson(data);
      return info.isFallback ? null : info;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeToCache(EurRateInfo info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode({
          'fetched_at': DateTime.now().toIso8601String(),
          'data': info.toJson(),
        }),
      );
    } catch (_) {
      // Ignoriši greške pisanja keša
    }
  }

  @visibleForTesting
  void setRateForTesting(EurRateInfo info) {
    rateNotifier.value = info;
    _lastFetchedAt = DateTime.now();
  }

  @visibleForTesting
  void resetForTesting() {
    rateNotifier.value = EurRateInfo.fallback;
    _lastFetchedAt = null;
    _inFlight = null;
  }
}
