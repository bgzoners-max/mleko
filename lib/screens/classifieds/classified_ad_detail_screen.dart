import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design_system.dart';
import '../../core/haptic.dart';
import '../../core/web_seo.dart';
import '../../models/app_error.dart';
import '../../models/classified_ad_model.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/app_state.dart';
import '../../providers/classifieds_provider.dart';
import '../../services/classifieds/classifieds_service.dart';
import '../../services/communication/chat_service.dart';
import '../../supabase_config.dart';
import '../../utils/classified_attributes_engine.dart';
import '../../widgets/app_error_retry.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/classifieds/report_classified_ad_dialog.dart';

class ClassifiedAdDetailScreen extends StatefulWidget {
  final String adId;

  const ClassifiedAdDetailScreen({super.key, required this.adId});

  @override
  State<ClassifiedAdDetailScreen> createState() =>
      _ClassifiedAdDetailScreenState();
}

class _ClassifiedAdDetailScreenState extends State<ClassifiedAdDetailScreen> {
  late ClassifiedsService _service;
  late Future<ClassifiedAdModel?> _adFuture;
  final _pageController = PageController();
  int _currentImageIndex = 0;

  bool _viewIncremented = false;
  String? _revealedPhone;
  bool _isLoadingPhone = false;

  @override
  void initState() {
    super.initState();
    _service = context.read<ClassifiedsService>();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final future = _service.getAd(widget.adId);
    setState(() => _adFuture = future);

    if (!_viewIncremented) {
      final ad = await future;
      if (ad != null && mounted) {
        if (_revealedPhone == null && ad.phone != null && ad.phone!.isNotEmpty) {
          setState(() => _revealedPhone = ad.phone);
        }
        final userId = context.read<AppState>().user?.id;
        if (userId == null || userId != ad.userId) {
          unawaited(_service.incrementViews(widget.adId));
        }
        _viewIncremented = true;
      }
    }
  }

