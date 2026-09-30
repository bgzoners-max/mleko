import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/app_state.dart';
import '../../services/core/logger_service.dart';

Future<void> enterAsGuestWithMode(BuildContext context, MarketMode mode) async {
  final appState = context.read<AppState>();
  unawaited(context.read<AppSettingsProvider>().setMarketMode(mode));
  await appState.authService.ensureCleanSession();
  if (context.mounted) {
    try {
      context.go('/');
    } catch (e) {
      LoggerService.warning('Navigation to / failed in enterAsGuestWithMode', extra: {'error': e.toString()});
    }
  }
}
