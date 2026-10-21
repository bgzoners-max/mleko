import 'package:flutter/material.dart';
import '../core/responsive.dart';

/// Centralizovani widget za odabir desktop vs mobile/layout child-a.
///
/// Korišćen kada ekran ima različite layout-e za desktop (>=1200px) i mobilne uređaje.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= Breakpoints.desktop) return desktop;
    if (width >= Breakpoints.phone) return tablet;
    return mobile;
  }
}

/// Scaffold sa ograničenom maksimalnom širinom i centriranim sadržajem na desktopu.
///
/// Na mobilnim uređajima prikazuje punu širinu ekrana. Na desktopu wrapuje
/// [child] u [ConstrainedBox] sa [Breakpoints.maxContentWidth] i centrira ga.
class DesktopScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const DesktopScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = Breakpoints.maxContentWidth(context);

    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      body: Breakpoints.isDesktop(context)
          ? Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            )
          : child,
    );
  }
}

/// Dvopanelni layout za data-heavy desktop ekrane (sidebar + glavni sadržaj).
///
/// Na desktopu prikazuje sidebar sa [sidebarWidth] i glavni sadržaj pored njega.
/// Na tablet/mobilu prikazuje samo [child] (sidebar se sakriva).
class TwoPaneLayout extends StatelessWidget {
  final Widget sidebar;
  final Widget child;
  final double sidebarWidth;

  const TwoPaneLayout({
    super.key,
    required this.sidebar,
    required this.child,
    this.sidebarWidth = 320,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: child,
      tablet: child,
      desktop: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: sidebarWidth, child: sidebar),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Pomoć za proveru da li trenutni kontekst zahteva desktop ponašanje (>= 1200px).
bool isDesktopWidth(BuildContext context) =>
    Breakpoints.isDesktop(context);
