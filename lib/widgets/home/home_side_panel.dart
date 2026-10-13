import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/amazon_theme.dart';
import '../../core/responsive.dart';
import '../../models/home_products_data.dart';
import '../../providers/app_state.dart';
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

    final textScale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.4);
    final cardHeight = (236.0 * textScale).roundToDouble();

    if (isWide) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SidePanelCard(
            title: 'Najprodavaniji proizvodi',
            icon: Icons.trending_up,
            height: cardHeight,
            child: TopProductsList(
                homeProductsStream: widget.homeProductsStream,
                initialData: widget.initialData),
          ),
          const SizedBox(height: 12),
          SidePanelCard(
            title: 'Omiljena gazdinstva',
            icon: Icons.favorite_border,
            height: cardHeight,
            child: const FavoriteFarmsList(),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
          width: 1.0,
        ),
        boxShadow: AmazonColors.getCardShadow(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 10),
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
              height: cardHeight,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
          width: 1.0,
        ),
        boxShadow: AmazonColors.getCardShadow(context),
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
                    size: 17, color: isDark ? AmazonColors.lightGreen : AmazonColors.link),
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
    final isSeller = context.select<AppState, bool>((s) => s.user?.isSeller ?? false);

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
            title: 'Još nema ponude u katalogu',
            subtitle: isSeller
                ? 'Dodajte svoje proizvode i započnite prodaju.'
                : 'Proizvodite domaću hranu? Otvorite svoju online tezgu besplatno.',
            ctaLabel: isSeller ? 'Dodaj proizvod' : 'Postani prodavac',
            ctaIcon: Icons.add_business_outlined,
            onCtaPressed: () => context.push(isSeller ? '/add-product' : '/becoming-seller'),
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
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AmazonColors.lightGreen : AmazonColors.link,
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

