import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/responsive.dart';
import '../../models/home_products_data.dart';
import '../skeleton.dart';
import '../app_empty_state.dart';
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
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            onTap: (_) => HapticFeedback.selectionClick(),
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
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
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon,
                    size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Divider(height: 16),
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
    return StreamBuilder<HomeProductsData>(
      initialData: initialData,
      stream: homeProductsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const ProductListSkeleton();
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('GreÅ¡ka pri uÄitavanju proizvoda.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.red)));
        }
        final data = snapshot.data;
        final list = data?.products ?? [];
        final salesCounts = data?.salesCounts ?? {};
        if (list.isEmpty) {
          return AppEmptyState(
            icon: Icons.shopping_basket_outlined,
            title: 'JoÅ¡ nema proizvoda u katalogu',
            subtitle:
                'Proverite ponovo kasnije ili pretraÅ¾ite po kategorijama.',
            ctaLabel: 'PretraÅ¾i proizvode',
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
          padding: const EdgeInsets.all(12),
          itemCount: top.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final p = top[index];
            final count = salesCounts[p.id] ?? 0;
            return ListTile(
              onTap: () => context.push('/product/${p.id}'),
              leading: p.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: p.imageUrls.first,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        memCacheWidth: 80,
                        memCacheHeight: 80,
                        fadeInDuration: Duration.zero,
                      ),
                    )
                  : const Icon(Icons.shopping_basket),
              title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('$count prodaja'),
            );
          },
        );
      },
    );
  }
}
