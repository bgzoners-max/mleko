import '../../models/classified_category_model.dart';

/// Helper klasa za izgradnju i normalizaciju hijerarhijskog stabla kategorija oglasa.
class ClassifiedCategoryTreeBuilder {
  const ClassifiedCategoryTreeBuilder._();

  /// Zastareli ID-ovi kategorija koji se filtriraju iz stabla ako postoje kanonski pandani.
  static const Set<String> obsoleteCategoryIds = {
    'stocarstvo_zivotinje',
    'prodaja_kuca',
    'industrijski_placevi',
    'gume_felne',
    'auto_multimedija_navigacija',
    'stampaci_skeneri_toneri',
    'mrezna_oprema_ruteri',
    'memorije_hard_diskovi',
    'mali_kuhinjski_aparati',
    'aparati_za_kafu',
  };

  /// Gradi hijerarhijsko stablo kategorija iz sirovih JSON podataka.
  static List<ClassifiedCategoryModel> build(List<dynamic> rawList) {
    final all = rawList
        .map((e) => ClassifiedCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..removeWhere((c) => obsoleteCategoryIds.contains(c.id));

    // Osiguraj postojanje 'zivinarstvo' i 'stocarska_oprema' pod 'poljoprivreda'
    if (!all.any((c) => c.id == 'zivinarstvo')) {
      all.add(const ClassifiedCategoryModel(
        id: 'zivinarstvo',
        name: 'Živinarstvo i peradarstvo',
        iconName: 'egg',
        parentId: 'poljoprivreda',
        sortOrder: 52,
        isConditionApplicable: false,
      ));
    }
    if (!all.any((c) => c.id == 'stocarska_oprema')) {
      all.add(const ClassifiedCategoryModel(
        id: 'stocarska_oprema',
        name: 'Stočarska oprema i muzilice',
        iconName: 'precision_manufacturing',
        parentId: 'poljoprivreda',
        sortOrder: 54,
        isConditionApplicable: true,
      ));
    }

    final roots = all.where((c) => c.isRoot).toList();
    final childrenByParent = <String, List<ClassifiedCategoryModel>>{};

    for (final c in all.where((c) => !c.isRoot)) {
      if (c.parentId != null) {
        childrenByParent.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }

    // Bezbednosna garancija: osiguraj da pod 'smartfoni' uvek postoji 'smartfoni_ostalo' (Ostale marke)
    final smartfoniChildren = childrenByParent['smartfoni'];
    if (smartfoniChildren != null &&
        !smartfoniChildren.any((c) => c.id == 'smartfoni_ostalo')) {
      smartfoniChildren.add(const ClassifiedCategoryModel(
        id: 'smartfoni_ostalo',
        name: 'Ostale marke',
        iconName: 'smartphone',
        parentId: 'smartfoni',
        sortOrder: 999,
      ));
    }

    ClassifiedCategoryModel buildSubtree(ClassifiedCategoryModel node) {
      final rawChildren = childrenByParent[node.id] ?? [];
      final nestedChildren = rawChildren.map((c) {
        // Kanon je server (isConditionApplicable iz baze/view-a).
        // Zastita u stablu obezbedjuje konzistentnost u slucaju zastarelog kesa
        // (ako je roditelj neprimenljiv, podkategorija takodje ne moze imati stanje).
        final effectiveApplicable = node.isConditionApplicable && c.isConditionApplicable;
        final updatedChild = c.isConditionApplicable != effectiveApplicable
            ? c.copyWith(isConditionApplicable: effectiveApplicable)
            : c;
        return buildSubtree(updatedChild);
      }).toList()
        ..sort(ClassifiedCategoryModel.compareCategories);
      return node.copyWith(subcategories: nestedChildren);
    }

    final list = roots.map(buildSubtree).toList()
      ..sort(ClassifiedCategoryModel.compareCategories);
    return list;
  }
}
