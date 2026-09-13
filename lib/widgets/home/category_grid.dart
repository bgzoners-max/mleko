import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/amazon_theme.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            isWide ? 4 : (isLargeTablet ? 4 : (isSmallTablet ? 3 : 2)),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 46,
      ),
      itemCount: topCategories.length,
      itemBuilder: (context, index) {
        final cat = topCategories[index];
        final catColor = _getCategoryColor(cat.name);

        return Semantics(
          button: true,
          label: 'Kategorija ${cat.name}',
          child: Container(
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => context.push('/categories/${cat.id}', extra: cat),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: buildCategoryIcon(
                          cat.icon,
                          size: 17,
                          color: catColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: isDark
                                ? AmazonColors.darkTextPrimary
                                : AmazonColors.textPrimary,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 15,
                        color: isDark
                            ? AmazonColors.darkTextSecondary.withValues(alpha: 0.6)
                            : AmazonColors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

