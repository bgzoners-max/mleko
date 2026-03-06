import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/recipes_service.dart';
import '../widgets/app_error_retry.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Future<RecipeModel?> _recipeFuture =
      RecipesService().getRecipe(widget.recipeId);

  void _retry() => setState(() {
        _recipeFuture = RecipesService().getRecipe(widget.recipeId);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recept')),
      body: FutureBuilder<RecipeModel?>(
        future: _recipeFuture,
        builder: (context, snap) {
          if (snap.hasError) {
            return AppErrorRetry(
              message: 'Greška pri učitavanju recepta.',
              detail: snap.error?.toString(),
              onRetry: _retry,
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final r = snap.data;
          if (r == null) return const Center(child: Text('Recept nije pronađen.'));
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (r.imageUrl != null && r.imageUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: r.imageUrl!,
                    height: 200,
                    memCacheWidth: 400,
                    memCacheHeight: 300,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => ColoredBox(color: Colors.grey.shade200, child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey.shade400)),
                  )
                else
                  ColoredBox(
                    color: Colors.grey.shade200,
                    child: SizedBox(
                      height: 200,
                      child: Center(child: Icon(Icons.restaurant, size: 64, color: Colors.grey.shade400)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (r.description.isNotEmpty) ...[
                        Text(r.description, style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 16),
                      ],
                      if (r.ingredients.isNotEmpty) ...[
                        Text('Sastojci', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(r.ingredients.replaceAll(',', '\n'), style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 16),
                      ],
                      if (r.instructions.isNotEmpty) ...[
                        Text('Priprema', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(r.instructions, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
