import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/categories_provider.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/category_icon.dart';
import '../widgets/skeleton.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<CategoriesProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategorije')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final catProvider = context.watch<CategoriesProvider>();
    final categories = catProvider.topCategories;
    final loading = catProvider.isLoading;
    final error = catProvider.error;

    if (loading && !catProvider.isLoaded) {
      return const CategoryGridSkeleton();
    }
    if (error != null) {
      return AppErrorRetry(
        message: 'Greška pri učitavanju',
        detail: error.toString(),
        onRetry: () => catProvider.refresh(),
      );
    }
    if (categories.isEmpty) {
      return const AppEmptyState(
        icon: Icons.category_outlined,
        title: 'Nema kategorija',
        subtitle: 'Kategorije će se pojaviti kada budu dodate.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => catProvider.refresh(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.9,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/categories/${cat.id}', extra: cat),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    buildCategoryIcon(cat.icon, size: 48, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      cat.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
