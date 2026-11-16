import 'dart:io';

/// Proverava da je svaka ruta iz `lib/core/router.dart` eksplicitno pokrivena
/// u `functions/_middleware.ts`, `static-seo-pages.ts` ili `preview-utils.ts`.
///
/// Sprečava tihi SEO drift kada se u aplikaciju doda nova ruta, a botovi je
/// pogrešno tretiraju kao 404 ili javno indeksibilnu stranicu.
void main() {
  final routerFile = File('lib/core/router.dart');
  final middlewareFile = File('functions/_middleware.ts');
  final staticSeoFile = File('functions/api/_shared/static-seo-pages.ts');
  final previewUtilsFile = File('functions/api/_shared/preview-utils.ts');

  for (final file in [
    routerFile,
    middlewareFile,
    staticSeoFile,
    previewUtilsFile,
  ]) {
    if (!file.existsSync()) {
      stderr.writeln('ERROR: Nedostaje fajl ${file.path}.');
      exitCode = 2;
      return;
    }
  }

  final routerRoutes = _extractGoRouterPaths(routerFile.readAsStringSync());
  final middleware = _parseMiddlewareMatchers(middlewareFile.readAsStringSync());
  final publicStaticRoutes =
      _extractPublicSeoRoutes(staticSeoFile.readAsStringSync());
  final previewAndLegacyRoutes =
      _extractPreviewAndLegacyRoutes(previewUtilsFile.readAsStringSync());

  final uncovered = <String>[];
  for (final route in routerRoutes) {
    if (_matchesAnyKnownHandler(
      route: route,
      middleware: middleware,
      publicStaticRoutes: publicStaticRoutes,
      previewAndLegacyRoutes: previewAndLegacyRoutes,
    )) {
      continue;
    }
    uncovered.add(route);
  }

  final staleExactPrivate = <String>[];
  for (final exactPrivate in middleware.exactPrivate) {
    if (!routerRoutes.contains(exactPrivate)) {
      staleExactPrivate.add(exactPrivate);
    }
  }

  if (uncovered.isEmpty && staleExactPrivate.isEmpty) {
    stdout.writeln(
      'OK: Svih ${routerRoutes.length} ruta iz router.dart su usklađene sa Cloudflare middleware-om.',
    );
    return;
  }

  if (uncovered.isNotEmpty) {
    stderr.writeln(
      'ERROR: Sledeće rute iz lib/core/router.dart nisu pokrivene u functions/_middleware.ts ni static-seo-pages.ts:',
    );
    for (final r in uncovered) {
      stderr.writeln(' - $r');
    }
  }

  if (staleExactPrivate.isNotEmpty) {
    stderr.writeln(
      'ERROR: Sledeće tačne rute u isPrivateOrDynamicSpaRoute (functions/_middleware.ts) više ne postoje u router.dart:',
    );
    for (final r in staleExactPrivate) {
      stderr.writeln(' - $r');
    }
  }

  exitCode = 1;
}

List<String> _extractGoRouterPaths(String source) {
  final matches = RegExp(r"GoRoute\(\s*path:\s*'([^']+)'").allMatches(source);
  final seen = <String>{};
  final routes = <String>[];
  for (final m in matches) {
    final path = m.group(1)!.trim();
    if (seen.add(path)) {
      routes.add(path);
    }
  }
  return routes;
}

({
  Set<String> exactPrivate,
  List<String> prefixPrivate,
  Set<String> staticHtml,
  bool hasSellerPreview,
}) _parseMiddlewareMatchers(String source) {
  final privateBlockMatch = RegExp(
    r'const\s+isPrivateOrDynamicSpaRoute\s*=([\s\S]*?);',
  ).firstMatch(source);
  final privateBlock = privateBlockMatch?.group(1) ?? '';

  final exactPrivate = RegExp(r'normalizedBotPath\s*===\s*"([^"]+)"')
      .allMatches(privateBlock)
      .map((m) => m.group(1)!)
      .toSet();
  final prefixPrivate = RegExp(r'normalizedBotPath\.startsWith\("([^"]+)"\)')
      .allMatches(privateBlock)
      .map((m) => m.group(1)!)
      .toList();

  final staticBlockMatch = RegExp(
    r'const\s+isKnownStaticOrHtmlRoute\s*=([\s\S]*?);',
  ).firstMatch(source);
  final staticBlock = staticBlockMatch?.group(1) ?? '';
  final staticHtml = RegExp(r'normalizedBotPath\s*===\s*"([^"]+)"')
      .allMatches(staticBlock)
      .map((m) => m.group(1)!)
      .toSet();

  final hasSellerPreview = source.contains(r'\/seller\/([^/]+)');

  return (
    exactPrivate: exactPrivate,
    prefixPrivate: prefixPrivate,
    staticHtml: staticHtml,
    hasSellerPreview: hasSellerPreview,
  );
}

Set<String> _extractPublicSeoRoutes(String source) {
  final routes = <String>{};
  final baseMatch = RegExp(
    r'const\s+BASE_ROUTES:\s*Record<string,\s*RouteSeo>\s*=\s*\{([\s\S]*?)\n\};',
  ).firstMatch(source);
  final baseBlock = baseMatch?.group(1) ?? '';
  for (final m in RegExp(r'^\s*"(/[^"]*)":\s*\{', multiLine: true)
      .allMatches(baseBlock)) {
    routes.add(m.group(1)!);
  }
  if (source.contains('path === "/support"')) {
    routes.add('/support');
  }
  if (source.contains(r'${BASE_URL_PATH_CATEGORIES}/')) {
    routes.add('/categories/:parentId');
  }
  return routes;
}

Set<String> _extractPreviewAndLegacyRoutes(String source) {
  final routes = <String>{};
  for (final m in RegExp(r'requestUrl\.pathname\s*===\s*"(/[^"/]+)"')
      .allMatches(source)) {
    routes.add(m.group(1)!);
  }
  if (source.contains(r'\/ad\/([^/]+)')) routes.add('/ad/:id');
  if (source.contains(r'\/p\/([^/]+)')) routes.add('/p/:id');
  if (source.contains(r'\/classifieds\/ad\/([^/]+)')) {
    routes.add('/classifieds/ad/:id');
  }
  if (source.contains(r'\/product\/([^/]+)')) routes.add('/product/:id');
  return routes;
}

bool _matchesAnyKnownHandler({
  required String route,
  required ({
    Set<String> exactPrivate,
    List<String> prefixPrivate,
    Set<String> staticHtml,
    bool hasSellerPreview,
  }) middleware,
  required Set<String> publicStaticRoutes,
  required Set<String> previewAndLegacyRoutes,
}) {
  if (publicStaticRoutes.contains(route) ||
      middleware.staticHtml.contains(route) ||
      previewAndLegacyRoutes.contains(route) ||
      middleware.exactPrivate.contains(route)) {
    return true;
  }

  // Kanonski /seller/:sellerId je pokriven sa sellerMatch u _middleware.ts
  if (middleware.hasSellerPreview &&
      RegExp(r'^/seller/:[^/]+$').hasMatch(route)) {
    return true;
  }

  // Parametarske segmente zamenimo bezbednim placeholder-om za startsWith proveru
  final normalizedSample = route.replaceAll(RegExp(r':[^/]+'), 'sample');
  for (final prefix in middleware.prefixPrivate) {
    if (normalizedSample.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}
