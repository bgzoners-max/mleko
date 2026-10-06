import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../models/classified_ad_model.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/classifieds_provider.dart';
import '../../../theme/amazon_colors.dart';

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
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        InkWell(
          onTap: () {
            context.read<AppSettingsProvider>().setMarketMode(MarketMode.foodMarket);
            context.read<ClassifiedsProvider>().clearFilters();
            context.go('/');
          },
          child: Text(
            'Početna',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ),
        Icon(Icons.chevron_right, size: 14, color: colorScheme.onSurfaceVariant),
        Text(
          'Mali oglasi',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        if (ad.categoryName != null) ...[
          Icon(Icons.chevron_right, size: 14, color: colorScheme.onSurfaceVariant),
          Text(
            ad.categoryName!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AmazonColors.lightGreen
                  : AmazonColors.link,
            ),
          ),
        ],
      ],
    );
  }
}
