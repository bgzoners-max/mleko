import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/category.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  /// Fetches top-level categories (where parent_id is null)
  /// Optimized: SQL ordering + minimal select
  Future<List<Category>> getTopCategories() async {
    final res = await _client
        .from('categories')
        .select('id,name,slug,icon,order,parent_id')
        .filter('parent_id', 'is', null)
        .order('order', ascending: true);

    return (res as List).map((e) => Category.fromJson(e)).toList();
  }

  /// Fetches all categories (top + children) for product form, search filters, etc.
  /// Optimized: SQL ordering handles top-level first, then children within groups
  /// Minimal select reduces payload size
  Future<List<Category>> getAllCategories() async {
    final res = await _client
        .from('categories')
        .select('id,name,slug,icon,order,parent_id')
        // Order by: parent_id (nulls first), then order within each group
        .order('parent_id', ascending: true, nullsFirst: true)
        .order('order', ascending: true);

    return (res as List).map((e) => Category.fromJson(e)).toList();
  }

  /// Grupisane kategorije – roditelji sa podkategorijama za hijerarhijski prikaz
  /// Uses getAllCategories which is already ordered for efficient grouping
  Future<List<CategoryGroup>> getCategoriesGrouped() async {
    final all = await getAllCategories();

    // Build a map for quick lookup
    final byParent = <String?, List<Category>>{};
    for (final c in all) {
      byParent.putIfAbsent(c.parentId, () => []).add(c);
    }

    // Build groups: iterate top-level and their children
    final groups = <CategoryGroup>[];
    final topLevel = byParent[null] ?? [];

    for (final parent in topLevel) {
      final children = byParent[parent.id] ?? [];
      if (children.isNotEmpty) {
        groups.add(CategoryGroup(parent: parent, children: children));
      }
    }

    return groups;
  }

  /// Fetches child categories for a given parent
  /// Optimized: minimal select
  Future<List<Category>> getChildCategories(String parentId) async {
    final res = await _client
        .from('categories')
        .select('id,name,slug,icon,order,parent_id')
        .eq('parent_id', parentId)
        .order('order', ascending: true);

    return (res as List).map((e) => Category.fromJson(e)).toList();
  }
}
