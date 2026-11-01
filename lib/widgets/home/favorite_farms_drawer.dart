import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/amazon_theme.dart';
import '../../core/responsive.dart';
import 'favorite_farms_list.dart';

/// Prikazuje moderan bočni panel (slide-over drawer sa desne strane na desktopu,
/// ili modal bottom sheet na mobilnim uređajima) sa omiljenim gazdinstvima.
void showFavoriteFarmsDrawer(BuildContext context) {
  final isDesktopOrTablet = Breakpoints.isTabletOrLarger(context);

  if (isDesktopOrTablet) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Omiljena gazdinstva',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(
                  410.0,
                  MediaQuery.sizeOf(dialogContext).width * 0.88,
                ),
                maxHeight: MediaQuery.sizeOf(dialogContext).height,
              ),
              child: const _FavoriteFarmsDrawerContent(isDrawer: true),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        );
        return SlideTransition(position: slide, child: child);
      },
    );
  } else {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        final height = MediaQuery.sizeOf(bottomSheetContext).height * 0.85;
        return SizedBox(
          height: height,
          child: const _FavoriteFarmsDrawerContent(isDrawer: false),
        );
      },
    );
  }
}

class _FavoriteFarmsDrawerContent extends StatelessWidget {
  final bool isDrawer;

  const _FavoriteFarmsDrawerContent({required this.isDrawer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AmazonColors.darkCard : Colors.white;
    final borderColor = isDark ? AmazonColors.darkBorder : AmazonColors.borderGray;

    final borderRadius = isDrawer
        ? const BorderRadius.horizontal(left: Radius.circular(20))
        : const BorderRadius.vertical(top: Radius.circular(20));

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: isDrawer ? const Offset(-6, 0) : const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: isDrawer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Zaglavlje panela
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AmazonColors.dealRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 20,
                      color: AmazonColors.dealRed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Omiljena gazdinstva',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AmazonColors.darkTextPrimary
                                : AmazonColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gazdinstva koja pratite i njihova ponuda',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AmazonColors.darkTextSecondary
                                : AmazonColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    tooltip: 'Zatvori',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? AmazonColors.darkBorder : AmazonColors.borderSubtle,
            ),

            // Glavni sadržaj: lista omiljenih gazdinstava
            const Expanded(
              child: FavoriteFarmsList(),
            ),

            Divider(
              height: 1,
              color: isDark ? AmazonColors.darkBorder : AmazonColors.borderSubtle,
            ),

            // Donja sekcija: prečica ka mapi gazdinstava
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/sellers-map');
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(
                    color: isDark
                        ? AmazonColors.darkBorder
                        : AmazonColors.borderGray,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.map_outlined,
                  size: 18,
                  color: AmazonColors.green,
                ),
                label: Text(
                  'Zavirite u komšiluk na mapi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AmazonColors.darkTextPrimary
                        : AmazonColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
