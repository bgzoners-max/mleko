import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/app_state.dart';
import '../services/favorite_sellers_service.dart';
import '../widgets/app_error_retry.dart';

class FavoriteSellersScreen extends StatefulWidget {
  const FavoriteSellersScreen({super.key});

  @override
  State<FavoriteSellersScreen> createState() => _FavoriteSellersScreenState();
}

class _FavoriteSellersScreenState extends State<FavoriteSellersScreen> {
  final _service = FavoriteSellersService();
  Future<List<UserModel>>? _sellersFuture;
  String? _lastUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AppState>().user;
    if (user != null && !user.isGuest && user.id != _lastUserId) {
      _lastUserId = user.id;
      _sellersFuture = _service.getFavoriteSellersWithProfiles(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pratim prodavce')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('Prijavite se da pratite prodavce', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pratim prodavce')),
      body: FutureBuilder<List<UserModel>>(
        future: _sellersFuture,
        builder: (context, snap) {
          if (snap.hasError) {
            return AppErrorRetry(
              message: 'Greška pri učitavanju prodavaca.',
              detail: snap.error?.toString(),
              onRetry: () => setState(() => _sellersFuture = _service.getFavoriteSellersWithProfiles(user.id)),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Ne pratite nijedno gazdinstvo', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Kliknite "Pratim" na profilu prodavca', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final seller = list[i];
              final title = seller.farmName ?? seller.displayName ?? 'Gazdinstvo';
              final subtitle = seller.location ?? seller.city;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: seller.profileImageUrl != null
                        ? NetworkImage(seller.profileImageUrl!)
                        : null,
                    child: seller.profileImageUrl == null
                        ? Icon(Icons.store, color: Colors.grey.shade700)
                        : null,
                  ),
                  title: Text(title),
                  subtitle: subtitle != null
                      ? Text(subtitle, style: TextStyle(color: Colors.grey.shade700))
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/seller/${seller.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
