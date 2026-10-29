import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_state.dart';

/// Centralna zaštita i preusmeravanje ruta (Guest flow, Auth guards, Admin, Email potvrda).
String? routerRedirect(BuildContext context, GoRouterState state, AppState appState) {
  final loc = state.uri.path;
  if (loc == '/splash') {
    if (!appState.authChecked || appState.isLoading) return null;
    final rawReturnTo = state.uri.queryParameters['returnTo'];
    if (rawReturnTo != null && rawReturnTo.isNotEmpty) {
      final decoded = Uri.decodeComponent(rawReturnTo);
      final decodedUri = Uri.tryParse(decoded);
      if (decodedUri != null && decodedUri.path != '/splash') {
        return decoded;
      }
    }
    return null;
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

  final isPublicRoute = loc == '/' ||
      loc.startsWith('/search') ||
      loc.startsWith('/product/') ||
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
    if (appState.user != null && !appState.user!.isGuest) return '/';
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
  if (loc.startsWith('/admin/')) {
    final u = appState.user;
    if (u == null || !u.isAdmin) return '/';
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
