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

  Color _getCategoryColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mlek') || lower.contains('sir') || lower.contains('kajmak')) {
      return const Color(0xFF0288D1); // Mlečni proizvodi - Plava
    }
    if (lower.contains('med') || lower.contains('pčel')) {
      return const Color(0xFFE65100); // Med i pčelinji proizvodi - Zlatno narandžasta
    }
    if (lower.contains('meso') ||
        lower.contains('suhomesnato') ||
        lower.contains('specijalitet') ||
        lower.contains('slanina') ||
        lower.contains('čvarci') ||
        lower.contains('šunka')) {
      return const Color(0xFFB71C1C); // Suhomesnato - Bordo/Crvena
    }
    if (lower.contains('voće') ||
        lower.contains('povrće') ||
        lower.contains('bašta') ||
        lower.contains('zelen')) {
      return const Color(0xFF2E7D32); // Voće i povrće - Sveže zelena
    }
    if (lower.contains('hleb') || lower.contains('peciv') || lower.contains('brašno')) {
      return const Color(0xFF795548); // Peciva i brašno - Topla pekar siva
    }
    if (lower.contains('jaj')) {
      return const Color(0xFFF57F17); // Jaja - Žuto-zlatna
    }
    if (lower.contains('pić') || lower.contains('sok') || lower.contains('vino')) {
      return const Color(0xFF6A1B9A); // Pića i sokovi - Ljubičasta
    }
    return const Color(0xFF1B5E20); // Podrazumevana primarna zelena
  }

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
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 56,
      ),
      itemCount: topCategories.length,
      itemBuilder: (context, index) {
        final cat = topCategories[index];
        final catColor = _getCategoryColor(cat.name);

        return Semantics(
          button: true,
          label: 'Kategorija ${cat.name}',
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: catColor.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            color: catColor.withValues(alpha: 0.05),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/categories/${cat.id}', extra: cat),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: buildCategoryIcon(
                        cat.icon,
                        size: 22,
                        color: catColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: Theme.of(context).colorScheme.onSurface,
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
