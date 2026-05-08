import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../services/services.dart';
import '../skeleton.dart';
import '../app_network_image.dart';

/// Lista gazdinstava koje kupac prati (isti podatak kao ekran â€žPratim prodavceâ€œ).
class FavoriteFarmsList extends StatefulWidget {
  final TabController? tabController;

  const FavoriteFarmsList({super.key, this.tabController});

  @override
  State<FavoriteFarmsList> createState() => _FavoriteFarmsListState();
}

class _FavoriteFarmsListState extends State<FavoriteFarmsList> {
  final FavoriteSellersService _service = FavoriteSellersService();
  Future<List<UserModel>>? _future;
  String? _loadedForUserId;
  int _prevTabIndex = 0;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    widget.tabController?.addListener(_onTabChanged);
    _subscribeToFavoriteSellersChanges();
  }

  @override
  void dispose() {
    widget.tabController?.removeListener(_onTabChanged);
    _channel?.unsubscribe();
    _channel = null;
    super.dispose();
  }

  void _subscribeToFavoriteSellersChanges() {
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) return;

    _channel = Supabase.instance.client
        .channel('favorite_sellers:user_id=eq.${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'favorite_sellers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            _refreshForCurrentUser();
          },
        )
        .subscribe();
  }

  void _onTabChanged() {
    if (widget.tabController?.indexIsChanging ?? true) return;
    final idx = widget.tabController?.index ?? 0;
    if (idx == 1 && _prevTabIndex != 1) {
      _refreshForCurrentUser();
    }
    _prevTabIndex = idx;
  }

  void _refreshForCurrentUser() {
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) return;
    setState(() {
      _future = _service.getFavoriteSellersWithProfiles(user.id);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) {
      if (_loadedForUserId != null) {
        _channel?.unsubscribe();
        _channel = null;
        setState(() {
          _loadedForUserId = null;
          _future = null;
        });
      }
      return;
    }
    if (_loadedForUserId != user.id) {
      _channel?.unsubscribe();
      _subscribeToFavoriteSellersChanges();
      setState(() {
        _loadedForUserId = user.id;
        _future = _service.getFavoriteSellersWithProfiles(user.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AppState, UserModel?>((s) => s.user);
    if (user == null || user.isGuest) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'Prijavite se da vidite gazdinstva koja pratite.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              TextButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Prijavi se')),
            ],
          ),
        ),
      );
    }

    final future = _future;
    if (future == null) return const SellerProductListSkeleton(itemCount: 3);

    return FutureBuilder<List<UserModel>>(
      future: future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('GreÅ¡ka pri uÄitavanju.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.red),
                      textAlign: TextAlign.center),
                  TextButton(
                      onPressed: _refreshForCurrentUser,
                      child: const Text('PokuÅ¡aj ponovo')),
                ],
              ),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const SellerProductListSkeleton(itemCount: 3);
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('JoÅ¡ ne pratite nijedno gazdinstvo.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                  TextButton(
                      onPressed: () => context.push('/search'),
                      child: const Text('PretraÅ¾i proizvode')),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final seller = list[i];
                  final title =
                      seller.farmName ?? seller.displayName ?? 'Gazdinstvo';
                  final subtitle = seller.location ?? seller.city;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onTap: () => context.push('/seller/${seller.id}'),
                    leading: seller.profileImageUrl != null
                        ? ClipOval(
                            child: AppNetworkImage.profileSmall(
                                imageUrl: seller.profileImageUrl!,
                                width: 40,
                                height: 40))
                        : CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey.shade300,
                            child: Icon(Icons.store,
                                size: 20, color: Colors.grey.shade700)),
                    title: Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: subtitle != null
                        ? Text(subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700))
                        : null,
                    trailing: const Icon(Icons.chevron_right, size: 20),
                  );
                },
              ),
            ),
            TextButton(
                onPressed: () => context.push('/favorite-sellers'),
                child: const Text('Sva omiljena gazdinstva')),
          ],
        );
      },
    );
  }
}
