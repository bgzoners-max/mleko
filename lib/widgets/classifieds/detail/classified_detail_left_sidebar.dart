import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system.dart';
import '../../../models/classified_ad_model.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/app_state.dart';
import '../../../providers/classifieds_provider.dart';
import '../../../providers/unread_notifications_provider.dart';

/// Levi navigacioni sidebar za detalje malog oglasa na širokom desktopu (`>= 1200 px`).
/// Pruža brze prečice za rad sa oglasima i nalogom bez pretrpavanja glavne kartice.
class ClassifiedDetailLeftSidebar extends StatelessWidget {
  const ClassifiedDetailLeftSidebar({
    super.key,
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final user = context.select((AppState? s) => s?.user);
    final unreadNotifications =
        context.select((UnreadNotificationsProvider? p) => p?.unreadCount ?? 0);
    final savedSearchCount =
        context.select((ClassifiedsProvider? p) => p?.subscriptions.length ?? 0);
    final isLoggedIn = user != null && !user.isGuest;
    final cardBg = isDark ? AmazonColors.darkCard : AmazonColors.cardWhite;
    final borderColor =
        isDark ? AmazonColors.darkBorder : AmazonColors.borderGray;
    final primaryText =
        isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary;
    final secondaryText =
        isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: AmazonColors.getCardShadow(context),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoggedIn) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName?.trim().isNotEmpty == true
                        ? user.displayName!
                        : (user.farmName?.trim().isNotEmpty == true
                            ? user.farmName!
                            : 'Moj nalog'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: primaryText,
                    ),
                  ),
                  if (user.email != null && user.email!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: secondaryText),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Moj Domaći Market',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => context.push('/login'),
                    icon: const Icon(Icons.login_rounded, size: 16),
                    label: const Text('Prijavi se'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Divider(height: 1, color: borderColor.withValues(alpha: 0.7)),
          const SizedBox(height: 6),
          _SidebarNavItem(
            icon: Icons.folder_copy_outlined,
            label: 'Moji oglasi',
            isDark: isDark,
            onTap: () => context.push('/classifieds/my'),
          ),
          _SidebarNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Poruke',
            isDark: isDark,
            onTap: () => context.push('/conversations'),
          ),
          _SidebarNavItem(
            icon: Icons.notifications_none_rounded,
            label: 'Obaveštenja',
            badgeCount: unreadNotifications,
            isDark: isDark,
            onTap: () => context.push('/notifications'),
          ),
          _SidebarNavItem(
            icon: Icons.favorite_border_rounded,
            label: 'Sačuvani oglasi',
            isDark: isDark,
            onTap: () => context.push('/favorites?tab=classifieds'),
          ),
          _SidebarNavItem(
            icon: Icons.bookmark_border_rounded,
            label: 'Sačuvane pretrage',
            badgeCount: savedSearchCount,
            isDark: isDark,
            onTap: () => context.push('/classifieds/saved-searches'),
          ),
          _SidebarNavItem(
            icon: Icons.storefront_outlined,
            label: 'Omiljeni prodavci',
            isDark: isDark,
            onTap: () => context.push('/favorite-sellers'),
          ),
          if (isLoggedIn) ...[
            _SidebarNavItem(
              icon: Icons.star_outline_rounded,
              label: 'Moje ocene',
              isDark: isDark,
              onTap: () => context.push(
                user.isSeller
                    ? '/seller/${user.id}/reviews'
                    : '/buyer/${user.id}/reviews',
              ),
            ),
            _SidebarNavItem(
              icon: Icons.person_outline_rounded,
              label: 'Moj nalog',
              isDark: isDark,
              onTap: () => context.push('/profile'),
            ),
          ],
          const SizedBox(height: 6),
          Divider(height: 1, color: borderColor.withValues(alpha: 0.7)),
          const SizedBox(height: 6),
          _SidebarNavItem(
            icon: Icons.eco_outlined,
            label: 'Pijaca hrane',
            accentColor: isDark ? AmazonColors.lightGreen : AmazonColors.green,
            isDark: isDark,
            onTap: () {
              context
                  .read<AppSettingsProvider?>()
                  ?.setMarketMode(MarketMode.foodMarket);
              context.go('/');
            },
          ),
          _SidebarNavItem(
            icon: Icons.add_circle_outline_rounded,
            label: 'Postavi oglas',
            accentColor:
                isDark ? AmazonColors.amberLight : AmazonColors.amberDark,
            isDark: isDark,
            onTap: () => context.push('/classifieds/add'),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: borderColor.withValues(alpha: 0.7)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Icon(Icons.euro_rounded, size: 14, color: secondaryText),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Kurs evra · ~${ClassifiedAdModel.eurToRsdRate.toStringAsFixed(1)} RSD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.badgeCount = 0,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final int badgeCount;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final textColor = accentColor ??
        (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary);
    final iconColor = accentColor ??
        (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 17, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        accentColor != null ? FontWeight.w700 : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AmazonColors.green.withValues(alpha: 0.3)
                        : AmazonColors.green.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color:
                          isDark ? AmazonColors.lightGreen : AmazonColors.green,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
