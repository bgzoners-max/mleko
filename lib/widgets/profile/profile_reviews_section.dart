import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../screens/buyer/buyer_reviews_hub_screen.dart';
import '../../screens/seller/seller_reviews_screen.dart';
import 'profile_market_section.dart'
    show ProfileOpenPanel, ProfileIsActiveSection;

/// SEKCIJA 3: Ocene i recenzije (zajednički ugled prodavca i kupca).
/// Izdvojeno iz `ProfileScreen._buildReviewsSection` bez izmena logike.
class ProfileReviewsSection extends StatelessWidget {
  const ProfileReviewsSection({
    super.key,
    required this.user,
    required this.isWide,
    required this.onOpenPanel,
    required this.isActiveSection,
  });

  final UserModel user;
  final bool isWide;
  final ProfileOpenPanel onOpenPanel;
  final ProfileIsActiveSection isActiveSection;
  static const headerColor = Colors.amber;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.star_outline_rounded,
                      size: 20, color: headerColor),
                  SizedBox(width: 8),
                  Text(
                    'OCENE I RECENZIJE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: headerColor,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 8, thickness: 0.8),
            if (user.isSeller)
              ListTile(
                visualDensity: VisualDensity.compact,
                leading: const Icon(Icons.rate_review_outlined),
                title: const Text('Recenzije kupaca',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle:
                    const Text('Utisci kupaca za proizvode i male oglase'),
                selected: isActiveSection('reviews', isWide),
                onTap: () => onOpenPanel(
                    'reviews', SellerReviewsScreen(sellerId: user.id),
                    isWide: isWide),
              ),
            ListTile(
              visualDensity: VisualDensity.compact,
              leading: const Icon(Icons.reviews_outlined),
              title: const Text('Moje date recenzije'),
              subtitle:
                  const Text('Utisci koje ste ostavili drugim prodavcima'),
              selected: isActiveSection('buyer-reviews', isWide),
              onTap: () => onOpenPanel(
                'buyer-reviews',
                BuyerReviewsHubScreen(buyerId: user.id),
                isWide: isWide,
                route: '/buyer/${user.id}/reviews',
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
