import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design_system.dart';
import '../../core/haptic.dart';
import '../../core/responsive.dart';
import '../../core/web_seo.dart';
import '../../models/app_error.dart';
import '../../models/classified_ad_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../services/auth/users_service.dart';
import '../../services/classifieds/classified_ad_favorites_service.dart';
import '../../services/classifieds/classifieds_service.dart';
import '../../services/communication/chat_service.dart';
import '../../services/core/analytics_service.dart';
import '../../services/social/favorite_sellers_service.dart';
import '../../services/social/reviews_service.dart';
import '../../widgets/app_error_retry.dart';
import '../../widgets/app_share_sheet.dart';
import '../../widgets/classifieds/detail/classified_action_buttons.dart';
import '../../widgets/classifieds/detail/classified_detail_content.dart';
import '../../widgets/classifieds/detail/classified_more_from_seller_strip.dart';
import '../../widgets/product/full_screen_image_viewer.dart';

class ClassifiedAdDetailScreen extends StatefulWidget {
  final String adId;

  const ClassifiedAdDetailScreen({super.key, required this.adId});

  @override
  State<ClassifiedAdDetailScreen> createState() =>
      _ClassifiedAdDetailScreenState();
}

class _ClassifiedAdDetailScreenState extends State<ClassifiedAdDetailScreen> {
  late ClassifiedsService _service;
  final _adFavoritesService = ClassifiedAdFavoritesService();
  final _favoriteSellersService = FavoriteSellersService();
  final _usersService = UsersService();
  final _reviewsService = ReviewsService();

  late Future<ClassifiedAdModel?> _adFuture;

  bool _viewIncremented = false;
  String? _revealedPhone;
  bool _isLoadingPhone = false;

  UserModel? _sellerProfile;
  double _sellerAvgRating = 0;
  int _sellerReviewCount = 0;
  List<ClassifiedAdModel> _sellerAllActiveAds = const [];
  List<ClassifiedAdModel> _sellerOtherAds = const [];

  bool _isFollowingSeller = false;
  bool _isTogglingFollow = false;
  bool _isFavorited = false;
  bool _isTogglingFavorite = false;
  int? _favoritesCount;

  @override
  void initState() {
    super.initState();
    _service = context.read<ClassifiedsService>();
    _load();
  }

