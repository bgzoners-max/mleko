import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../utils/animations.dart';

/// Prazno stanje – jasna poruka i opciono CTA dugme kada nema podataka za prikaz.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  /// Opciono CTA dugme (npr. "Pretraži proizvode", "Dodaj prvi proizvod").
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;
  final IconData? ctaIcon;

  /// Ako želiš custom widget umesto ctaLabel (npr. više dugmadi).
  final Widget? cta;

  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCtaPressed,
    this.ctaIcon,
    this.cta,
  }) : assert(cta == null || (ctaLabel == null && onCtaPressed == null),
            'Koristi ili cta ili (ctaLabel + onCtaPressed).');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Center(
      child: FadeInSlide(
        duration: const Duration(milliseconds: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium Icon Container
            Container(
              padding: const EdgeInsets.all(AppDesign.spaceL),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: AppDesign.spaceL),
            
            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Subtitle
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: AppDesign.spaceS),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            
            // Call to Action
            if (cta != null) ...[
              const SizedBox(height: AppDesign.spaceXL),
              cta!,
            ] else if (ctaLabel != null && onCtaPressed != null) ...[
              const SizedBox(height: AppDesign.spaceXL),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: onCtaPressed,
                  icon: Icon(ctaIcon ?? Icons.search, size: 20),
                  label: Text(
                    ctaLabel!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) {
          return Padding(
            padding: const EdgeInsets.all(AppDesign.spaceXL),
            child: content,
          );
        }

        final targetHeight = (constraints.maxHeight - AppDesign.spaceXL * 2).clamp(0.0, double.infinity);
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDesign.spaceXL),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: targetHeight),
            child: content,
          ),
        );
      },
    );
  }
}
