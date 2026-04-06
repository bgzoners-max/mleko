import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/scheduler.dart';
import '../models/category.dart';
import 'package:mleko/services/services.dart';

/// Keš kategorija – učitavanje jednom pri startu, deljenje između ekrana.
class CategoriesProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<Category>? _categories;
  List<CategoryGroup>? _groups;
  bool _loading = false;
  bool _loaded = false;
  Object? _error;

  List<Category>? get categories => _categories;
  List<CategoryGroup>? get groups => _groups;
  bool get isLoading => _loading;
  bool get isLoaded => _loaded;
  Object? get error => _error;

  /// Lista imena kategorija (za chips, filtere) – fallback na praznu listu
  List<String> get categoryNames {
    if (_categories == null || _categories!.isEmpty) return [];
    return List<String>.from(_categories!.map((c) => c.name));
  }

  /// Top-level kategorije (parent_id == null)
  /// Note: Already sorted from SQL, no need to sort again
  List<Category> get topCategories {
    if (_categories == null) return [];
    return _categories!.where((c) => c.parentId == null).toList();
  }

  /// Sekcije za All Categories screen – uredjen prikaz po grupama
  static const _sectionOrder = [
    'hrana', 'osnove', 'domace', 'sveze', 'pica', 'specijaliteti', 'ostalo',
  ];

  static const _sectionLabels = {
    'hrana':         ('🥛', 'Hrana'),
    'osnove':        ('🌾', 'Osnove za kuhinju'),
    'domace':        ('🍯', 'Domaći proizvodi'),
    'sveze':         ('🍎', 'Sveže i prirodno'),
    'pica':          ('🧃', 'Pića'),
    'specijaliteti': ('🍲', 'Specijaliteti'),
    'ostalo':        ('🎨', 'Ostalo'),
  };

  /// Vraća listu (emoji, label, kategorije) za svaku sekciju, u ispravnom redoslijedu.
  List<({String emoji, String label, List<Category> categories})> get categoriesBySection {
    if (_categories == null) return [];
    final topLevel = _categories!.where((c) => c.parentId == null).toList();
    final bySection = <String, List<Category>>{};
    for (final cat in topLevel) {
      final key = cat.section ?? 'ostalo';
      bySection.putIfAbsent(key, () => []).add(cat);
    }
    return [
      for (final key in _sectionOrder)
        if (bySection.containsKey(key))
          (
            emoji: _sectionLabels[key]?.$1 ?? '📦',
            label: _sectionLabels[key]?.$2 ?? key,
            categories: bySection[key]!,
          ),
    ];
  }

  Future<void> load() async {
    if (_loading || _loaded) return;
    _loading = true;
    _error = null;
    // Defer to avoid calling notifyListeners during a build phase
    // (e.g. when load() is triggered from didChangeDependencies).
    SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
    try {
      final list = await _service.getAllCategories();
      _groups = _buildGroups(list);
      _categories = list;
      _loaded = true;
    } catch (e, st) {
      _error = e;
      LoggerService.error('Failed to load categories', e, stackTrace: st);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Gradi grupe za dropdown: svaka kategorija sa decom = grupa (3 nivoa).
  /// Top-level sa listovima + podkategorije sa svojim listovima (Šunke i pršute, Kobasice, itd.)
  /// Optimized: SQL już sortira, ne trebaju dodatna sortiranja
  List<CategoryGroup> _buildGroups(List<Category> list) {
    final groups = <CategoryGroup>[];
    final byParent = <String?, List<Category>>{};

    // Grupiraj po parent_id (već sortirano iz SQL-a po parent_id, pa po order)
    for (final c in list) {
      byParent.putIfAbsent(c.parentId, () => []).add(c);
    }

    void addGroups(Category? parent) {
      final children = byParent[parent?.id] ?? [];
      if (children.isEmpty && parent != null) return;

      final leaves = <Category>[];
      final withChildren = <Category>[];

      // Podeli decu: ona sa decom i ona bez dece (već su sortirani iz SQL-a)
      for (final c in children) {
        if (byParent.containsKey(c.id) && byParent[c.id]!.isNotEmpty) {
          withChildren.add(c);
        } else {
          leaves.add(c);
        }
      }

      // Dodaj grupu sa listovima (ako postoje)
      if (parent != null && leaves.isNotEmpty) {
        groups.add(CategoryGroup(parent: parent, children: leaves));
      }

      // Rekurzivno obradi kategorije sa decom
      for (final c in withChildren) {
        addGroups(c);
      }
    }

    // Počni sa top-level kategorijama (parent_id == null)
    final topLevel = byParent[null] ?? [];
    for (final top in topLevel) {
      addGroups(top);
    }

    return groups;
  }

  /// Force refresh – korisno posle dodavanja nove kategorije (admin)
  Future<void> refresh() async {
    _loaded = false;
    _categories = null;
    _groups = null;
    await load();
  }
}

