import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/category.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  /// Fetches top-level categories (where parent_id is null)
  Future<List<Category>> getTopCategories() async {
    final res = await _client
        .from('categories')
        .select()
        .filter('parent_id', 'is', null)
        .order('order', ascending: true);

    return (res as List).map((e) => Category.fromJson(e)).toList();
  }

  /// Fetches all categories (top + children) for product form, search filters, etc.
  /// Order: top-level first, then children, each by "order"
  Future<List<Category>> getAllCategories() async {
    final res = await _client.from('categories').select().order('order', ascending: true);
    final list = (res as List).map((e) => Category.fromJson(e)).toList();
    list.sort((a, b) {
      final aTop = a.parentId == null;
      final bTop = b.parentId == null;
      if (aTop != bTop) return aTop ? -1 : 1;
      return a.order.compareTo(b.order);
    });
    return list;
  }

  /// Grupisane kategorije – roditelji sa podkategorijama za hijerarhijski prikaz
  Future<List<CategoryGroup>> getCategoriesGrouped() async {
    final all = await getAllCategories();
    final topLevel = all.where((c) => c.parentId == null).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return topLevel.map((parent) {
      final children = all.where((c) => c.parentId == parent.id).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return CategoryGroup(parent: parent, children: children);
    }).toList();
  }

  /// Fetches child categories for a given parent
  Future<List<Category>> getChildCategories(String parentId) async {
    final res = await _client
        .from('categories')
        .select()
        .eq('parent_id', parentId)
        .order('order', ascending: true);

    return (res as List).map((e) => Category.fromJson(e)).toList();
  }
}
