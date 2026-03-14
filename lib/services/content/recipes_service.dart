import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/recipe_model.dart';

class RecipesService {
  final _client = Supabase.instance.client;

  Future<List<RecipeModel>> getRecipes({String? category}) async {
    var query = _client.from('recipes').select();
    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    final list = await query.order('created_at', ascending: false);
    return (list as List).map((e) => RecipeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RecipeModel?> getRecipe(String id) async {
    final res = await _client.from('recipes').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return RecipeModel.fromJson(res);
  }
}
