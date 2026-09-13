/// Agregirana statistika i analitika oglasa za prodavca
class ClassifiedSellerStatsModel {
  final int totalAds;
  final int activeAds;
  final int soldAds;
  final int totalViews;
  final int totalCallClicks;
  final int totalShares;
  final int featuredCount;
  final String? topAdId;
  final String? topAdTitle;
  final int topAdViews;
  final int topAdCallClicks;
  final double topAdPrice;
  final String topAdCurrency;
  final String? topAdImage;

  const ClassifiedSellerStatsModel({
    this.totalAds = 0,
    this.activeAds = 0,
    this.soldAds = 0,
    this.totalViews = 0,
    this.totalCallClicks = 0,
    this.totalShares = 0,
    this.featuredCount = 0,
    this.topAdId,
    this.topAdTitle,
    this.topAdViews = 0,
    this.topAdCallClicks = 0,
    this.topAdPrice = 0.0,
    this.topAdCurrency = 'RSD',
    this.topAdImage,
  });

  bool get hasAds => totalAds > 0;
  bool get hasTopAd => topAdId != null && topAdTitle != null;

  factory ClassifiedSellerStatsModel.fromJson(Map<String, dynamic> json) {
    final topAd = json['top_ad'] as Map<String, dynamic>?;

    return ClassifiedSellerStatsModel(
      totalAds: (json['total_ads'] as num?)?.toInt() ?? 0,
      activeAds: (json['active_ads'] as num?)?.toInt() ?? 0,
      soldAds: (json['sold_ads'] as num?)?.toInt() ?? 0,
      totalViews: (json['total_views'] as num?)?.toInt() ?? 0,
      totalCallClicks: (json['total_call_clicks'] as num?)?.toInt() ?? 0,
      totalShares: (json['total_shares'] as num?)?.toInt() ?? 0,
      featuredCount: (json['featured_count'] as num?)?.toInt() ?? 0,
      topAdId: topAd?['id'] as String? ?? json['top_ad_id'] as String?,
      topAdTitle: topAd?['title'] as String? ?? json['top_ad_title'] as String?,
      topAdViews: (topAd?['views_count'] as num?)?.toInt() ??
          (json['top_ad_views'] as num?)?.toInt() ??
          0,
      topAdCallClicks: (topAd?['call_clicks_count'] as num?)?.toInt() ??
          (json['top_ad_call_clicks'] as num?)?.toInt() ??
          0,
      topAdPrice: (topAd?['price'] as num?)?.toDouble() ??
          (json['top_ad_price'] as num?)?.toDouble() ??
          0.0,
      topAdCurrency: topAd?['currency'] as String? ??
          json['top_ad_currency'] as String? ??
          'RSD',
      topAdImage:
          topAd?['image'] as String? ?? json['top_ad_image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_ads': totalAds,
      'active_ads': activeAds,
      'sold_ads': soldAds,
      'total_views': totalViews,
      'total_call_clicks': totalCallClicks,
      'total_shares': totalShares,
      'featured_count': featuredCount,
      if (topAdId != null)
        'top_ad': {
          'id': topAdId,
          'title': topAdTitle,
          'views_count': topAdViews,
          'call_clicks_count': topAdCallClicks,
          'price': topAdPrice,
          'currency': topAdCurrency,
          if (topAdImage != null) 'image': topAdImage,
        },
    };
  }
}
