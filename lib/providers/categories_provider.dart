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
  List<Category> get topCategories {
    if (_categories == null) return [];
    return _categories!.where((c) => c.parentId == null).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
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
  List<CategoryGroup> _buildGroups(List<Category> list) {
    final groups = <CategoryGroup>[];
    final byParent = <String?, List<Category>>{};
    for (final c in list) {
      byParent.putIfAbsent(c.parentId, () => []).add(c);
    }
    for (final cs in byParent.values) {
      cs.sort((a, b) => a.order.compareTo(b.order));
    }
    void addGroups(Category? parent, int depth) {
      final children = byParent[parent?.id] ?? [];
      if (children.isEmpty && parent != null) return;
      final leaves = <Category>[];
      final withChildren = <Category>[];
      for (final c in children) {
        final hasChild = (byParent[c.id]?.isNotEmpty ?? false);
        if (hasChild) {
          withChildren.add(c);
        } else {
          leaves.add(c);
        }
      }
      if (parent != null && leaves.isNotEmpty) {
        groups.add(CategoryGroup(parent: parent, children: leaves));
      }
      for (final c in withChildren) {
        addGroups(c, depth + 1);
      }
    }

    final topLevel = (byParent[null] ?? []).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    for (final top in topLevel) {
      addGroups(top, 0);
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

