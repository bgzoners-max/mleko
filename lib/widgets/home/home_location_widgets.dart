import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/design_system.dart';
import '../../providers/location_provider.dart';

class HomeRegionBanner extends StatelessWidget {
  final String selectedRegion;
  final bool isDark;
  final VoidCallback onChangeTap;

  const HomeRegionBanner({
    super.key,
    required this.selectedRegion,
    required this.isDark,
    required this.onChangeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
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
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 16,
            color: isDark ? AmazonColors.lightGreen : AmazonColors.link,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Prikaz za region: $selectedRegion',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AmazonColors.darkTextPrimary
                    : AmazonColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onChangeTap,
            child: Text(
              'Promeni',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AmazonColors.lightGreen : AmazonColors.link,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showHomeLocationPicker(BuildContext context) async {
  final loc = context.read<LocationProvider>();
  if (!loc.gpsTried) {
    final detected = await loc.tryDetectFromGps();
    if (detected && context.mounted) {
      return;
    }
  }
  if (!context.mounted) return;
  final chosen = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Izaberi region',
              style: Theme.of(ctx)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: Icon(Icons.my_location,
                color: Theme.of(ctx).colorScheme.primary),
            title: const Text('Pokušaj GPS ponovo'),
            subtitle: const Text('Automatski odredi najbliži region'),
            onTap: () => Navigator.pop(ctx, '__gps_retry__'),
          ),
          ListTile(
            leading: Icon(Icons.location_off,
                color: Theme.of(ctx).colorScheme.outline),
            title: const Text('Prikaži sve regione'),
            subtitle: const Text('Bez filtera po lokaciji'),
            onTap: () => Navigator.pop(ctx, ''),
          ),
          const Divider(height: 1),
          ...AppConstants.regions.map((r) => ListTile(
                title: Text(r),
                trailing: loc.selectedRegion == r
                    ? Icon(Icons.check,
                        color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, r),
              )),
        ],
      ),
    ),
  );
  if (chosen != null && context.mounted) {
    if (chosen == '__gps_retry__') {
      final detected = await loc.tryDetectFromGps(force: true);
      if (!detected && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokacija nije dostupna. Izaberite region ručno.'),
          ),
        );
      }
    } else if (chosen.isEmpty) {
      unawaited(loc.clearRegion());
    } else {
      await loc.setRegion(chosen);
    }
  }
}
