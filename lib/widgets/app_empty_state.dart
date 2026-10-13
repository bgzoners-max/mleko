import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../utils/animations.dart';
import 'rustic_illustration.dart';

/// Prazno stanje – jasna poruka i opciono CTA dugme kada nema podataka za prikaz.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  /// Opcioni rustic motiv (ilustracija) — ako je zadat, prikazuje se umesto
  /// generičke Material ikonice u kružnoj podlozi.
  final RusticMotif? motif;

  /// Opciono CTA dugme (npr. "Pretraži proizvode", "Dodaj prvi proizvod").
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;
  final IconData? ctaIcon;

  /// Ako želiš custom widget umesto ctaLabel (npr. više dugmadi).
  final Widget? cta;

  /// Kompaktni prikaz za kartice i bočne panele manjih dimenzija.
  /// Ako je null, automatski se aktivira kompaktni mod kada je visina <= 290 px.
  final bool? isCompact;

  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.motif,
    this.ctaLabel,
    this.onCtaPressed,
    this.ctaIcon,
    this.cta,
    this.isCompact,
  }) : assert(cta == null || (ctaLabel == null && onCtaPressed == null),
            'Koristi ili cta ili (ctaLabel + onCtaPressed).');

  Widget _buildContent(BuildContext context, bool compact) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final iconWidget = motif != null
        ? RusticIllustration(motif: motif!, size: compact ? 64 : 132)
        : Container(
            padding: EdgeInsets.all(compact ? 10 : AppDesign.spaceL),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: compact ? 36 : 64,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
          );

    final titleWidget = Text(
      title,
      style: compact
          ? theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
            )
          : theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
      textAlign: TextAlign.center,
      maxLines: compact ? 2 : null,
      overflow: compact ? TextOverflow.ellipsis : null,
    );

    Widget? subtitleWidget;
    if (subtitle != null && subtitle!.isNotEmpty) {
      subtitleWidget = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 260 : 280),
        child: Text(
          subtitle!,
          style: compact
              ? theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.3,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
          textAlign: TextAlign.center,
          maxLines: compact ? 2 : null,
          overflow: compact ? TextOverflow.ellipsis : null,
        ),
      );
    }

    Widget? ctaWidget;
    if (cta != null) {
      ctaWidget = cta!;
    } else if (ctaLabel != null && onCtaPressed != null) {
      ctaWidget = SizedBox(
        height: compact ? 34 : 48,
        child: FilledButton.icon(
          onPressed: onCtaPressed,
          style: compact
              ? FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
          icon: Icon(ctaIcon ?? Icons.search, size: compact ? 16 : 20),
          label: Text(
            ctaLabel!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: compact ? 12.5 : null,
            ),
          ),
        ),
      );
    }

    return FadeInSlide(
      duration: const Duration(milliseconds: 600),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          SizedBox(height: compact ? 8 : AppDesign.spaceL),
          titleWidget,
          if (subtitleWidget != null) ...[
            SizedBox(height: compact ? 4 : AppDesign.spaceS),
            subtitleWidget,
          ],
          if (ctaWidget != null) ...[
            SizedBox(height: compact ? 10 : AppDesign.spaceXL),
            ctaWidget,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = isCompact ??
            (constraints.hasBoundedHeight && constraints.maxHeight <= 290);
        final content = _buildContent(context, compact);

        final verticalPadding = compact ? AppDesign.spaceS : AppDesign.spaceXL;
        final horizontalPadding = compact ? AppDesign.spaceM : AppDesign.spaceXL;
        final padding = EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        );

        if (!constraints.hasBoundedHeight) {
          return Center(
            child: Padding(
              padding: padding,
              child: content,
            ),
          );
        }

        final targetHeight = (constraints.maxHeight - verticalPadding * 2)
            .clamp(0.0, double.infinity);
        return Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: targetHeight),
              child: content,
            ),
          ),
        );
      },
    );
  }
}
