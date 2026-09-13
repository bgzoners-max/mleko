import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../models/classified_category_model.dart';
import '../../providers/app_state.dart';
import '../../providers/classifieds_provider.dart';

/// Pomoćna funkcija za pretplatu na kategoriju ili pretragu oglasa.
Future<void> handleClassifiedSubscribe(
  BuildContext context,
  ClassifiedsProvider classifieds, {
  String? categoryId,
  String? searchQuery,
  double? maxPrice,
}) async {
  AppHaptics.selection();
  final user = context.read<AppState>().user;
  if (user == null || user.isGuest) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prijavite se da biste pratili kategorije i primali obaveštenja.'),
      ),
    );
    return;
  }

  final cat = categoryId != null ? classifieds.findCategory(categoryId) : null;
  final targetName = cat?.name ?? (searchQuery != null ? '„$searchQuery”' : 'ovu pretragu');

  if (categoryId != null && classifieds.isCategorySubscribed(categoryId)) {
    final success = await classifieds.toggleCategorySubscription(categoryId: categoryId);
    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Više ne pratite kategoriju $targetName.')),
      );
    }
    return;
  }

  final targetCatId = categoryId ?? classifieds.activeRootCategory?.id;
  if (targetCatId == null && (searchQuery == null || searchQuery.isEmpty)) {
    return;
  }

  final success = await classifieds.toggleCategorySubscription(
    categoryId: targetCatId ?? '',
    searchQuery: searchQuery,
    maxPrice: maxPrice,
  );

  if (context.mounted && success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pratite $targetName! Dobićete obaveštenje za nove oglase.'),
        action: SnackBarAction(
          label: 'Moje pretrage',
          onPressed: () => context.push('/classifieds/saved-searches'),
        ),
      ),
    );
  }
}

/// Dugme/chip za praćenje kategorije i dobijanje notifikacija o novim oglasima.
class ClassifiedCategorySubscriptionChip extends StatelessWidget {
  final ClassifiedCategoryModel category;

  const ClassifiedCategorySubscriptionChip({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final classifieds = context.watch<ClassifiedsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isSubscribed = classifieds.isCategorySubscribed(category.id);

    return Tooltip(
      message: isSubscribed
          ? 'Pratite „${category.name}”. Dodirnite za otkazivanje obaveštenja.'
          : 'Pratite „${category.name}” i dobijajte notifikacije o novim oglasima.',
      child: SizedBox(
        height: 38,
        child: OutlinedButton.icon(
          onPressed: () => handleClassifiedSubscribe(
            context,
            classifieds,
            categoryId: category.id,
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: isSubscribed
                ? colorScheme.primaryContainer.withValues(alpha: 0.7)
                : colorScheme.surface,
            foregroundColor: isSubscribed
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
            side: BorderSide(
              color: isSubscribed
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.6),
              width: isSubscribed ? 1.5 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          icon: Icon(
            isSubscribed
                ? Icons.notifications_active_rounded
                : Icons.notification_add_outlined,
            size: 16,
            color: isSubscribed ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          label: Text(
            isSubscribed ? 'Pratite' : 'Prati',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSubscribed ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
