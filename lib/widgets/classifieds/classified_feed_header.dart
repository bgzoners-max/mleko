import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/responsive.dart';
import '../../theme/amazon_colors.dart';

class ClassifiedFeedHeader extends StatelessWidget {
  const ClassifiedFeedHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkNavy : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : AmazonColors.borderGray,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 12,
        vertical: 8,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go('/'),
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DOMAĆI MARKET',
                  style: TextStyle(
                    color: isDark ? Colors.white : AmazonColors.darkNavy,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AmazonColors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'MALI OGLASI',
                    style: TextStyle(
                      color: AmazonColors.darkNavy,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: Icon(
              Icons.storefront_outlined,
              size: 15,
              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
            ),
            label: Text(
              isDesktop ? 'Pređi na Pijacu hrane' : 'Pijaca hrane',
              style: TextStyle(
                color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFF0FDF4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : const Color(0xFFBBF7D0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
