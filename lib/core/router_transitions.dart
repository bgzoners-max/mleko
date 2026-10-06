import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'web_seo.dart';

/// Pomoćna funkcija za premium tranzicije između ekrana i ažuriranje SEO metapodataka.
///
/// Poštuje sistemsko smanjenje animacija (pristupačnost): kada je na uređaju
/// uključeno "Remove animations" / "Reduce motion", vraća običnu stranicu
/// bez Fade+Slide+Scale tranzicije.
Page<T> buildPageTransition<T>({
  required GoRouterState state,
  required Widget child,
}) {
  applyRouteSeo(state.uri.path);
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return child;
      }
      // Suptilna "Shared Axis" tranzicija (Fade + Slide + Scale)
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );

      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.03), // Blagi pomak odozdo
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      final scaleAnimation = Tween<double>(
        begin: 0.98, // Blago skaliranje
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
