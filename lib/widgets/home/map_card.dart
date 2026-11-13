import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';

/// Kartica mape – kompaktno, tap otvara punu mapu sa podnožjem (footer)
class MapCard extends StatelessWidget {
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool fullWidth;

  const MapCard({
    super.key,
    this.maxWidth,
    this.padding,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final effectiveMaxWidth =
        fullWidth ? null : (maxWidth ?? (isDesktop ? 520.0 : null));
    final effectivePadding =
        padding ?? EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 16);

    final card = Padding(
      padding: effectivePadding,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/sellers-map'),
          borderRadius: BorderRadius.circular(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideBanner = constraints.maxWidth >= 540;
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isWideBanner ? 20 : 18,
                  vertical: isWideBanner ? 14 : 18,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF142419),
                      Color(0xFF245938),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF142419).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isWideBanner ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFD97724).withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        Icons.explore_outlined,
                        size: isWideBanner ? 24 : 28,
                        color: const Color(0xFFFBF8F2),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2.5),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97724)
                                  .withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFD97724)
                                    .withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'LOKALNA GAZDINSTVA',
                              style: TextStyle(
                                fontSize: 9.0,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFFD9A0),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const Text(
                            'Zavirite u komšiluk na mapi',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pronađite sveže domaće proizvode u vašoj blizini',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.white.withValues(alpha: 0.88),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isWideBanner)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Otvori mapu',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    if (effectiveMaxWidth != null) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: card,
        ),
      );
    }

    return card;
  }
}


