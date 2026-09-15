import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/amazon_theme.dart';
import '../core/responsive.dart';
import '../providers/categories_provider.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/category_icon.dart';
import '../widgets/emoji_text.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          'Kategorije',
          style: TextStyle(
            color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
        ),
      ),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = Breakpoints.horizontalPadding(context);
    final isDesktop = Breakpoints.isDesktop(context);
    final isWideDesktop = Breakpoints.isWideDesktop(context);
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final isSmallTablet = Breakpoints.isSmallTablet(context);
    final gridColumns = isWideDesktop
        ? 5
        : isDesktop
            ? 4
            : (isLargeTablet ? 4 : (isSmallTablet ? 3 : 2));
    final cardPadding = isDesktop
        ? 16.0
        : (isLargeTablet ? 14.0 : (isSmallTablet ? 12.0 : 16.0));
    final iconSize = isDesktop
        ? 32.0
        : (isLargeTablet ? 30.0 : (isSmallTablet ? 32.0 : 36.0));
    final gridSpacing = Breakpoints.adaptiveDouble(
      context,
      phone: 8,
      smallTabletValue: 10,
      largeTabletValue: 12,
      desktop: 12,
    );

    return RefreshIndicator(
      onRefresh: () => catProvider.refresh(),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop
                ? Breakpoints.dataContentWidth(context)
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
                        EmojiText(
                          section.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          section.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
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
                          elevation: 0,
                          color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                              width: 1.0,
                            ),
                          ),
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: isDark
                                          ? AmazonColors.darkTextPrimary
                                          : AmazonColors.textPrimary,
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
                      childAspectRatio: isWideDesktop
                          ? 1.14
                          : isLargeTablet
                              ? 1.08
                              : (isSmallTablet ? 1.02 : 0.96),
                      crossAxisSpacing: gridSpacing,
                      mainAxisSpacing: gridSpacing,
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
