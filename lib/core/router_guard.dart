import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_state.dart';

final RegExp _invalidPercentEncodingRe = RegExp(r'%(?![0-9a-fA-F]{2})');

String _normalizePath(String path) {
  if (path.length > 1 && path.endsWith('/')) {
    return path.replaceAll(RegExp(r'/+$'), '');
  }
  return path.isEmpty ? '/' : path;
}

/// Validira i sanitizuje internu `returnTo` putanju (sprečava open-redirect,
/// dvostruko dekodiranje dijakritika i petlje ka `/splash`, `/login`, `/register`).
String? sanitizeReturnTo(String? rawReturnTo) {
  if (rawReturnTo == null || rawReturnTo.isEmpty) return null;
  final trimmed = rawReturnTo.trim();
  if (!trimmed.startsWith('/') ||
      trimmed.startsWith('//') ||
      trimmed.startsWith('/\\') ||
      _invalidPercentEncodingRe.hasMatch(trimmed)) {
    return null;
  }
  final parsed = Uri.tryParse(trimmed);
  if (parsed == null ||
      parsed.hasScheme ||
      parsed.hasAuthority ||
      parsed.host.isNotEmpty) {
    return null;
  }
  final normalized = _normalizePath(parsed.path);
  if (normalized == '/splash' ||
      normalized == '/login' ||
      normalized == '/register') {
    return null;
  }
  return trimmed;
}

/// Centralna zaštita i preusmeravanje ruta (Guest flow, Auth guards, Seller, Admin, Email potvrda).
String? routerRedirect(BuildContext context, GoRouterState state, AppState appState) {
  final loc = _normalizePath(state.uri.path);
  if (loc == '/splash') {
    if (!appState.authChecked || appState.isLoading) return null;
    return sanitizeReturnTo(state.uri.queryParameters['returnTo']);
  }
  if (loc.startsWith('/onboarding')) return null;
  if (loc == '/verify-email') return null;
  if (loc == '/terms' ||
      loc == '/uslovi-koriscenja' ||
      loc == '/politika-privatnosti') {
    return null;
  }
  if (loc == '/about') return null;
  if (loc == '/vodic-za-proizvodjace') return null;
  if (loc == '/support') return null;

  // Email just confirmed — steer to success screen before anything else
  if (appState.justConfirmedEmail && loc != '/auth/confirmed') {
    return '/auth/confirmed';
  }
  if (loc == '/auth/confirmed') return null;

  // Javne rute koje posetilac bez naloga (gost) može slobodno da pregleda
  final isPublicClassifiedRoute = loc.startsWith('/classifieds') &&
      !loc.startsWith('/classifieds/new') &&
      !loc.startsWith('/classifieds/edit') &&
      !loc.startsWith('/classifieds/my') &&
      !loc.startsWith('/classifieds/saved-searches');

  final isPublicProductRoute =
      loc.startsWith('/product/') &&
      loc != '/product/edit' &&
      !loc.startsWith('/product/edit/');

  final isPublicRoute = loc == '/' ||
      loc.startsWith('/search') ||
      isPublicProductRoute ||
      loc.startsWith('/p/') ||
      loc.startsWith('/ad/') ||
      loc.startsWith('/categories') ||
      loc == '/sellers-map' ||
      loc == '/cart' ||
      loc == '/settings' ||
      loc.startsWith('/auth/confirm') ||
      isPublicClassifiedRoute ||
      (loc.startsWith('/seller/') && !loc.endsWith('/reviews'));

  if (isPublicRoute) {
    return null;
  }

  if (loc.startsWith('/login') || loc.startsWith('/register')) {
    if (appState.user != null && !appState.user!.isGuest) {
      return sanitizeReturnTo(state.uri.queryParameters['returnTo']) ?? '/';
    }
    return null;
  }

  // Zaštićena ruta: ako sesija još nije proverena ili je u toku loading,
  // ne dozvoljavamo fleš zaštićenog ekrana, već privremeno preusmeravamo na splash sa returnTo.
  if (!appState.authChecked || appState.isLoading) {
    final returnTo = Uri.encodeComponent(state.uri.toString());
    return '/splash?returnTo=$returnTo';
  }

  // Sve ostale rute (profil, porudžbine, dodavanje oglasa itd.) zahtevaju prijavu
  final isGuest = appState.user == null || appState.user!.isGuest;
  if (isGuest) {
    final returnTo = Uri.encodeComponent(state.uri.toString());
    return '/login?returnTo=$returnTo';
  }

  // Admin stranice — samo korisnici sa is_admin = true
  if (loc == '/admin' || loc.startsWith('/admin/')) {
    final u = appState.user;
    if (u == null || !u.isAdmin) return '/';
  }

  // Prodavačke rute — samo registrovani prodavci
  final isSellerOnlyRoute = loc == '/add-product' ||
      loc == '/product/edit' ||
      loc.startsWith('/product/edit/') ||
      loc == '/seller-dashboard' ||
      loc == '/seller-settings';
  if (isSellerOnlyRoute) {
    final u = appState.user;
    if (u == null || u.isGuest || !u.isSeller) return '/';
  }

  // Stranica recenzija — samo vlasnik prodavnice (kupci i gosti na javni profil).
  final sellerReviewsMatch =
      RegExp(r'^/seller/([^/]+)/reviews$').firstMatch(loc);
  if (sellerReviewsMatch != null) {
    final sid = sellerReviewsMatch.group(1)!;
    final u = appState.user;
    if (u == null || u.isGuest || !u.isSeller || u.id != sid) {
      return '/seller/$sid';
    }
  }

  final buyerReviewsMatch =
      RegExp(r'^/buyer/([^/]+)/reviews$').firstMatch(loc);
  if (buyerReviewsMatch != null) {
    final bid = buyerReviewsMatch.group(1)!;
    final u = appState.user;
    if (u == null || u.isGuest || u.isSeller || u.id != bid) {
      return '/buyer/$bid';
    }
  }

  return null;
}
