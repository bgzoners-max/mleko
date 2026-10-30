import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../providers/classifieds_provider.dart';

class ClassifiedCategoryChipsRow extends StatelessWidget {
  final ClassifiedsProvider classifieds;
  final ColorScheme colorScheme;
  final bool isDesktop;
  final ScrollController scrollController;

  const ClassifiedCategoryChipsRow({
    super.key,
    required this.classifieds,
    required this.colorScheme,
    required this.isDesktop,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 34,
      child: Row(
        children: [
          if (isDesktop)
            IconButton(
              icon: Icon(
                Icons.chevron_left,
                size: 18,
                color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              tooltip: 'Prethodne kategorije',
              onPressed: () {
                if (scrollController.hasClients) {
                  final target = (scrollController.offset - 240)
                      .clamp(0.0, scrollController.position.maxScrollExtent);
                  scrollController.animateTo(
                    target,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
            ),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: Listener(
                onPointerSignal: (pointerSignal) {
                  if (pointerSignal is PointerScrollEvent &&
                      scrollController.hasClients) {
                    final delta = pointerSignal.scrollDelta.dx != 0
                        ? pointerSignal.scrollDelta.dx
                        : pointerSignal.scrollDelta.dy;
                    final target = (scrollController.offset + delta)
                        .clamp(0.0, scrollController.position.maxScrollExtent);
                    scrollController.jumpTo(target);
                  }
                },
                child: ListView.builder(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 4 : 8),
                  itemCount: classifieds.categories.length + 1,
                  itemBuilder: (ctx, idx) {
                    if (idx == 0) {
                      final isAll = classifieds.selectedCategoryId == null;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: isAll,
                          label: const Text('Sve', style: TextStyle(fontSize: 11.5)),
                          backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
                          selectedColor: AmazonColors.navNavy,
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isAll ? FontWeight.w700 : FontWeight.w500,
                            color: isAll
                                ? Colors.white
                                : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                          ),
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isAll
                                  ? AmazonColors.navNavy
                                  : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
                              width: isAll ? 1.4 : 1.0,
                            ),
                          ),
                          onSelected: (_) => classifieds.selectCategory(null),
                        ),
                      );
                    }
                    final cat = classifieds.categories[idx - 1];
                    final activeRoot = classifieds.activeRootCategory;
                    final isSelected = activeRoot?.id == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        selected: isSelected,
                        avatar: Icon(
                          cat.iconData,
                          size: 13,
                          color: isSelected
                              ? AmazonColors.amberLight
                              : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.navNavy),
                        ),
                        label: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                          ),
                        ),
                        backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
                        selectedColor: AmazonColors.navNavy,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected
                                ? AmazonColors.navNavy
                                : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        onSelected: (sel) =>
                            classifieds.selectCategory(sel ? cat.id : null),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (isDesktop)
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                size: 18,
                color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              tooltip: 'Sledeće kategorije',
              onPressed: () {
                if (scrollController.hasClients) {
                  final target = (scrollController.offset + 240)
                      .clamp(0.0, scrollController.position.maxScrollExtent);
                  scrollController.animateTo(
                    target,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}
