import 'dart:async';

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
import '../../providers/app_state.dart';
import '../../services/classifieds/classifieds_service.dart';
import '../../services/communication/chat_service.dart';
import '../../supabase_config.dart';
import '../../widgets/app_error_retry.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/classifieds/report_classified_ad_dialog.dart';
import '../../widgets/classifieds/detail/classified_breadcrumbs.dart';
import '../../widgets/classifieds/detail/classified_image_gallery.dart';
import '../../widgets/classifieds/detail/classified_safety_tips_card.dart';
import '../../widgets/classifieds/detail/classified_report_button.dart';
import '../../widgets/classifieds/detail/classified_main_info_card.dart';
import '../../widgets/classifieds/detail/classified_specifications_table.dart';
import '../../widgets/classifieds/detail/classified_description_card.dart';
import '../../widgets/classifieds/detail/classified_seller_card.dart';
import '../../widgets/classifieds/detail/classified_action_buttons.dart';
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
  late Future<ClassifiedAdModel?> _adFuture;
  final _pageController = PageController();

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
              leading: const AppBackButton(fallbackRoute: '/classifieds'),
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
              actions: const [AppHomeButton()],
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError || snap.data == null) {
          return Scaffold(
            backgroundColor: AmazonColors.getCanvas(context),
            appBar: AppBar(
              leading: const AppBackButton(fallbackRoute: '/classifieds'),
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
              actions: const [AppHomeButton()],
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
            leading: const AppBackButton(fallbackRoute: '/classifieds'),
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
              const AppHomeButton(),
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
                    child: ClassifiedActionButtons(
                      ad: ad,
                      isOwner: isOwner,
                      hasPhone: hasPhone,
                      colorScheme: colorScheme,
                      isDark: isDark,
                      isLoadingPhone: _isLoadingPhone,
                      currentPhone: _revealedPhone ?? ad.phone,
                      isPhoneRevealed: (_revealedPhone ?? ad.phone) != null && (_revealedPhone ?? ad.phone)!.trim().isNotEmpty,
                      onEdit: () => context.push('/classifieds/edit/${ad.id}'),
                      onMarkAsSold: () async {
                        await _service.markAsSold(ad.id);
                        unawaited(_load());
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Oglas je označen kao prodat.')),
                          );
                        }
                      },
                      onPhoneReveal: () => _revealPhone(ad),
                      onPhoneTap: () => _showPhoneActionSheet(_revealedPhone ?? ad.phone!, ad.id),
                      onChatTap: () => _openChat(ad),
                    ),
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
                    ClassifiedBreadcrumbs(ad: ad, colorScheme: colorScheme),
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
                                ClassifiedImageGallery(
                                  ad: ad,
                                  colorScheme: colorScheme,
                                  isDesktop: true,
                                  onImageTap: _openImageLightbox,
                                ),
                                const SizedBox(height: 24),
                                ClassifiedDescriptionCard(ad: ad, theme: theme, colorScheme: colorScheme, isDark: isDark),
                                const SizedBox(height: 20),
                                ClassifiedSafetyTipsCard(colorScheme: colorScheme, isDark: isDark),
                                const SizedBox(height: 12),
                                ClassifiedReportButton(ad: ad, isOwner: isOwner, colorScheme: colorScheme),
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
                                ClassifiedMainInfoCard(
                                  ad: ad,
                                  theme: theme,
                                  colorScheme: colorScheme,
                                  isDark: isDark,
                                  isOwner: isOwner,
                                  hasPhone: hasPhone,
                                  isWide: true,
                                  actionButtons: ClassifiedActionButtons(
                                    ad: ad,
                                    isOwner: isOwner,
                                    hasPhone: hasPhone,
                                    colorScheme: colorScheme,
                                    isDark: isDark,
                                    isLoadingPhone: _isLoadingPhone,
                                    currentPhone: _revealedPhone ?? ad.phone,
                                    isPhoneRevealed: (_revealedPhone ?? ad.phone) != null && (_revealedPhone ?? ad.phone)!.trim().isNotEmpty,
                                    onEdit: () => context.push('/classifieds/edit/${ad.id}'),
                                    onMarkAsSold: () async {
                                      await _service.markAsSold(ad.id);
                                      unawaited(_load());
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Oglas je označen kao prodat.')),
                                        );
                                      }
                                    },
                                    onPhoneReveal: () => _revealPhone(ad),
                                    onPhoneTap: () => _showPhoneActionSheet(_revealedPhone ?? ad.phone!, ad.id),
                                    onChatTap: () => _openChat(ad),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ClassifiedSpecificationsTable(ad: ad, theme: theme, colorScheme: colorScheme, isDark: isDark),
                                const SizedBox(height: 20),
                                ClassifiedSellerCard(ad: ad, theme: theme, colorScheme: colorScheme, isDark: isDark),
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
                          ClassifiedImageGallery(
                            ad: ad,
                            colorScheme: colorScheme,
                            isDesktop: false,
                            onImageTap: _openImageLightbox,
                          ),
                          const SizedBox(height: 16),
                          ClassifiedMainInfoCard(
                            ad: ad,
                            theme: theme,
                            colorScheme: colorScheme,
                            isDark: isDark,
                            isOwner: isOwner,
                            hasPhone: hasPhone,
                            isWide: false,
                          ),
                          const SizedBox(height: 16),
                          ClassifiedSpecificationsTable(ad: ad, theme: theme, colorScheme: colorScheme, isDark: isDark),
                          const SizedBox(height: 16),
                          ClassifiedDescriptionCard(ad: ad, theme: theme, colorScheme: colorScheme, isDark: isDark),
                          const SizedBox(height: 16),
                          ClassifiedSellerCard(ad: ad, theme: theme, colorScheme: colorScheme, isDark: isDark),
                          const SizedBox(height: 16),
                          ClassifiedSafetyTipsCard(colorScheme: colorScheme, isDark: isDark),
                          const SizedBox(height: 12),
                          ClassifiedReportButton(ad: ad, isOwner: isOwner, colorScheme: colorScheme),
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









}
