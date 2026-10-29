import 'package:flutter/material.dart';
import '../../constants/amazon_theme.dart';
import '../../models/product_model.dart';
import 'home_product_item.dart';

/// Prikaz najnovijih proizvoda u 2 reda sa horizontalnim listanjem (paginacijom)
/// stranica kao knjiga, uz strelice levo/desno i swipe podršku.
class HomePaginatedProductsShelf extends StatefulWidget {
  final List<ProductModel> products;
  final Map<String, int> salesCounts;
  final Map<String, ({double avg, int count})> ratings;
  final bool canFavorite;
  final String? userId;
  final double productGridExtent;
  final String title;

  const HomePaginatedProductsShelf({
    super.key,
    required this.products,
    required this.salesCounts,
    required this.ratings,
    required this.canFavorite,
    required this.userId,
    required this.productGridExtent,
    this.title = 'Najnovija ponuda na Pijaci',
  });

  @override
  State<HomePaginatedProductsShelf> createState() =>
      _HomePaginatedProductsShelfState();
}

class _HomePaginatedProductsShelfState
    extends State<HomePaginatedProductsShelf> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int columns;
        if (width >= 960) {
          columns = 4;
        } else if (width >= 620) {
          columns = 3;
        } else {
          columns = 2;
        }

        const maxRows = 2;
        final itemsPerPage = columns * maxRows;
        final totalPages =
            (widget.products.length / itemsPerPage).ceil().clamp(1, 9999);

        // Ako se promenila širina ekrana pa je trenutna strana veća od totalPages
        if (_currentPage >= totalPages) {
          _currentPage = totalPages - 1;
        }

        // Visina: ako ima 1 red (npr. samo 4 proizvoda na 4 kolone), ne ostavljamo prazan prostor
        final displayedRows = widget.products.length <= columns ? 1 : maxRows;
        const mainAxisSpacing = 8.0;
        final shelfHeight = (displayedRows * widget.productGridExtent) +
            ((displayedRows - 1) * mainAxisSpacing);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Zaglavlje: Naslov sa leve strane, brojač i strelice za listanje sa desne
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AmazonColors.darkTextPrimary
                            : AmazonColors.textPrimary,
                      ),
                    ),
                  ),
                  if (totalPages > 1) ...[
                    // Brojač stranica (npr. "1 / 3")
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AmazonColors.darkCard
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark
                              ? AmazonColors.darkBorder
                              : AmazonColors.borderSubtle,
                        ),
                      ),
                      child: Text(
                        '${_currentPage + 1} / $totalPages',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AmazonColors.darkTextSecondary
                              : AmazonColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Leva strelica (prethodna stranica)
                    _buildNavArrow(
                      context: context,
                      icon: Icons.chevron_left_rounded,
                      tooltip: 'Prethodna stranica',
                      onPressed: _currentPage > 0
                          ? () => _animateToPage(_currentPage - 1)
                          : null,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    // Desna strelica (sledeća stranica)
                    _buildNavArrow(
                      context: context,
                      icon: Icons.chevron_right_rounded,
                      tooltip: 'Sledeća stranica',
                      onPressed: _currentPage < totalPages - 1
                          ? () => _animateToPage(_currentPage + 1)
                          : null,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),

            // 2-redni paginirani Shelf (kao knjiga)
            SizedBox(
              height: shelfHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalPages,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, pageIndex) {
                  final startIndex = pageIndex * itemsPerPage;
                  final endIndex = (startIndex + itemsPerPage)
                      .clamp(0, widget.products.length);
                  final pageItems =
                      widget.products.sublist(startIndex, endIndex);

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: mainAxisSpacing,
                      crossAxisSpacing: 8,
                      mainAxisExtent: widget.productGridExtent,
                    ),
                    itemCount: pageItems.length,
                    itemBuilder: (context, i) {
                      final product = pageItems[i];
                      final rating = widget.ratings[product.id];
                      return HomeProductItem(
                        product: product,
                        salesCount: widget.salesCounts[product.id] ?? 0,
                        canFavorite: widget.canFavorite,
                        userId: widget.userId,
                        avgRating: rating?.avg,
                        reviewCount: rating?.count,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavArrow({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    final isEnabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isEnabled
                ? (isDark ? AmazonColors.darkCard : Colors.white)
                : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEnabled
                  ? (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray)
                  : (isDark ? Colors.transparent : const Color(0xFFE2E8F0)),
              width: 1.0,
            ),
            boxShadow: isEnabled ? AmazonColors.getCardShadow(context) : null,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: isEnabled
                  ? (isDark
                      ? AmazonColors.darkTextPrimary
                      : AmazonColors.textPrimary)
                  : (isDark ? Colors.white24 : Colors.black26),
            ),
          ),
        ),
      ),
    );
  }
}
