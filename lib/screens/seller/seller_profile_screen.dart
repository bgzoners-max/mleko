import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mleko/services/services.dart';

import '../../core/web_seo.dart';
import '../../models/user_model.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/seller_profile/seller_profile_content.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;

  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  Future<UserModel?>? _userFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userFuture ??= context.read<UsersService>().getUser(widget.sellerId);
  }

  void _retry() => setState(() {
        _userFuture = context.read<UsersService>().getUser(widget.sellerId);
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, userSnap) {
        if (userSnap.hasError) {
          return Scaffold(
            appBar: AppBar(
              leading: const AppBackButton(fallbackRoute: '/'),
              title: const Text('Prodajni profil'),
              actions: const [AppHomeButton()],
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Greška pri učitavanju profila.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userSnap.error.toString(),
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('Pokušaj ponovo'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (!userSnap.hasData) {
          return Scaffold(
            appBar: AppBar(
              leading: const AppBackButton(fallbackRoute: '/'),
              title: const Text('Prodajni profil'),
              actions: const [AppHomeButton()],
            ),
            body: const BuyerProfileSkeleton(),
          );
        }
        final seller = userSnap.data;
        if (seller == null || !seller.isSeller) {
          return Scaffold(
            appBar: AppBar(
              leading: const AppBackButton(fallbackRoute: '/'),
              title: const Text('Prodajni profil'),
              actions: const [AppHomeButton()],
            ),
            body: const Center(child: Text('Prodavac nije pronađen.')),
          );
        }
        setSellerSeo(
          id: seller.id,
          name: seller.farmName ?? seller.displayName ?? 'Domaći Proizvođač',
          city: seller.city,
          avatarUrl: seller.profileImageUrl,
          bio: seller.sellerStory,
        );
        return SellerProfileContent(seller: seller);
      },
    );
  }
}
