import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/responsive.dart';
import '../providers/categories_provider.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/category_icon.dart';
import '../widgets/skeleton.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<CategoriesProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategorije')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final catProvider = context.watch<CategoriesProvider>();
    final loading = catProvider.isLoading;
    final error = catProvider.error;
    final sections = catProvider.categoriesBySection;

    if (loading && !catProvider.isLoaded) {
      return const CategoryGridSkeleton();
    }
    if (error != null) {
      return AppErrorRetry(
        message: 'Greška pri učitavanju',
        detail: error.toString(),
        onRetry: () => catProvider.refresh(),
      );
    }
    if (sections.isEmpty) {
      return const AppEmptyState(
        icon: Icons.category_outlined,
        title: 'Nema kategorija',
        subtitle: 'Kategorije će se pojaviti kada budu dodate.',
      );
    }

    final padding = Breakpoints.horizontalPadding(context);
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final isSmallTablet = Breakpoints.isSmallTablet(context);
    final gridColumns = Breakpoints.isDesktop(context)
        ? 4
        : (isLargeTablet ? 4 : (isSmallTablet ? 3 : 2));
    final cardPadding = isLargeTablet ? 14.0 : (isSmallTablet ? 12.0 : 16.0);
    final iconSize = isLargeTablet ? 30.0 : (isSmallTablet ? 32.0 : 36.0);

    return RefreshIndicator(
      onRefresh: () => catProvider.refresh(),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.isDesktop(context)
                ? 960
                : Breakpoints.maxContentWidth(context),
          ),
          child: CustomScrollView(
            slivers: [
              for (final section in sections) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padding, padding, padding, 8),
                    child: Row(
                      children: [
                        Text(
                          section.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          section.label,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(padding, 0, padding, 4),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cat = section.categories[index];
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => context.push('/categories/${cat.id}',
                                extra: cat),
                            child: Padding(
                              padding: EdgeInsets.all(cardPadding),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  buildCategoryIcon(
                                    cat.icon,
                                    size: iconSize,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    cat.name,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: section.categories.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridColumns,
                      childAspectRatio:
                          isLargeTablet ? 1.08 : (isSmallTablet ? 1.0 : 0.96),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(child: SizedBox(height: padding)),
            ],
          ),
        ),
      ),
    );
  }
}
