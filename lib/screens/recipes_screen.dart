import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/recipe_model.dart';
import '../services/recipes_service.dart';
import '../widgets/app_error_retry.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  late Future<List<RecipeModel>> _recipesFuture =
      RecipesService().getRecipes();

  void _retry() => setState(() {
        _recipesFuture = RecipesService().getRecipes();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recepti')),
      body: FutureBuilder<List<RecipeModel>>(
        future: _recipesFuture,
        builder: (context, snap) {
          if (snap.hasError) {
            return AppErrorRetry(
              message: 'Greška pri učitavanju recepta.',
              detail: snap.error?.toString(),
              onRetry: _retry,
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Nema recepta', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final r = list[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.push('/recipe/${r.id}'),
                  child: Row(
                    children: [
                      if (r.imageUrl != null && r.imageUrl!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: r.imageUrl!,
                          width: 100,
                          memCacheWidth: 200,
                          memCacheHeight: 200,
                          height: 100,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => ColoredBox(color: Colors.grey.shade200, child: Icon(Icons.image_not_supported, color: Colors.grey.shade400)),
                        )
                      else
                        ColoredBox(
                          color: Colors.grey.shade200,
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: Icon(Icons.restaurant, size: 40, color: Colors.grey.shade400),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(r.category, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              if (r.description.isNotEmpty)
                                Text(r.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
