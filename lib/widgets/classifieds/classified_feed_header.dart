import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/responsive.dart';
import '../../theme/amazon_colors.dart';

class ClassifiedFeedHeader extends StatelessWidget {
  const ClassifiedFeedHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);

    return Container(
      color: AmazonColors.darkNavy,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 12,
        vertical: 8,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go('/'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'DOMAĆI MARKET',
                  style: TextStyle(
                    color: Colors.white,
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
            icon: const Icon(Icons.storefront_outlined, size: 15, color: Color(0xFF86EFAC)),
            label: Text(
              isDesktop ? 'Pređi na Pijacu hrane' : 'Pijaca hrane',
              style: const TextStyle(
                color: Color(0xFF86EFAC),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
