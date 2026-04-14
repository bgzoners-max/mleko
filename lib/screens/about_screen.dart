import 'package:flutter/material.dart';
import 'package:mleko/core/responsive.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Breakpoints.horizontalPadding(context);
    return Scaffold(
      appBar: AppBar(title: const Text('O platformi')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
                Breakpoints.isTabletOrLarger(context) ? 720 : double.infinity,
          ),
          child: SelectionArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                Breakpoints.adaptiveDouble(
                  context,
                  phone: 16,
                  largeTabletValue: 20,
                  desktop: 24,
                ),
                horizontalPadding,
                Breakpoints.adaptiveDouble(
                  context,
                  phone: 32,
                  largeTabletValue: 40,
                  desktop: 48,
                ),
              ),
              child: const _AboutContent(),
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
    final theme = Theme.of(context);
    final sectionSpacing = Breakpoints.adaptiveDouble(
      context,
      phone: 28,
      largeTabletValue: 32,
      desktop: 36,
    );
    final heading = Breakpoints.heroTitleStyle(
      context,
      theme.textTheme.headlineSmall,
    )?.copyWith(fontWeight: FontWeight.w800);
    final subheading = Breakpoints.sectionTitleStyle(
      context,
      theme.textTheme.titleMedium,
    )?.copyWith(
      fontWeight: FontWeight.w700,
      color: const Color(0xFF1B5E20),
    );
    final lead = Breakpoints.supportingTextStyle(
      context,
      theme.textTheme.titleMedium,
      phone: 17,
      largeTabletValue: 18,
      desktop: 19,
      height: 1.6,
      color: theme.colorScheme.onSurface,
    );
    final body = Breakpoints.supportingTextStyle(
      context,
      theme.textTheme.bodyLarge,
      phone: 16,
      largeTabletValue: 17,
      desktop: 17,
      height: 1.75,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(Breakpoints.cardPadding(context) + 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Direktno od domaćina do kupca',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF1B5E20),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 12),
              Text('Naša vizija', style: heading),
              const SizedBox(height: 14),
              Text(
                'Domaći market je platforma koja povezuje kupce sa domaćim proizvođačima i lokalnom ponudom, bez posrednika i bez gubljenja porekla proizvoda.',
                style: lead,
              ),
            ],
          ),
        ),
        SizedBox(height: sectionSpacing),
        Text('Naša vizija', style: heading),
        const SizedBox(height: 16),
        Text(
          'Gradimo mesto gde kupac može jasno da vidi ko stoji iza proizvoda, a proizvođač da dobije direktan kanal do ljudi koji cene kvalitet, poreklo i transparentnu kupovinu.',
          style: body,
        ),
        SizedBox(height: sectionSpacing),
        Text('Zašto Domaći market?', style: subheading),
        const SizedBox(height: 12),
        Text(
          'Verujemo da svako ima pravo da zna od koga kupuje i šta unosi u svoj dom. Malim proizvođačima u Srbiji nedostaje direktan kanal ka kupcima, a kupcima pregledna i pouzdana lokalna ponuda. Mi spajamo te dve strane.',
          style: body,
        ),
        SizedBox(height: sectionSpacing),
        Text('Šta gradimo?', style: subheading),
        const SizedBox(height: 12),
        Text(
          'Digitalni marketplace domaćih proizvoda gde svaki proizvođač ima svoju stranicu, svoju priču i direktnu komunikaciju sa kupcima. Platforma je u razvoju, a cilj je jasna, lokalna i pouzdana kupovina.',
          style: body,
        ),
        SizedBox(height: sectionSpacing),
        Text('Tim', style: subheading),
        const SizedBox(height: 12),
        Text(
          'Mala ekipa sa velikom idejom. Više detalja uskoro.',
          style: body,
        ),
        SizedBox(height: sectionSpacing + 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(Breakpoints.cardPadding(context)),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.eco_outlined,
                  color: Color(0xFF1B5E20),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Platforma je trenutno u fazi razvoja. Prijavite se na waitlistu i bićete među prvima obavešteni kada krenemo.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1B5E20),
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
