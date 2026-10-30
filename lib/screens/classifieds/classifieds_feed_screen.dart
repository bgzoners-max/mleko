import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/amazon_theme.dart';
import '../../core/responsive.dart';
import '../../core/web_seo.dart';
import '../../providers/app_state.dart';
import '../../providers/classifieds_provider.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/classifieds/classifieds_desktop_feed_view.dart';
import '../../widgets/classifieds/classifieds_mobile_feed_view.dart';
import '../../widgets/theme_toggle_switch.dart';

class ClassifiedsFeedScreen extends StatefulWidget {
  final Widget? headerWidget;
  final bool isEmbedded;
  final String? initialCategoryId;

  const ClassifiedsFeedScreen({
    super.key,
    this.headerWidget,
    this.isEmbedded = false,
    this.initialCategoryId,
  });

  @override
  State<ClassifiedsFeedScreen> createState() => _ClassifiedsFeedScreenState();
}

class _ClassifiedsFeedScreenState extends State<ClassifiedsFeedScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _categoryChipsScrollController = ScrollController();
  Timer? _debounceTimer;
  String? _lastSeoCategoryId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<ClassifiedsProvider>();
      if (widget.initialCategoryId != null &&
          widget.initialCategoryId!.isNotEmpty) {
        await p.loadCategories();
        if (!mounted) return;
        p.selectCategory(widget.initialCategoryId);
        final cat = p.findCategory(widget.initialCategoryId!);
        if (cat != null) {
          setClassifiedCategorySeo(cat);
          _lastSeoCategoryId = cat.id;
        }
      } else {
        if (!widget.isEmbedded) {
          applyRouteSeo('/classifieds');
        }
        // Pokrećemo kategorije i oglase paralelno u istoj milisekundi
        unawaited(p.loadCategories());
        unawaited(p.loadInitialAds());
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _categoryChipsScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<ClassifiedsProvider>().loadMore();
    }
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context
            .read<ClassifiedsProvider>()
            .search(val.trim().isEmpty ? null : val);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final classifieds = context.watch<ClassifiedsProvider>();
    final appState = context.watch<AppState>();
    final user = appState.user;
    final isAppOffline = appState.isOffline;
    final isNetworkErr = classifieds.error != null &&
        (isAppOffline ||
            classifieds.error!.toLowerCase().contains('socket') ||
            classifieds.error!.toLowerCase().contains('network') ||
            classifieds.error!.toLowerCase().contains('offline') ||
            classifieds.error!.toLowerCase().contains('konekcij') ||
            classifieds.error!.toLowerCase().contains('connection') ||
            classifieds.error!.toLowerCase().contains('host lookup') ||
            classifieds.error!.toLowerCase().contains('timeout'));

    if (!widget.isEmbedded) {
      final currentCatId = classifieds.selectedCategoryId;
      if (currentCatId != _lastSeoCategoryId) {
        _lastSeoCategoryId = currentCatId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (currentCatId != null) {
            final cat = classifieds.findCategory(currentCatId);
            if (cat != null) {
              setClassifiedCategorySeo(cat);
            }
          } else {
            applyRouteSeo('/classifieds');
          }
        });
      }
    }

    final isDesktop = Breakpoints.isDesktop(context);
    final isRefreshing = classifieds.refreshing;

    final isFiltered = classifieds.selectedCategoryId != null ||
        classifieds.selectedCity != null ||
        classifieds.selectedDistrict != null ||
        classifieds.minPrice != null ||
        classifieds.maxPrice != null ||
        classifieds.selectedCondition != null ||
        classifieds.selectedAttributes.isNotEmpty ||
        classifieds.onlyFeatured ||
        classifieds.onlyUrgent ||
        (classifieds.searchQuery != null &&
            classifieds.searchQuery!.isNotEmpty);

    // FAB — samo za prijavljene korisnike (gost može samo da pregleda)
    final isGuest = user == null || user.isGuest;
    final fab = isGuest
        ? null
        : FloatingActionButton.extended(
            onPressed: () => context.push('/classifieds/new'),
            backgroundColor: const Color(0xFFFFE082),
            foregroundColor: AmazonColors.darkNavy,
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text(
              'Postavi oglas',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          );

    final canvasColor = AmazonColors.getCanvas(context);

    final Widget content;
    if (isDesktop) {
      content = ClassifiedsDesktopFeedView(
        classifieds: classifieds,
        user: user,
        searchController: _searchController,
        scrollController: _scrollController,
        isRefreshing: isRefreshing,
        isFiltered: isFiltered,
        isGuest: isGuest,
        headerWidget: widget.headerWidget,
        onSearchChanged: _onSearchChanged,
      );
    } else {
      content = ClassifiedsMobileFeedView(
        classifieds: classifieds,
        user: user,
        searchController: _searchController,
        scrollController: _scrollController,
        categoryChipsScrollController: _categoryChipsScrollController,
        isEmbedded: widget.isEmbedded,
        isRefreshing: isRefreshing,
        isFiltered: isFiltered,
        isGuest: isGuest,
        isAppOffline: isAppOffline,
        isNetworkErr: isNetworkErr,
        headerWidget: widget.headerWidget,
        onSearchChanged: _onSearchChanged,
      );
    }

    if (widget.isEmbedded) {
      return Stack(
        fit: StackFit.expand,
        children: [
          content,
          if (fab != null)
            Positioned(
              bottom: 16,
              right: 16,
              child: SafeArea(child: fab),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: (widget.isEmbedded || isDesktop)
          ? null
          : AppBar(
              leading: const AppBackButton(fallbackRoute: '/'),
              title: const Text('Mali oglasi'),
              actions: const [
                Center(child: ThemeToggleSwitch()),
                SizedBox(width: 4),
                AppHomeButton(),
              ],
            ),
      backgroundColor: canvasColor,
      floatingActionButton: fab,
      body: content,
    );
  }
}
