import 'dart:async';
import 'dart:io' show InternetAddress, SocketException;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../core/web_seo.dart' show isWebOnline;
import 'logger_service.dart';

/// Prati internet konekciju - proverava status interfejsa, stvarnu dostupnost (reachability)
/// i reaguje na autoritativne operativne mrežne greške.
class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity;
  final Future<bool> Function()? _customReachabilityChecker;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline;
  bool _isCheckingReachability = false;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  ConnectivityService({
    Connectivity? connectivity,
    Future<bool> Function()? reachabilityChecker,
    bool initialOnline = false,
  })  : _connectivity = connectivity ?? Connectivity(),
        _customReachabilityChecker = reachabilityChecker,
        _isOnline = initialOnline {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      await _updateConnectivity(result);

      // Listen to connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        (result) => _updateConnectivity(result),
      );
    } catch (e, st) {
      LoggerService.error('Failed to initialize connectivity', e,
          stackTrace: st);
    }
  }

  Future<void> _updateConnectivity(dynamic result) async {
    final hasInterface = switch (result) {
      final List<ConnectivityResult> results =>
        !results.contains(ConnectivityResult.none) && results.isNotEmpty,
      final ConnectivityResult r => r != ConnectivityResult.none,
      _ => true,
    };

    if (!hasInterface) {
      _setOnlineState(false, reason: 'Interface disconnected');
      return;
    }

    // Kada je interfejs aktivan (WiFi, Mobile), proveri stvarnu dostupnost
    await checkReachability();
  }

  /// Proverava stvarnu dostupnost interneta (ping/DNS ili navigator.onLine na webu).
  Future<bool> checkReachability() async {
    if (_isCheckingReachability) return _isOnline;
    _isCheckingReachability = true;

    try {
      bool reachable = false;
      if (_customReachabilityChecker != null) {
        reachable = await _customReachabilityChecker();
      } else if (kIsWeb) {
        // Na webu čitamo status browsera preko navigator.onLine
        reachable = isWebOnline;
      } else {
        try {
          // Brz DNS lookup ka Google DNS sa kratkim timeout-om
          final addresses = await InternetAddress.lookup('dns.google')
              .timeout(const Duration(seconds: 3));
          reachable = addresses.isNotEmpty && addresses[0].rawAddress.isNotEmpty;
        } catch (_) {
          reachable = false;
        }
      }

      _setOnlineState(
        reachable,
        reason: reachable ? 'Reachability check passed' : 'Reachability check failed',
      );
      return reachable;
    } finally {
      _isCheckingReachability = false;
    }
  }

  /// Autoritativni signal: aplikacioni servis (npr. Supabase, HTTP) je naišao na mrežnu grešku.
  void reportNetworkFailure(dynamic error) {
    if (_isNetworkException(error) && _isOnline) {
      _setOnlineState(false, reason: 'Authoritative network failure: $error');
    }
  }

  /// Autoritativni signal: mrežni poziv je uspeo, internet je sigurno dostupan.
  void reportNetworkSuccess() {
    if (!_isOnline) {
      _setOnlineState(true, reason: 'Authoritative network success');
    }
  }

  void _setOnlineState(bool newState, {String? reason}) {
    if (_isOnline != newState) {
      _isOnline = newState;
      LoggerService.info(
        'Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}'
        '${reason != null ? " ($reason)" : ""}',
      );
      notifyListeners();
    }
  }

  static bool _isNetworkException(dynamic error) {
    if (error == null) return false;
    final errStr = error.toString().toLowerCase();
    return error is SocketException ||
        error is TimeoutException ||
        errStr.contains('socketexception') ||
        errStr.contains('network is unreachable') ||
        errStr.contains('connection refused') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('connection closed') ||
        errStr.contains('timed out') ||
        errStr.contains('clientexception');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
