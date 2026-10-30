import 'dart:async';

import 'package:flutter/foundation.dart';
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
import '../../providers/app_state.dart';
import '../../services/classifieds/classifieds_service.dart';
import '../../services/communication/chat_service.dart';
import '../../supabase_config.dart';
import '../../widgets/app_error_retry.dart';
import '../../widgets/app_share_sheet.dart';
import '../../widgets/classifieds/detail/classified_action_buttons.dart';
import '../../widgets/classifieds/detail/classified_detail_content.dart';
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

  bool _viewIncremented = false;
  String? _revealedPhone;
  bool _isLoadingPhone = false;

  @override
  void initState() {
    super.initState();
    _service = context.read<ClassifiedsService>();
    _load();
  }

  Future<void> _load() async {
    final future = _service.getAd(widget.adId);
    setState(() => _adFuture = future);

    final ad = await future;
    if (ad != null && mounted) {
      setClassifiedAdSeo(ad);
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
    }
  }

  Future<void> _shareAd(ClassifiedAdModel ad) async {
    final rawBase = SupabaseConfig.shareBaseUrl.isNotEmpty
        ? SupabaseConfig.shareBaseUrl
        : (kIsWeb
            ? (Uri.base.origin == 'https://domacimarket.rs'
                ? 'https://www.domacimarket.rs'
                : Uri.base.origin)
            : 'https://www.domacimarket.rs');
    final base = rawBase.replaceAll(RegExp(r'/+$'), '');
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
        final userId = context.watch<AppState>().user?.id;
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
            onEdit: () => context.push('/classifieds/edit/${ad.id}'),
            onMarkAsSold: () => _markAsSold(ad),
            onPhoneReveal: () => _revealPhone(ad),
            onPhoneTap: () => _showPhoneActionSheet(currentPhone!, ad.id),
            onChatTap: () => _openChat(ad),
          ),
        );
      },
    );
  }
}