  Future<void> _shareAd(ClassifiedAdModel ad) async {
    final rawBase = SupabaseConfig.shareBaseUrl.isNotEmpty
        ? SupabaseConfig.shareBaseUrl
        : (kIsWeb ? Uri.base.origin : 'https://domacimarket.rs');
    final base = rawBase.replaceAll(RegExp(r'/+$'), '');
    final url = '$base/ad/${ad.id}';
    final text = '${ad.title} — ${ad.priceFormatted}\n$url';
    unawaited(_service.recordInteraction(ad.id, 'share'));
    await SharePlus.instance.share(ShareParams(text: text, subject: ad.title));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Kontakt prodavca',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  phone,
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(ctx).colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: phone));
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Broj telefona je kopiran.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Kopiraj'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _makePhoneCall(phone, adId: adId);
                        },
                        icon: const Icon(Icons.phone_rounded, size: 18),
                        label: const Text('Pozovi'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
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
      final convId = await chatService.getOrCreateConversation(user.id, ad.userId);
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
    showDialog(
      context: context,
      builder: (ctx) {
        int activeIdx = initialIndex;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.black.withValues(alpha: 0.95),
              insetPadding: EdgeInsets.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    controller: PageController(initialPage: initialIndex),
                    onPageChanged: (i) => setModalState(() => activeIdx = i),
                    itemBuilder: (context, idx) {
                      return InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 3.5,
                        child: Center(
                          child: AppNetworkImage(
                            imageUrl: images[idx],
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${activeIdx + 1} / ${images.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
            appBar: AppBar(
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              foregroundColor: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
              elevation: 0,
              scrolledUnderElevation: 1,
              surfaceTintColor: Colors.transparent,
              shape: Border(
                bottom: BorderSide(
                  color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                  width: 1.0,
                ),
              ),
              title: Text(
                'Oglas...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                ),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError || snap.data == null) {
          return Scaffold(
            backgroundColor: AmazonColors.getCanvas(context),
            appBar: AppBar(
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              foregroundColor: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
              elevation: 0,
              scrolledUnderElevation: 1,
              surfaceTintColor: Colors.transparent,
              shape: Border(
                bottom: BorderSide(
                  color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                  width: 1.0,
                ),
              ),
              title: Text(
                'Oglas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                ),
              ),
            ),
            body: AppErrorRetry(
              message: 'Oglas nije pronađen',
              detail: 'Oglas je možda obrisan, istekao ili link nije ispravan.',
              onRetry: _load,
            ),
          );
        }

        final ad = snap.data!;
        setClassifiedAdSeo(ad);

        final userId = context.watch<AppState>().user?.id;
        final isOwner = userId != null && userId == ad.userId;
        final currentPhone = _revealedPhone ?? ad.phone;
        final hasPhone = ad.phonePublic ||
            (currentPhone != null && currentPhone.isNotEmpty);

        final isWide = MediaQuery.sizeOf(context).width >= 900;

        return Scaffold(
          backgroundColor: AmazonColors.getCanvas(context),
          appBar: AppBar(
            backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
            foregroundColor: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 1,
            surfaceTintColor: Colors.transparent,
            shape: Border(
              bottom: BorderSide(
                color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                width: 1.0,
              ),
            ),
            title: Text(
              ad.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
              ),
            ),
            iconTheme: IconThemeData(
              color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Podeli oglas',
                onPressed: () {
                  AppHaptics.light();
                  _shareAd(ad);
                },
              ),
              if (!isOwner)
                IconButton(
                  icon: const Icon(Icons.flag_outlined),
                  tooltip: 'Prijavi oglas',
                  onPressed: () {
                    AppHaptics.light();
                    ReportClassifiedAdDialog.show(context, ad: ad);
                  },
                ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Izmeni oglas',
                  onPressed: () => context.push('/classifieds/edit/${ad.id}'),
                ),
            ],
          ),
          bottomNavigationBar: isWide
              ? null
              : SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
                      border: Border(
                        top: BorderSide(
                          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: _buildActionButtons(ad, isOwner, hasPhone, colorScheme),
                  ),
                ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 16,
              vertical: 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Amazon Breadcrumb navigacija
                    _buildBreadcrumbs(ad, colorScheme),
                    const SizedBox(height: 12),

                    // 2. Glavni sadržaj: 2 kolone na desktopu, 1 kolona na mobilnom
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LEVA KOLONA: Velika interaktivna galerija slika + Bezbednosni saveti
                          Expanded(
                            flex: 55,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildImageGallery(ad, colorScheme, isDesktop: true),
                                const SizedBox(height: 24),
                                _buildDescriptionCard(ad, theme, colorScheme),
                                const SizedBox(height: 20),
                                _buildSafetyTipsCard(colorScheme, isDark),
                                const SizedBox(height: 12),
                                _buildReportButton(context, ad, isOwner, colorScheme),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),

                          // DESNA KOLONA: Amazon Buy / Contact Box + Karakteristike + Prodavac
                          Expanded(
                            flex: 45,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildMainInfoCard(
                                  ad,
                                  theme,
                                  colorScheme,
                                  isDark,
                                  isOwner,
                                  hasPhone,
                                  isWide: true,
                                ),
                                const SizedBox(height: 20),
                                _buildSpecificationsTable(ad, theme, colorScheme),
                                const SizedBox(height: 20),
                                _buildSellerCard(ad, theme, colorScheme),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      // MOBILNI PRIKAZ (Single column)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildImageGallery(ad, colorScheme, isDesktop: false),
                          const SizedBox(height: 16),
                          _buildMainInfoCard(
                            ad,
                            theme,
                            colorScheme,
                            isDark,
                            isOwner,
                            hasPhone,
                            isWide: false,
                          ),
                          const SizedBox(height: 16),
                          _buildSpecificationsTable(ad, theme, colorScheme),
                          const SizedBox(height: 16),
                          _buildDescriptionCard(ad, theme, colorScheme),
                          const SizedBox(height: 16),
                          _buildSellerCard(ad, theme, colorScheme),
                          const SizedBox(height: 16),
                          _buildSafetyTipsCard(colorScheme, isDark),
                          const SizedBox(height: 12),
                          _buildReportButton(context, ad, isOwner, colorScheme),
                          const SizedBox(height: 24),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET PODKOMPONENTE ---

  Widget _buildBreadcrumbs(ClassifiedAdModel ad, ColorScheme colorScheme) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        InkWell(
          onTap: () {
            context.read<AppSettingsProvider>().setMarketMode(MarketMode.foodMarket);
            context.read<ClassifiedsProvider>().clearFilters();
            context.go('/');
          },
          child: Text(
            'Početna',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ),
        Icon(Icons.chevron_right, size: 14, color: colorScheme.onSurfaceVariant),
        Text(
          'Mali oglasi',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        if (ad.categoryName != null) ...[
          Icon(Icons.chevron_right, size: 14, color: colorScheme.onSurfaceVariant),
          Text(
            ad.categoryName!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AmazonColors.link,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageGallery(
    ClassifiedAdModel ad,
    ColorScheme colorScheme, {
    required bool isDesktop,
  }) {
    if (ad.images.isEmpty) {
      return AspectRatio(
        aspectRatio: isDesktop ? 1.35 : 1.25,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }

    final hasMultiple = ad.images.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Glavna slika (Hero)
        AspectRatio(
          aspectRatio: isDesktop ? 1.35 : 1.25,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: ad.images.length,
                  onPageChanged: (i) => setState(() => _currentImageIndex = i),
                  itemBuilder: (ctx, i) {
                    return InkWell(
                      onTap: () => _openImageLightbox(ad.images, i),
                      child: AppNetworkImage(
                        imageUrl: ad.images[i],
                        fit: BoxFit.cover,
                        placeholder: Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image, size: 60),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Zum ikonica u uglu
              Positioned(
                top: 12,
                right: 12,
                child: InkWell(
                  onTap: () => _openImageLightbox(ad.images, _currentImageIndex),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // Oznaka "PRODATO"
              if (ad.isSold)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'PRODATO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Thumbnail strip ispod glavne slike
        if (hasMultiple) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ad.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final isSelected = _currentImageIndex == idx;
                return InkWell(
                  onTap: () {
                    setState(() => _currentImageIndex = idx);
                    _pageController.animateToPage(
                      idx,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withValues(alpha: 0.4),
                        width: isSelected ? 2.5 : 1.0,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AppNetworkImage.thumbnail(
                        imageUrl: ad.images[idx],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMainInfoCard(
    ClassifiedAdModel ad,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    bool isOwner,
    bool hasPhone, {
    required bool isWide,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceL),
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bedževi stanja, statusa, isticanja i hitnosti
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (ad.isCurrentlyFeatured) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AmazonColors.amber,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 13, color: AmazonColors.textPrimary),
                      SizedBox(width: 4),
                      Text(
                        'ISTAKNUT OGLAS',
                        style: TextStyle(
                          color: AmazonColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (ad.isUrgent) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AmazonColors.badgeRed,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
                      SizedBox(width: 3),
                      Text(
                        'HITNA PRODAJA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (ad.showConditionBadge) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ad.condition == 'new'
                        ? AmazonColors.green
                        : AmazonColors.navNavy.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ad.condition == 'new') ...[
                        const Icon(Icons.verified_rounded, size: 11, color: Colors.white),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        ad.conditionLabel.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ad.isSold
                      ? Colors.red.shade800.withValues(alpha: 0.12)
                      : ad.isRejected
                          ? Colors.red.shade900.withValues(alpha: 0.15)
                          : ad.isArchived
                              ? Colors.grey.shade800.withValues(alpha: 0.15)
                              : Colors.green.shade800.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ad.isSold
                      ? 'PRODATO'
                      : ad.isRejected
                          ? 'UKLONJENO (MODERACIJA)'
                          : ad.isArchived
                              ? 'ARHIVIRANO'
                              : 'AKTIVAN OGLAS',
                  style: TextStyle(
                    color: ad.isSold
                        ? Colors.red.shade800
                        : ad.isRejected
                            ? Colors.red.shade900
                            : ad.isArchived
                                ? Colors.grey.shade800
                                : Colors.green.shade800,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                ad.timeAgo,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Naslov oglasa
          Text(
            ad.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Istaknuti blok cene (Amazon Style Deal Price Box)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AmazonColors.darkCanvas
                  : const Color(0xFFF7F8F8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
              ),
            ),
            child: Row(
              children: [
                Text(
                  ad.priceFormatted,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isDark ? const Color(0xFFFF6B6B) : AmazonColors.dealRed,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.location_on_outlined, size: 16, color: AmazonColors.link),
                const SizedBox(width: 4),
                Text(
                  ad.city,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Na širokim ekranima, dugmad za akciju su smeštena direktno u ovaj box!
          if (isWide) ...[
            const SizedBox(height: 20),
            _buildActionButtons(ad, isOwner, hasPhone, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    ClassifiedAdModel ad,
    bool isOwner,
    bool hasPhone,
    ColorScheme colorScheme,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isOwner) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push('/classifieds/edit/${ad.id}'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Izmeni oglas'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: ad.isSold
                  ? null
                  : () async {
                      await _service.markAsSold(ad.id);
                      unawaited(_load());
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Oglas je označen kao prodat.')),
                        );
                      }
                    },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(ad.isSold ? 'Već prodat' : 'Označi prodato'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (!isOwner && !ad.isAvailable) {
      final message = ad.isSold
          ? 'Ovaj oglas je označen kao prodat.'
          : ad.isRejected
              ? 'Ovaj oglas je uklonjen nakon moderacije.'
              : 'Ovaj oglas više nije aktivan.';
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 20, color: colorScheme.error),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final currentPhone = _revealedPhone ?? ad.phone;
    final isPhoneRevealed = currentPhone != null && currentPhone.trim().isNotEmpty;

    return Row(
      children: [
        if (hasPhone) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isLoadingPhone
                  ? null
                  : () {
                      AppHaptics.medium();
                      if (isPhoneRevealed) {
                        _showPhoneActionSheet(currentPhone, ad.id);
                      } else {
                        _revealPhone(ad);
                      }
                    },
              icon: _isLoadingPhone
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isPhoneRevealed ? Icons.phone_in_talk_rounded : Icons.phone_outlined,
                      color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                    ),
              label: Text(
                _isLoadingPhone
                    ? 'Učitavanje...'
                    : (isPhoneRevealed ? currentPhone : 'Prikaži broj'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
                side: BorderSide(
                  color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: hasPhone ? 1 : 2,
          child: ElevatedButton.icon(
            onPressed: () {
              AppHaptics.medium();
              _openChat(ad);
            },
            icon: const Icon(Icons.chat_bubble_outline, color: AmazonColors.darkNavy),
            label: const Text(
              'Pošalji poruku',
              style: TextStyle(
                color: AmazonColors.darkNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AmazonColors.amberLight,
              foregroundColor: AmazonColors.darkNavy,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AmazonColors.amberDark, width: 0.9),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecificationsTable(
    ClassifiedAdModel ad,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceL),
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Karakteristike predmeta',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _buildSpecRow('Kategorija', ad.categoryName ?? ad.categoryId, colorScheme),
          const Divider(height: 18),
          if (ad.showConditionBadge) ...[
            _buildSpecRow('Stanje', ad.conditionLabel, colorScheme),
            const Divider(height: 18),
          ],
          _buildSpecRow('Mesto / Lokacija', ad.city, colorScheme),
          const Divider(height: 18),
          if (ad.attributes.isNotEmpty) ...[
            for (final entry in ad.attributes.entries) ...[
              () {
                final val = entry.value;
                if (val == null) return const SizedBox.shrink();
                final attr =
                    ClassifiedAttributesEngine.findAttributeByKey(entry.key);
                final label = attr?.label ?? entry.key;
                final formatted = attr != null
                    ? attr.formatValue(val)
                    : (val is bool ? (val ? 'Da' : 'Ne') : val.toString());
                if (formatted.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: [
                    _buildSpecRow(
                      label,
                      formatted,
                      colorScheme,
                      icon: attr?.icon,
                    ),
                    const Divider(height: 18),
                  ],
                );
              }(),
            ],
          ],
          _buildSpecRow('Datum objave', ad.timeAgo, colorScheme),
          const Divider(height: 18),
          _buildSpecRow('Broj pregleda', '${ad.viewsCount} pregleda', colorScheme),
        ],
      ),
    );
  }

  Widget _buildSpecRow(
    String label,
    String value,
    ColorScheme colorScheme, {
    IconData? icon,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AmazonColors.link),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(
    ClassifiedAdModel ad,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceL),
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detaljan opis',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ad.description.isEmpty
                ? 'Prodavac nije uneo detaljan opis za ovaj oglas.'
                : ad.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              fontSize: 14.5,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard(
    ClassifiedAdModel ad,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceL),
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informacije o oglašivaču',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                backgroundImage: ad.sellerAvatar != null
                    ? CachedNetworkImageProvider(ad.sellerAvatar!)
                    : null,
                child: ad.sellerAvatar == null
                    ? Icon(Icons.person, color: colorScheme.primary, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            ad.sellerName ?? 'Korisnik Domaćeg Marketa',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: Color(0xFF059669),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lokacija: ${ad.city}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTipsCard(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceM),
      decoration: BoxDecoration(
        color: isDark
            ? AmazonColors.darkCard
            : const Color(0xFFF7F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Savet za bezbednu kupovinu',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Preporučujemo lično preuzimanje i proveru ispravnosti predmeta pre plaćanja. Ne uplaćujte novac unapred nepoznatim licima.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportButton(
    BuildContext context,
    ClassifiedAdModel ad,
    bool isOwner,
    ColorScheme colorScheme,
  ) {
    if (isOwner) return const SizedBox.shrink();

    return Center(
      child: TextButton.icon(
        onPressed: () {
          AppHaptics.light();
          ReportClassifiedAdDialog.show(context, ad: ad);
        },
        icon: Icon(
          Icons.flag_outlined,
          size: 14,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        label: Text(
          'Prijavi nepravilnost ili sumnjiv oglas',
          style: TextStyle(
            fontSize: 11.5,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
