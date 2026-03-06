import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/category.dart';
import '../services/supabase_service.dart';
import '../widgets/category_icon.dart';

class ChildCategoriesScreen extends StatefulWidget {
  const ChildCategoriesScreen({
    super.key,
    required this.parentCategory,
  });

  final Category parentCategory;

  @override
  State<ChildCategoriesScreen> createState() => _ChildCategoriesScreenState();
}

class _ChildCategoriesScreenState extends State<ChildCategoriesScreen> {
  final _service = SupabaseService();
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.getChildCategories(widget.parentCategory.id);
      if (mounted) {
        setState(() {
          _categories = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parentCategory.name),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Greška pri učitavanju',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadCategories,
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      );
    }
    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nema podkategorija',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Ovaj odeljak nema još potkategorija.',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.9,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.go('/search?category=${Uri.encodeComponent(cat.name)}'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
