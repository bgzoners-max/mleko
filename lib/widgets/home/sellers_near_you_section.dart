import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/services.dart';
import '../skeleton.dart';

/// Sekcija â€žProdavci u tvom okruÅ¾enjuâ€ â€“ prikazuje prodavce u izabranom regionu.
class SellersNearYouSection extends StatelessWidget {
  final String region;

  const SellersNearYouSection({super.key, required this.region});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prodavci u tvom okruÅ¾enju',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<UserModel>>(
            future: context.read<ProductsService>().getSellersInRegion(region),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SellerAvatarRowSkeleton();
              }
              final sellers = snap.data ?? <UserModel>[];
              if (sellers.isEmpty) {
                return Text(
                  'Nema prodavaca sa proizvodima u $region.',
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
                    final subtitle = seller.location ?? seller.city ?? region;
                    return SizedBox(
                      width: 160,
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: seller.profileImageUrl != null
                                ? NetworkImage(seller.profileImageUrl!)
                                : null,
                            child: seller.profileImageUrl == null
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
