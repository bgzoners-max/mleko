import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/amazon_theme.dart';
import '../../models/user_model.dart';
import '../../services/services.dart';

class ProductSellerBanner extends StatefulWidget {
  final String sellerId;

  const ProductSellerBanner({super.key, required this.sellerId});

  @override
  State<ProductSellerBanner> createState() => _ProductSellerBannerState();
}

class _ProductSellerBannerState extends State<ProductSellerBanner> {
  Future<UserModel?>? _sellerFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sellerFuture ??= context.read<UsersService>().getUser(widget.sellerId);
  }

  @override
  void didUpdateWidget(covariant ProductSellerBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sellerId != widget.sellerId) {
      _sellerFuture = context.read<UsersService>().getUser(widget.sellerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _sellerFuture,
      builder: (context, snap) {
        final seller = snap.data;
        final name = seller?.farmName ?? seller?.displayName ?? '';
        if (name.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: InkWell(
                onTap: () => context.push('/seller/${widget.sellerId}'),
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: [
                    const Icon(Icons.store_outlined,
                        size: 16, color: AmazonColors.link),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: const TextStyle(
                        color: AmazonColors.link,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        size: 16, color: AmazonColors.link),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
