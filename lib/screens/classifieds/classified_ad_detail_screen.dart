import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/responsive.dart';
import '../../core/web_seo.dart';
import '../../models/classified_ad_model.dart';
import '../../providers/app_state.dart';
import '../../services/classifieds/classifieds_service.dart';
import '../../services/communication/chat_service.dart';
import '../../supabase_config.dart';
import '../../widgets/app_error_retry.dart';

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

  @override
  void initState() {
    super.initState();
    _service = context.read<ClassifiedsService>();
    _load();
    // incrementViews se sada poziva unutar _load() uz provjeru vlasnika
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Ucitaj oglas i azuriraj future za FutureBuilder
    final future = _service.getAd(widget.adId);
    setState(() => _adFuture = future);

    // Nakon sto se oglas ucita, provjeri je li vlasnik i inkrementiraj
    if (!_viewIncremented) {
      final ad = await future;
      if (ad != null && mounted) {
        final userId = context.read<AppState>().user?.id;
        if (userId == null || userId != ad.userId) {
          _service.incrementViews(widget.adId);
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
    final url = '$base/classifieds/ad/${ad.id}';
    final text = '${ad.title} — ${ad.priceFormatted}\n$url';
    await SharePlus.instance.share(ShareParams(text: text, subject: ad.title));
  }

  Future<void> _makePhoneCall(String phone) async {
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

  Future<void> _openChat(ClassifiedAdModel ad) async {
    final user = context.read<AppState>().user;
    if (user == null) {
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
        context.push('/chat/$convId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Greška pri otvaranju razgovora.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = context.watch<AppState>().user;
    final isTablet = Breakpoints.isTablet(context);

    return FutureBuilder<ClassifiedAdModel?>(
      future: _adFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Učitavanje oglasa...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Oglas')),
            body: AppErrorRetry(
              message: 'Oglas nije pronađen ili je obrisan.',
              onRetry: _load,
            ),
          );
        }

        final ad = snapshot.data!;
        setClassifiedAdSeo(ad);
        final isOwner = currentUser?.id == ad.userId;
        final hasPhone = ad.phone != null &&
            ad.phone!.trim().isNotEmpty &&
            (ad.phonePublic || isOwner);

        return Scaffold(
          appBar: AppBar(
            title: Text(ad.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: 'Podeli oglas',
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _shareAd(ad),
              ),
              if (isOwner)
                IconButton(
                  tooltip: 'Izmeni oglas',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/classifieds/edit/${ad.id}'),
                ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: isOwner
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push('/classifieds/edit/${ad.id}'),
                            icon: const Icon(Icons.edit),
                            label: const Text('Izmeni oglas'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: ad.isSold
                                ? null
                                : () async {
                                    await _service.markAsSold(ad.id);
                                    _load();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Oglas je označen kao prodat.')),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(ad.isSold ? 'Već prodat' : 'Označi prodato'),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        if (hasPhone) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _makePhoneCall(ad.phone!),
                              icon: const Icon(Icons.phone_outlined),
                              label: const Text('Pozovi'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: hasPhone ? 1 : 2,
                          child: FilledButton.icon(
                            onPressed: () => _openChat(ad),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Pošalji poruku'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 800 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Galerija slika
                    if (ad.images.isNotEmpty)
                      AspectRatio(
                        aspectRatio: 1.3,
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: ad.images.length,
                              onPageChanged: (i) =>
                                  setState(() => _currentImageIndex = i),
                              itemBuilder: (ctx, i) {
                                return CachedNetworkImage(
                                  imageUrl: ad.images[i],
                                  fit: BoxFit.cover,
                                  placeholder: (c, url) => Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (c, url, err) => Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: const Icon(Icons.broken_image, size: 60),
                                  ),
                                );
                              },
                            ),

                            // Indikator tačkica na slikama
                            if (ad.images.length > 1)
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    ad.images.length,
                                    (idx) => Container(
                                      width: _currentImageIndex == idx ? 18 : 8,
                                      height: 8,
                                      margin:
                                          const EdgeInsets.symmetric(horizontal: 3),
                                      decoration: BoxDecoration(
                                        color: _currentImageIndex == idx
                                            ? colorScheme.primary
                                            : Colors.white.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Oznaka "PRODATO"
                            if (ad.isSold)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  child: const Center(
                                    child: Text(
                                      'PRODATO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                      ),

                    // Glavni detalji oglasa
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cena i bedževi
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                ad.priceFormatted,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: colorScheme.primary,
                                ),
                              ),
                              if (ad.showConditionBadge) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: ad.condition == 'new'
                                        ? Colors.green.shade700
                                        : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ad.conditionLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: ad.condition == 'new'
                                          ? Colors.white
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Naslov oglasa
                          Text(
                            ad.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tabela karakteristika (Lokacija, Datum, Pregledi)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  context,
                                  icon: Icons.location_on_outlined,
                                  label: 'Lokacija',
                                  value: ad.city,
                                ),
                                const Divider(height: 16),
                                _buildInfoRow(
                                  context,
                                  icon: Icons.category_outlined,
                                  label: 'Kategorija',
                                  value: ad.categoryName ?? ad.categoryId,
                                ),
                                const Divider(height: 16),
                                _buildInfoRow(
                                  context,
                                  icon: Icons.calendar_today_outlined,
                                  label: 'Objavljeno',
                                  value: ad.timeAgo,
                                ),
                                const Divider(height: 16),
                                _buildInfoRow(
                                  context,
                                  icon: Icons.visibility_outlined,
                                  label: 'Pregleda',
                                  value: '${ad.viewsCount}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Opis
                          Text(
                            'Opis oglasa',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ad.description.isEmpty
                                ? 'Prodavac nije uneo detaljan opis.'
                                : ad.description,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Kartica oglašivača
                          Text(
                            'Oglašivač',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 0,
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: ad.sellerAvatar != null
                                    ? CachedNetworkImageProvider(ad.sellerAvatar!)
                                    : null,
                                child: ad.sellerAvatar == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(
                                ad.sellerName ?? 'Korisnik Domaćeg Marketa',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Grad: ${ad.city}'),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
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

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
