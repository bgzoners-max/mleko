import 'package:flutter/material.dart';
import '../core/responsive.dart';

/// Zajednički layout za pravne dokumente (Privacy, Terms, itd.)
class LegalDocumentLayout extends StatelessWidget {
  final String appBarTitle;
  final String? summaryHeader;
  final String? summaryText;
  final String pageTitle;
  final String effectiveDate;
  final List<Widget> children;

  const LegalDocumentLayout({
    super.key,
    required this.appBarTitle,
    this.summaryHeader,
    this.summaryText,
    required this.pageTitle,
    required this.effectiveDate,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final horizontalPadding = Breakpoints.horizontalPadding(context);
    final sectionSpacing = Breakpoints.adaptiveDouble(context,
        phone: 22, largeTabletValue: 28, desktop: 32);

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
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
                Breakpoints.adaptiveDouble(context,
                    phone: 16, largeTabletValue: 20, desktop: 24),
                horizontalPadding,
                Breakpoints.adaptiveDouble(context,
                    phone: 32, largeTabletValue: 40, desktop: 48),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (summaryHeader != null && summaryText != null) ...[
                    Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.all(Breakpoints.cardPadding(context) + 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(summaryHeader!,
                              style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary)),
                          const SizedBox(height: 10),
                          Text(summaryText!,
                              style: Breakpoints.supportingTextStyle(
                                  context, theme.textTheme.bodyMedium,
                                  phone: 15,
                                  largeTabletValue: 16,
                                  desktop: 16,
                                  height: 1.72,
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                  ],
                  Text(pageTitle,
                      style: Breakpoints.heroTitleStyle(
                              context, theme.textTheme.titleLarge)
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text('Datum stupanja na snagu: $effectiveDate',
                      style: Breakpoints.supportingTextStyle(
                          context, theme.textTheme.bodyMedium,
                          phone: 15,
                          largeTabletValue: 16,
                          desktop: 16,
                          height: 1.72,
                          color: theme.colorScheme.onSurfaceVariant)),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper za kreiranje stilizovanog teksta i sekcija unutar pravnih dokumenata
class LegalContentBuilder {
  final BuildContext context;
  late final TextStyle? body;
  late final TextStyle? heading;
  late final double sectionSpacing;
  late final double itemSpacing;

  LegalContentBuilder(this.context) {
    final theme = Theme.of(context);
    sectionSpacing = Breakpoints.adaptiveDouble(context,
        phone: 22, largeTabletValue: 28, desktop: 32);
    itemSpacing = Breakpoints.adaptiveDouble(context,
        phone: 6, largeTabletValue: 7, desktop: 8);
    body = Breakpoints.supportingTextStyle(context, theme.textTheme.bodyMedium,
        phone: 15,
        largeTabletValue: 16,
        desktop: 16,
        height: 1.72,
        color: theme.colorScheme.onSurfaceVariant);
    heading =
        Breakpoints.sectionTitleStyle(context, theme.textTheme.titleMedium)
            ?.copyWith(fontWeight: FontWeight.w700);
  }

  Widget section(String number, String title, List<String> items) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: sectionSpacing),
        Text('$number. $title', style: heading),
        const SizedBox(height: 10),
        ...items.map((item) => Padding(
            padding: EdgeInsets.only(bottom: itemSpacing),
            child: Text(item, style: body))),
      ]);

  Widget bullet(String text) => Padding(
      padding: EdgeInsets.only(left: 16, bottom: itemSpacing),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('• ', style: body),
        Expanded(child: Text(text, style: body))
      ]));
  Widget sectionBullets(String number, String title, List<String> bullets) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        Text('$number. $title', style: heading),
        const SizedBox(height: 8),
        ...bullets.map(bullet)
      ]);
  Widget text(String text) => Padding(
      padding: EdgeInsets.only(top: itemSpacing),
      child: Text(text, style: body));
}
