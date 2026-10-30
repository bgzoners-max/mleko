import 'package:flutter/material.dart';

import '../core/design_system.dart';
import '../core/responsive.dart';
import '../widgets/about/about_hero_mission_section.dart';
import '../widgets/about/about_pillars_section.dart';
import '../widgets/about/about_values_and_cta_section.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_footer.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Breakpoints.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AmazonColors.getCanvas(context),
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/'),
        title: const Text('O platformi'),
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
                  _AboutContent(),
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

class _AboutContent extends StatelessWidget {
  const _AboutContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AboutHeroAndMissionSection(),
        SizedBox(height: 28),
        AboutPillarsSection(),
        SizedBox(height: 28),
        AboutValuesAndCtaSection(),
      ],
    );
  }
}
