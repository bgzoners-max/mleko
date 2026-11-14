import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system.dart';
import '../../../core/responsive.dart';
import '../../../models/classified_ad_model.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/classifieds_provider.dart';

class ClassifiedBreadcrumbs extends StatelessWidget {
  final ClassifiedAdModel ad;
  final ColorScheme colorScheme;

  const ClassifiedBreadcrumbs({
    super.key,
    required this.ad,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final linkColor = Theme.of(context).brightness == Brightness.dark
        ? AmazonColors.lightGreen
        : AmazonColors.link;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        if (isDesktop) ...[
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/classifieds');
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, size: 14, color: linkColor),
                  const SizedBox(width: 4),
                  Text(
                    'Nazad',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: linkColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            '|',
            style: TextStyle(fontSize: 12, color: colorScheme.outlineVariant),
          ),
        ],
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {
            context.read<AppSettingsProvider?>()?.setMarketMode(MarketMode.foodMarket);
            context.read<ClassifiedsProvider?>()?.clearFilters();
            context.go('/');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              'Početna',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        Icon(Icons.chevron_right, size: 14, color: colorScheme.onSurfaceVariant),
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {
            context.read<AppSettingsProvider?>()?.setMarketMode(MarketMode.classifieds);
            context.read<ClassifiedsProvider?>()?.clearFilters();
            context.go('/classifieds');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              'Mali oglasi',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        if (ad.categoryName != null) ...[
          Icon(Icons.chevron_right, size: 14, color: colorScheme.onSurfaceVariant),
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              context.read<AppSettingsProvider?>()?.setMarketMode(MarketMode.classifieds);
              if (ad.categoryId.isNotEmpty) {
                context.read<ClassifiedsProvider?>()?.selectCategory(ad.categoryId);
                context.go('/classifieds?category=${Uri.encodeComponent(ad.categoryId)}');
              } else {
                context.go('/classifieds');
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Text(
                ad.categoryName!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: linkColor,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