  @override
  void didUpdateWidget(covariant ClassifiedAdDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adId != widget.adId) {
      _viewIncremented = false;
      _revealedPhone = null;
      _isLoadingPhone = false;
      _sellerProfile = null;
      _sellerAvgRating = 0;
      _sellerReviewCount = 0;
      _sellerAllActiveAds = const [];
      _sellerOtherAds = const [];
      _isFollowingSeller = false;
      _isFavorited = false;
      _favoritesCount = null;
      _load();
    }
  }

  Future<void> _load() async {
    final future = _service.getAd(widget.adId);
    setState(() => _adFuture = future);

    final ad = await future;
    if (ad != null && mounted) {
      setState(() => _favoritesCount = ad.favoritesCount);
      setClassifiedAdSeo(ad);
      unawaited(
        context.read<AnalyticsService>().logViewClassifiedAd(ad),
      );
      if (!_viewIncremented) {
        if (_revealedPhone == null &&
            ad.phone != null &&
            ad.phone!.isNotEmpty) {
          setState(() => _revealedPhone = ad.phone);
        }
        final userId = context.read<AppState>().user?.id;
        if (userId == null || userId != ad.userId) {
          unawaited(_service.incrementViews(widget.adId));
        }
        _viewIncremented = true;
      }
      unawaited(_loadSecondaryData(ad));
    }
  }

  Future<void> _loadSecondaryData(ClassifiedAdModel ad) async {
    final user = context.read<AppState>().user;
    final isLoggedIn = user != null && !user.isGuest;
    final isOwner = isLoggedIn && user.id == ad.userId;

    final profileFuture = _usersService
        .getUser(ad.userId)
        .then<UserModel?>((v) => v, onError: (_, __) => null);
    final statsFuture = _reviewsService
        .getSellerStats(ad.userId)
        .then<dynamic>((v) => v, onError: (_, __) => null);
    final sellerAdsFuture = _service
        .getUserAds(ad.userId)
        .then<List<ClassifiedAdModel>>(
          (v) => v,
          onError: (_, __) => const <ClassifiedAdModel>[],
        );
    final followingFuture = (isLoggedIn && !isOwner)
        ? _favoriteSellersService
            .isFollowing(user.id, ad.userId)
            .then<bool>((v) => v, onError: (_, __) => false)
        : Future<bool>.value(false);
    final favoritedFuture = (isLoggedIn && !isOwner)
        ? _adFavoritesService
            .isFavorite(user.id, ad.id)
            .then<bool>((v) => v, onError: (_, __) => false)
        : Future<bool>.value(false);

    final results = await Future.wait<dynamic>([
      profileFuture,
      statsFuture,
      sellerAdsFuture,
      followingFuture,
      favoritedFuture,
    ]);

    if (!mounted || widget.adId != ad.id) return;

    final profile = results[0] as UserModel?;
    final stats = results[1];
    final allAds = results[2] as List<ClassifiedAdModel>;
    final activeAds = allAds.where((a) => a.status == 'active').toList();
    final otherAds = activeAds.where((a) => a.id != ad.id).toList();

    setState(() {
      _sellerProfile = profile;
      if (stats != null) {
        _sellerAvgRating = (stats.avgRating as double?) ?? 0;
        _sellerReviewCount = (stats.reviewCount as int?) ?? 0;
      }
      _sellerAllActiveAds = activeAds;
      _sellerOtherAds = otherAds;
      _isFollowingSeller = results[3] as bool;
      _isFavorited = results[4] as bool;
    });
  }

  Future<void> _toggleFavorite(ClassifiedAdModel ad) async {
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Prijavite se da biste sačuvali oglas.'),
          action: SnackBarAction(
            label: 'Prijava',
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return;
    }

    if (_isTogglingFavorite) return;
    final previous = _isFavorited;
    final prevCount = _favoritesCount ?? ad.favoritesCount;
    final next = !previous;
    final nextCount = (prevCount + (next ? 1 : -1)).clamp(0, 1 << 30);

    unawaited(AppHaptics.light());
    setState(() {
      _isTogglingFavorite = true;
      _isFavorited = next;
      _favoritesCount = nextCount;
    });

    try {
      if (next) {
        await _adFavoritesService.addFavorite(user.id, ad.id);
      } else {
        await _adFavoritesService.removeFavorite(user.id, ad.id);
      }
      if (!mounted) return;
      setState(() => _isTogglingFavorite = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next
                ? 'Oglas je dodat u sačuvane oglase.'
                : 'Oglas je uklonjen iz sačuvanih.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTogglingFavorite = false;
        _isFavorited = previous;
        _favoritesCount = prevCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nije moguće sačuvati izmenu. Pokušajte ponovo.'),
        ),
      );
    }
  }

  Future<void> _toggleFollowSeller(ClassifiedAdModel ad) async {
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Prijavite se da biste sačuvali prodavca.'),
          action: SnackBarAction(
            label: 'Prijava',
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return;
    }

    if (_isTogglingFollow) return;
    final previous = _isFollowingSeller;
    final next = !previous;

    unawaited(AppHaptics.light());
    setState(() {
      _isTogglingFollow = true;
      _isFollowingSeller = next;
    });

    try {
      if (next) {
        await _favoriteSellersService.follow(user.id, ad.userId);
      } else {
        await _favoriteSellersService.unfollow(user.id, ad.userId);
      }
      if (!mounted) return;
      setState(() => _isTogglingFollow = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next
                ? 'Prodavac je dodat u omiljene.'
                : 'Prodavac je uklonjen iz omiljenih.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTogglingFollow = false;
        _isFollowingSeller = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Greška pri čuvanju prodavca. Pokušajte ponovo.'),
        ),
      );
    }
  }

  void _openAllSellerAds(ClassifiedAdModel ad) {
    final sellerName = ad.sellerName ??
        _sellerProfile?.farmName ??
        _sellerProfile?.displayName ??
        'Oglašivač';
    final ads =
        _sellerAllActiveAds.isNotEmpty ? _sellerAllActiveAds : <ClassifiedAdModel>[ad];
    ClassifiedMoreFromSellerStrip.showAllSellerAdsModal(
      context,
      sellerName: sellerName,
      ads: ads,
    );
  }

  Future<void> _shareAd(ClassifiedAdModel ad) async {
    final base = resolvePublicShareBaseUrl();
    final url = '$base/ad/${ad.id}';
    final text = '${ad.title} — ${ad.priceFormatted}';
    unawaited(_service.recordInteraction(ad.id, 'share'));
    await showAppShareSheet(
      context,
      title: ad.title,
      url: url,
      shareText: text,
      subject: ad.title,
    );
  }

  Future<void> _makePhoneCall(String phone, {String? adId}) async {
    if (adId != null) {
      unawaited(_service.recordInteraction(adId, 'call'));
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nije moguće pokrenuti poziv.')),
        );
      }
    }
  }

  Future<void> _revealPhone(ClassifiedAdModel ad) async {
    setState(() => _isLoadingPhone = true);
    try {
      final phone = await _service.getAdPhone(ad.id);
      if (!mounted) return;
      if (phone != null && phone.trim().isNotEmpty) {
        setState(() {
          _revealedPhone = phone;
          _isLoadingPhone = false;
        });
        unawaited(AppHaptics.medium());
        _showPhoneActionSheet(phone, ad.id);
      } else {
        setState(() => _isLoadingPhone = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Broj telefona nije dostupan za ovaj oglas.'),
          ),
        );
      }
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPhone = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.userMessage ?? 'Nije moguće učitati broj telefona.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPhone = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nije moguće učitati broj telefona.'),
        ),
      );
    }
  }

  void _showPhoneActionSheet(String phone, String adId) {
    ClassifiedPhoneActionSheet.show(
      context,
      phone: phone,
      onCall: () => _makePhoneCall(phone, adId: adId),
    );
  }

  Future<void> _openChat(ClassifiedAdModel ad) async {
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Prijavite se da biste poslali poruku.'),
          action: SnackBarAction(
            label: 'Prijava',
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return;
    }

    if (user.id == ad.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ovo je vaš oglas.')),
      );
      return;
    }

    try {
      final chatService = context.read<ChatService>();
      final convId = await chatService.getOrCreateConversation(
        user.id,
        ad.userId,
        adId: ad.id,
      );
      if (mounted) {
        unawaited(context.push('/chat/$convId'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: $e')),
        );
      }
    }
  }

  void _openImageLightbox(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (BuildContext context, _, __) {
          return FullScreenImageViewer(
            productId: 'ad_${widget.adId}',
            imageUrls: images,
            initialIndex: initialIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _markAsSold(ClassifiedAdModel ad) async {
    await _service.markAsSold(ad.id);
    unawaited(_load());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oglas je označen kao prodat.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<ClassifiedAdModel?>(
      future: _adFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AmazonColors.getCanvas(context),
            appBar: ClassifiedDetailAppBar(
              title: 'Oglas...',
              isDark: isDark,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError || snap.data == null) {
          return Scaffold(
            backgroundColor: AmazonColors.getCanvas(context),
            appBar: ClassifiedDetailAppBar(
              title: 'Oglas',
              isDark: isDark,
            ),
            body: AppErrorRetry(
              message: 'Oglas nije pronađen',
              detail: 'Oglas je možda obrisan, istekao ili link nije ispravan.',
              onRetry: _load,
            ),
          );
        }

        final ad = snap.data!;
        final userId = context.select((AppState s) => s.user?.id);
        final isOwner = userId != null && userId == ad.userId;
        final currentPhone = _revealedPhone ?? ad.phone;
        final hasPhone = ad.phonePublic ||
            (currentPhone != null && currentPhone.isNotEmpty);
        final isDesktop = Breakpoints.isDesktop(context);
        final isWide = MediaQuery.sizeOf(context).width >= 900;

        return Scaffold(
          backgroundColor: AmazonColors.getCanvas(context),
          appBar: isDesktop
              ? null
              : ClassifiedDetailAppBar(
                  title: ad.title,
                  isDark: isDark,
                  ad: ad,
                  isOwner: isOwner,
                  onShare: () => _shareAd(ad),
                ),
          bottomNavigationBar: isWide
              ? null
              : SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AmazonColors.darkCard
                          : AmazonColors.cardWhite,
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? AmazonColors.darkBorder
                              : AmazonColors.borderGray,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.3 : 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ClassifiedActionButtons(
                      ad: ad,
                      isOwner: isOwner,
                      hasPhone: hasPhone,
                      colorScheme: colorScheme,
                      isDark: isDark,
                      isLoadingPhone: _isLoadingPhone,
                      currentPhone: currentPhone,
                      isPhoneRevealed: currentPhone != null &&
                          currentPhone.trim().isNotEmpty,
                      onEdit: () => context.push('/classifieds/edit/${ad.id}'),
                      onMarkAsSold: () => _markAsSold(ad),
                      onPhoneReveal: () => _revealPhone(ad),
                      onPhoneTap: () =>
                          _showPhoneActionSheet(currentPhone!, ad.id),
                      onChatTap: () => _openChat(ad),
                    ),
                  ),
                ),
          body: ClassifiedDetailContent(
            ad: ad,
            isDesktop: isDesktop,
            isWide: isWide,
            isOwner: isOwner,
            hasPhone: hasPhone,
            isLoadingPhone: _isLoadingPhone,
            currentPhone: currentPhone,
            onImageTap: _openImageLightbox,
            onShare: () => _shareAd(ad),
            onEdit: () => context.push('/classifieds/edit/${ad.id}'),
            onMarkAsSold: () => _markAsSold(ad),
            onPhoneReveal: () => _revealPhone(ad),
            onPhoneTap: () => _showPhoneActionSheet(currentPhone!, ad.id),
            onChatTap: () => _openChat(ad),
            sellerProfile: _sellerProfile,
            sellerAvgRating: _sellerAvgRating,
            sellerReviewCount: _sellerReviewCount,
            sellerOtherAds: _sellerOtherAds,
            sellerActiveAdsCount: _sellerAllActiveAds.length,
            isFollowingSeller: _isFollowingSeller,
            isTogglingFollow: _isTogglingFollow,
            isFavorited: _isFavorited,
            isTogglingFavorite: _isTogglingFavorite,
            favoritesCount: _favoritesCount,
            onToggleFavorite: () => _toggleFavorite(ad),
            onToggleFollowSeller: () => _toggleFollowSeller(ad),
            onViewAllSellerAds: () => _openAllSellerAds(ad),
          ),
        );
      },
    );
  }
}
