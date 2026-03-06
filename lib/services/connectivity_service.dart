import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'logger_service.dart';

/// Prati internet konekciju - pomaže da znamo da li je app online/offline
class ConnectivityService extends ChangeNotifier {
  final _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  ConnectivityService() {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectivity(result);

      // Listen to connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        (result) => _updateConnectivity(result),
      );
    } catch (e, st) {
      LoggerService.error('Failed to initialize connectivity', e,
          stackTrace: st);
    }
  }

  void _updateConnectivity(dynamic result) {
    final newIsOnline = switch (result) {
      List<ConnectivityResult> results =>
        !results.contains(ConnectivityResult.none),
      ConnectivityResult r => r != ConnectivityResult.none,
      _ => true,
    };

    if (newIsOnline != _isOnline) {
      _isOnline = newIsOnline;
      LoggerService.info(
          'Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
