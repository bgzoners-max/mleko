import 'package:flutter/material.dart';

import '../core/design_system.dart';
import '../core/responsive.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_footer.dart';
import '../widgets/seller_guide/seller_guide_hero_and_comparison.dart';
import '../widgets/seller_guide/seller_guide_steps_faq_cta.dart';

/// Javni vodič za proizvođače hrane: objašnjava razliku između Pijace
/// (prodaja domaće hrane) i Malih oglasa (besplatni oglasnik za sve
/// ostalo) i korak-po-korak proces postavljanja proizvoda na sajt.
class SellerGuideScreen extends StatelessWidget {
  const SellerGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Breakpoints.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AmazonColors.getCanvas(context),
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/'),
        title: const Text('Kako postaviti proizvode'),
        actions: const [
          AppHomeButton(),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: SelectionArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                Breakpoints.adaptiveDouble(
                  context,
                  phone: 16,
                  largeTabletValue: 24,
                  desktop: 28,
                ),
                horizontalPadding,
                Breakpoints.adaptiveDouble(
                  context,
                  phone: 32,
                  largeTabletValue: 44,
                  desktop: 52,
                ),
              ),
              child: const Column(
                children: [
                  _SellerGuideContent(),
                  SizedBox(height: 24),
                  AppFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SellerGuideContent extends StatelessWidget {
  const _SellerGuideContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SellerGuideHeroAndComparisonSection(),
        SizedBox(height: 28),
        SellerGuideStepsFaqAndCtaSection(),
      ],
    );
  }
}
