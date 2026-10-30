import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/design_system.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/classifieds_provider.dart';
import '../beta_announcement_banner.dart';
import '../theme_toggle_switch.dart';

class HomeMobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  final bool isGuest;
  final int unreadCount;
  final int cartCount;
  final VoidCallback onLocationTap;

  const HomeMobileAppBar({
    super.key,
    required this.isDark,
    required this.isGuest,
    required this.unreadCount,
    required this.cartCount,
    required this.onLocationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      elevation: 0,
      backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
      foregroundColor:
          isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
          width: 1.0,
        ),
      ),
      titleSpacing: 8,
      title: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          context
              .read<AppSettingsProvider>()
              .setMarketMode(MarketMode.foodMarket);
          context.read<ClassifiedsProvider>().clearFilters();
          context.go('/');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/domaci_market_logo_v2.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.storefront_rounded,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  AppConstants.appName,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.5,
                    color: isDark
                        ? AmazonColors.darkTextPrimary
                        : AmazonColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                const BetaBadge(showInfoIcon: false),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (!isGuest)
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              backgroundColor: AmazonColors.dealRed,
              child: const Icon(Icons.notifications_none_rounded, size: 22),
            ),
            onPressed: () => context.push('/notifications'),
          ),
        IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            backgroundColor: AmazonColors.amber,
            textColor: AmazonColors.darkNavy,
            child: const Icon(Icons.shopping_cart_outlined, size: 22),
          ),
          onPressed: () => context.push('/cart'),
        ),
        IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(Icons.location_on_outlined, size: 22),
          tooltip: 'Izaberi lokaciju',
          onPressed: onLocationTap,
        ),
        const SizedBox(width: 4),
        const Center(child: ThemeToggleSwitch()),
        const SizedBox(width: 6),
      ],
    );
  }
}
