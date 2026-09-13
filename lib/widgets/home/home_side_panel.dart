import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../constants/amazon_theme.dart';
import '../../core/responsive.dart';
import '../../models/home_products_data.dart';
import '../skeleton.dart';
import '../app_empty_state.dart';
import '../app_network_image.dart';
import 'favorite_farms_list.dart';

class HomeSidePanel extends StatefulWidget {
  final Stream<HomeProductsData> homeProductsStream;
  final HomeProductsData? initialData;
  final bool isSeller;

  const HomeSidePanel({
    super.key,
    required this.homeProductsStream,
    this.initialData,
    required this.isSeller,
  });

  @override
  State<HomeSidePanel> createState() => _HomeSidePanelState();
}

class _HomeSidePanelState extends State<HomeSidePanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Breakpoints.useTwoPaneLayout(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isWide) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SidePanelCard(
            title: 'Najprodavaniji proizvodi',
            icon: Icons.trending_up,
            height: 236,
            child: TopProductsList(
                homeProductsStream: widget.homeProductsStream,
                initialData: widget.initialData),
          ),
          const SizedBox(height: 12),
          const SidePanelCard(
            title: 'Omiljena gazdinstva',
            icon: Icons.favorite_border,
            height: 236,
            child: FavoriteFarmsList(),
          ),
        ],
      );
    }

    final children = [
      TopProductsList(
          homeProductsStream: widget.homeProductsStream,
          initialData: widget.initialData),
      FavoriteFarmsList(tabController: _tabController),
    ];
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
          width: 1.0,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            onTap: (_) => HapticFeedback.selectionClick(),
            labelColor: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
            unselectedLabelColor:
                isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
            indicatorColor: AmazonColors.amberDark,
            tabs: const [
              Tab(text: 'Najprodavaniji proizvodi'),
              Tab(text: 'Omiljena gazdinstva')
            ],
          ),
          SizedBox(
              height: 236,
              child: IndexedStack(
                  index: _tabController.index,
                  sizing: StackFit.expand,
                  children: children)),
        ],
      ),
    );
  }
}

class SidePanelCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double height;
  final Widget child;

  const SidePanelCard(
      {super.key,
      required this.title,
      required this.icon,
      required this.height,
      required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
          width: 1.0,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Icon(icon,
                    size: 17, color: AmazonColors.link),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 14,
            color: isDark ? AmazonColors.darkBorder : AmazonColors.borderSubtle,
          ),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

class TopProductsList extends StatelessWidget {
  final Stream<HomeProductsData> homeProductsStream;
  final HomeProductsData? initialData;

  const TopProductsList(
      {super.key, required this.homeProductsStream, this.initialData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<HomeProductsData>(
      initialData: initialData,
      stream: homeProductsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const ProductListSkeleton();
        }
        if (snapshot.hasError && !snapshot.hasData) {
          return const Center(
              child: Text('Greška pri učitavanju proizvoda.',
                  style: TextStyle(color: Colors.red)));
        }
        final data = snapshot.data;
        final list = data?.products ?? [];
        final salesCounts = data?.salesCounts ?? {};
        if (list.isEmpty) {
          return AppEmptyState(
            icon: Icons.shopping_basket_outlined,
            title: 'Još nema proizvoda u katalogu',
            subtitle:
                'Proverite ponovo kasnije ili pretražite po kategorijama.',
            ctaLabel: 'Pretraži proizvode',
            ctaIcon: Icons.search,
            onCtaPressed: () => context.push('/search'),
          );
        }

        final sorted = [...list];
        sorted.sort((a, b) {
          final sa = salesCounts[a.id] ?? 0;
          final sb = salesCounts[b.id] ?? 0;
          return sb.compareTo(sa);
        });
        final top = sorted.take(5).toList();

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          itemCount: top.length,
          separatorBuilder: (_, __) => Divider(
            height: 8,
            color: isDark ? AmazonColors.darkBorder.withValues(alpha: 0.5) : AmazonColors.borderSubtle,
          ),
          itemBuilder: (context, index) {
            final p = top[index];
            final count = salesCounts[p.id] ?? 0;
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              onTap: () => context.push('/product/${p.id}'),
              leading: p.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                            width: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: AppNetworkImage.icon(
                          imageUrl: p.imageUrls.first,
                          width: 38,
                          height: 38,
                        ),
                      ),
                    )
                  : const Icon(Icons.shopping_basket, size: 28),
              title: Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                ),
              ),
              subtitle: Text(
                '$count prodaja',
                style: const TextStyle(
                  fontSize: 11,
                  color: AmazonColors.link,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                size: 16,
                color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
              ),
            );
          },
        );
      },
    );
  }
}

