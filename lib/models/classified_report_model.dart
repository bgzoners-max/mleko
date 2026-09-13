import 'package:flutter/material.dart';

/// Razlozi za prijavu oglasa
class ClassifiedReportReason {
  static const String fraudScam = 'fraud_scam';
  static const String spamDuplicate = 'spam_duplicate';
  static const String inappropriate = 'inappropriate';
  static const String wrongCategory = 'wrong_category';
  static const String soldUnavailable = 'sold_unavailable';
  static const String other = 'other';

  static const List<String> all = [
    fraudScam,
    spamDuplicate,
    inappropriate,
    wrongCategory,
    soldUnavailable,
    other,
  ];

  static String labelFor(String reason) {
    switch (reason) {
      case fraudScam:
        return 'Sumnja na prevaru ili lažan oglas';
      case spamDuplicate:
        return 'Spam ili višestruko postavljen oglas';
      case inappropriate:
        return 'Neprikladan ili uvredljiv sadržaj';
      case wrongCategory:
        return 'Pogrešna kategorija ili netačni podaci';
      case soldUnavailable:
        return 'Predmet je prodat ili više nije dostupan';
      case other:
        return 'Ostalo (opišite detaljnije)';
      default:
        return reason;
    }
  }

  static IconData iconFor(String reason) {
    switch (reason) {
      case fraudScam:
        return Icons.gpp_maybe_outlined;
      case spamDuplicate:
        return Icons.content_copy_outlined;
      case inappropriate:
        return Icons.block_outlined;
      case wrongCategory:
        return Icons.category_outlined;
      case soldUnavailable:
        return Icons.remove_shopping_cart_outlined;
      case other:
        return Icons.help_outline_rounded;
      default:
        return Icons.flag_outlined;
    }
  }
}

/// Model prijave nepravilnosti ili sumnjivog oglasa
class ClassifiedAdReportModel {
  final String id;
  final String adId;
  final String reporterId;
  final String reason;
  final String? details;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  // Pridruženi podaci za administratorski pregled
  final String? adTitle;
  final double? adPrice;
  final String? adCurrency;
  final List<String> adImages;
  final String? adStatus;
  final int? adReportsCount;
  final String? sellerId;
  final String? reporterName;

  const ClassifiedAdReportModel({
    required this.id,
    required this.adId,
    required this.reporterId,
    required this.reason,
    this.details,
    this.status = 'pending',
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.adTitle,
    this.adPrice,
    this.adCurrency,
    this.adImages = const [],
    this.adStatus,
    this.adReportsCount,
    this.sellerId,
    this.reporterName,
  });

  bool get isPending => status == 'pending';
  bool get isReviewed => status == 'reviewed';
  bool get isDismissed => status == 'dismissed';
  bool get isAdRemoved => status == 'ad_removed';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Na čekanju';
      case 'reviewed':
        return 'Pregledano';
      case 'dismissed':
        return 'Odbačeno';
      case 'ad_removed':
        return 'Oglas uklonjen';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange.shade800;
      case 'reviewed':
        return Colors.blue.shade700;
      case 'dismissed':
        return Colors.grey.shade600;
      case 'ad_removed':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  factory ClassifiedAdReportModel.fromJson(Map<String, dynamic> json) {
    final adData = json['classified_ads'] is Map
        ? json['classified_ads'] as Map<String, dynamic>
        : null;
    final reporterData = json['reporter'] is Map
        ? json['reporter'] as Map<String, dynamic>
        : null;

    final parsedImages = (json['ad_images'] as List?)?.map((e) => e.toString()).toList() ??
        (adData?['images'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];

    return ClassifiedAdReportModel(
      id: json['id'] as String? ?? '',
      adId: json['ad_id'] as String? ?? '',
      reporterId: json['reporter_id'] as String? ?? '',
      reason: json['reason'] as String? ?? ClassifiedReportReason.other,
      details: json['details'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as String?,
      adTitle: json['ad_title'] as String? ?? adData?['title'] as String?,
      adPrice: json['ad_price'] != null
          ? (json['ad_price'] as num).toDouble()
          : (adData?['price'] != null
              ? (adData!['price'] as num).toDouble()
              : null),
      adCurrency: json['ad_currency'] as String? ??
          adData?['currency'] as String? ??
          'RSD',
      adImages: parsedImages,
      adStatus: json['ad_status'] as String? ?? adData?['status'] as String?,
      adReportsCount: json['ad_reports_count'] as int? ??
          adData?['reports_count'] as int?,
      sellerId: json['seller_id'] as String? ?? adData?['user_id'] as String?,
      reporterName: json['reporter_name'] as String? ??
          reporterData?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'ad_id': adId,
      'reporter_id': reporterId,
      'reason': reason,
      if (details != null && details!.trim().isNotEmpty)
        'details': details!.trim(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
      if (resolvedBy != null) 'resolved_by': resolvedBy,
      if (adTitle != null) 'ad_title': adTitle,
      if (adPrice != null) 'ad_price': adPrice,
      if (adCurrency != null) 'ad_currency': adCurrency,
      if (adImages.isNotEmpty) 'ad_images': adImages,
      if (adStatus != null) 'ad_status': adStatus,
      if (adReportsCount != null) 'ad_reports_count': adReportsCount,
      if (sellerId != null) 'seller_id': sellerId,
      if (reporterName != null) 'reporter_name': reporterName,
    };
  }

  ClassifiedAdReportModel copyWith({
    String? id,
    String? adId,
    String? reporterId,
    String? reason,
    String? details,
    String? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? adTitle,
    double? adPrice,
    String? adCurrency,
    List<String>? adImages,
    String? adStatus,
    int? adReportsCount,
    String? sellerId,
    String? reporterName,
  }) {
    return ClassifiedAdReportModel(
      id: id ?? this.id,
      adId: adId ?? this.adId,
      reporterId: reporterId ?? this.reporterId,
      reason: reason ?? this.reason,
      details: details ?? this.details,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      adTitle: adTitle ?? this.adTitle,
      adPrice: adPrice ?? this.adPrice,
      adCurrency: adCurrency ?? this.adCurrency,
      adImages: adImages ?? this.adImages,
      adStatus: adStatus ?? this.adStatus,
      adReportsCount: adReportsCount ?? this.adReportsCount,
      sellerId: sellerId ?? this.sellerId,
      reporterName: reporterName ?? this.reporterName,
    );
  }
}
