import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/responsive.dart';
import '../category_icon.dart';

class CategoryGrid extends StatelessWidget {
  final List topCategories;
  final bool isWide;

  const CategoryGrid({
    super.key,
    required this.topCategories,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final isSmallTablet = Breakpoints.isSmallTablet(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            isWide ? 4 : (isLargeTablet ? 4 : (isSmallTablet ? 3 : 2)),
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        mainAxisExtent: 52,
      ),
      itemCount: topCategories.length,
      itemBuilder: (context, index) {
        final cat = topCategories[index];
        final colorScheme = Theme.of(context).colorScheme;
        return Semantics(
          button: true,
          label: 'Kategorija ${cat.name}',
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            color: colorScheme.surfaceContainerLow,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.push('/categories/${cat.id}', extra: cat),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: buildCategoryIcon(
                        cat.icon,
                        size: 24,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
}
