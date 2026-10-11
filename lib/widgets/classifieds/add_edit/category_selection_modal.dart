import 'package:flutter/material.dart';
import '../../../models/classified_category_model.dart';
import '../../../core/responsive.dart';
import 'category_card_picker.dart';

class CategorySelectionResult {
  final String id;
  final String name;
  final bool? isConditionApplicable;
  final List<ClassifiedCategoryModel> breadcrumbs;

  CategorySelectionResult({
    required this.id,
    required this.name,
    this.isConditionApplicable,
    this.breadcrumbs = const [],
  });
}

class CategorySelectionModal {
  static Future<CategorySelectionResult?> show(
    BuildContext context,
    List<ClassifiedCategoryModel> categories,
  ) async {
    final modalPath = <ClassifiedCategoryModel>[];

    return showModalBottomSheet<CategorySelectionResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              expand: false,
              builder: (_, scrollCtl) {
                Widget headerWidget;
                Widget contentWidget;

                if (modalPath.isNotEmpty) {
                  final current = modalPath.last;

                  headerWidget = Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () =>
                              setModalState(() => modalPath.removeLast()),
                        ),
                        Expanded(
                          child: Text(
                            current.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  );

                  contentWidget = ListView(
                    controller: scrollCtl,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(current.iconData,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                modalPath.length == 1
                                    ? 'Izaberite podkategoriju za ${current.name}:'
                                    : 'Izaberite marku ili tip (ili "Ostalo"):',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (current.subcategories.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        if (!current.isRoot &&
                            current.subcategories
                                    .where((s) => s.subcategories.isNotEmpty)
                                    .length >=
                                2) ...[
                          // Grupisan prikaz po sekcijama (npr. Automobili -> • NEMAČKA -> marke, • ITALIJA -> marke)
                          for (final group in current.subcategories
                              .where((s) => s.subcategories.isNotEmpty)) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 14, bottom: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    group.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: 46,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: group.subcategories.length,
                              itemBuilder: (c, i) {
                                final brand = group.subcategories[i];
                                return CategoryCardPicker(
                                  category: brand,
                                  hasChildren: false,
                                  onTap: () {
                                    final fullPath = [
                                      ...modalPath.map((e) => e.name),
                                      group.name,
                                      brand.name,
                                    ].join(' > ');
                                    Navigator.pop(
                                      ctx,
                                      CategorySelectionResult(
                                        id: brand.id,
                                        name: fullPath,
                                        isConditionApplicable:
                                            brand.isConditionApplicable,
                                        breadcrumbs: [
                                          ...modalPath,
                                          group,
                                          brand,
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                          // Samostalne podkategorije (Džipovi, Havarisana, Ostalo)
                          if (current.subcategories
                              .any((s) => s.subcategories.isEmpty)) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 16, bottom: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'OSTALO / DODATNE KATEGORIJE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: 54,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: current.subcategories
                                  .where((s) => s.subcategories.isEmpty)
                                  .length,
                              itemBuilder: (c, i) {
                                final sub = current.subcategories
                                    .where((s) => s.subcategories.isEmpty)
                                    .toList()[i];
                                return CategoryCardPicker(
                                  category: sub,
                                  hasChildren: false,
                                  onTap: () {
                                    final fullPath = [
                                      ...modalPath.map((e) => e.name),
                                      sub.name,
                                    ].join(' > ');
                                    Navigator.pop(
                                      ctx,
                                      CategorySelectionResult(
                                        id: sub.id,
                                        name: fullPath,
                                        isConditionApplicable:
                                            sub.isConditionApplicable,
                                        breadcrumbs: [...modalPath, sub],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ] else ...[
                          Text(
                            modalPath.length == 1
                                ? 'Izaberite podkategoriju:'
                                : 'Ili izaberite užu podkategoriju:',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 46,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: current.subcategories.length,
                            itemBuilder: (c, i) {
                              final sub = current.subcategories[i];
                              return CategoryCardPicker(
                                category: sub,
                                hasChildren: sub.subcategories.isNotEmpty,
                                onTap: () {
                                  if (sub.subcategories.isNotEmpty) {
                                    setModalState(() => modalPath.add(sub));
                                  } else {
                                    final fullPath = [
                                      ...modalPath.map((e) => e.name),
                                      sub.name
                                    ].join(' > ');
                                    Navigator.pop(
                                      ctx,
                                      CategorySelectionResult(
                                        id: sub.id,
                                        name: fullPath,
                                        isConditionApplicable:
                                            sub.isConditionApplicable,
                                        breadcrumbs: [...modalPath, sub],
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ],
                    ],
                  );
                } else {
                  // Nivo 1: Glavne kategorije
                  headerWidget = Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text(
                          'Izaberi kategoriju',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  );

                  contentWidget = ListView.builder(
                    controller: scrollCtl,
                    itemCount: categories.length,
                    itemBuilder: (c, i) {
                      final cat = categories[i];
                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(cat.iconData, size: 20),
                        ),
                        title: Text(cat.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: cat.subcategories.isNotEmpty
                            ? const Icon(Icons.chevron_right, size: 20)
                            : null,
                        onTap: () {
                          if (cat.subcategories.isNotEmpty) {
                            setModalState(() => modalPath.add(cat));
                          } else {
                            Navigator.pop(
                              ctx,
                              CategorySelectionResult(
                                id: cat.id,
                                name: cat.name,
                                isConditionApplicable:
                                    cat.isConditionApplicable,
                                breadcrumbs: [cat],
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                        maxWidth: Breakpoints.modalMaxWidth),
                    child: Column(
                      children: [
                        headerWidget,
                        Expanded(child: contentWidget),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
