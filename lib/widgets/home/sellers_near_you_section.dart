import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/services.dart';
import '../skeleton.dart';

/// Sekcija „Prodavci u tvom okruženju“ – prikazuje prodavce u izabranom regionu.
class SellersNearYouSection extends StatefulWidget {
  final String region;
  final EdgeInsetsGeometry padding;

  const SellersNearYouSection({
    super.key,
    required this.region,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  State<SellersNearYouSection> createState() => _SellersNearYouSectionState();
}

class _SellersNearYouSectionState extends State<SellersNearYouSection> {
  Future<List<UserModel>>? _sellersFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sellersFuture ??=
        context.read<ProductsService>().getSellersInRegion(widget.region);
  }

  @override
  void didUpdateWidget(covariant SellersNearYouSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.region != widget.region) {
      _sellersFuture =
          context.read<ProductsService>().getSellersInRegion(widget.region);
    }
  }

  void _retry() {
    setState(() {
      _sellersFuture =
          context.read<ProductsService>().getSellersInRegion(widget.region);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prodavci u tvom okruženju',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<UserModel>>(
            future: _sellersFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SellerAvatarRowSkeleton();
              }
              if (snap.hasError) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Nije moguće učitati prodavce u okruženju.',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _retry,
                      child: const Text('Pokušaj ponovo'),
                    ),
                  ],
                );
              }
              final sellers = snap.data ?? <UserModel>[];
              if (sellers.isEmpty) {
                return Text(
                  'Nema prodavaca sa proizvodima u ${widget.region}.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                );
              }
              return SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sellers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final seller = sellers[i];
                    final name =
                        seller.farmName ?? seller.displayName ?? 'Prodavac';
                    final subtitle =
                        seller.location ?? seller.city ?? widget.region;
                    final avatarUrl = seller.profileImageUrl;
                    return SizedBox(
                      width: 160,
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: avatarUrl != null &&
                                    avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            onBackgroundImageError: avatarUrl != null &&
                                    avatarUrl.isNotEmpty
                                ? (_, __) {}
                                : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Icon(Icons.store, color: Colors.grey.shade700)
                                : null,
                          ),
                          title: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                          subtitle: Text(subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600)),
                          onTap: () => context.push('/seller/${seller.id}'),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
