import 'dart:async';
import 'dart:io' show Socket, InternetAddress;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus {
  online,
  offline,
  reconnecting,
}

class ConnectivityService extends StateNotifier<NetworkStatus> {
  Timer? _heartbeatTimer;
  bool _isManualOverride = false;

  ConnectivityService() : super(NetworkStatus.online) {
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!_isManualOverride) {
        _checkActualConnectivity();
      }
    });
  }

  Future<void> _checkActualConnectivity() async {
    // Flutter Web runs inside browser sandbox where raw sockets are not permitted
    if (kIsWeb) {
      if (state != NetworkStatus.online) {
        state = NetworkStatus.online;
      }
      return;
    }

    try {
      // Primary native check: Fast socket connect to DNS server
      final socket = await Socket.connect('8.8.8.8', 53,
          timeout: const Duration(seconds: 3));
      socket.destroy();
      if (state != NetworkStatus.online) {
        state = NetworkStatus.online;
      }
    } catch (_) {
      try {
        // Fallback: Domain lookup
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          if (state != NetworkStatus.online) {
            state = NetworkStatus.online;
          }
          return;
        }
      } catch (_) {
        // Actual disconnected state on native device
        if (state != NetworkStatus.offline) {
          state = NetworkStatus.offline;
        }
      }
    }
  }

  /// Manually toggle simulated offline mode for testing
  void setSimulatedOffline(bool isOffline) {
    _isManualOverride = true;
    state = isOffline ? NetworkStatus.offline : NetworkStatus.online;
  }

  /// Trigger manual reconnect attempt
  Future<void> retryConnection() async {
    state = NetworkStatus.reconnecting;
    await Future.delayed(const Duration(milliseconds: 600));
    _isManualOverride = false;
    await _checkActualConnectivity();
    if (state == NetworkStatus.reconnecting) {
      state = NetworkStatus.online;
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}

final connectivityServiceProvider =
    StateNotifierProvider<ConnectivityService, NetworkStatus>((ref) {
  return ConnectivityService();
});

final isOfflineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityServiceProvider);
  return status == NetworkStatus.offline || status == NetworkStatus.reconnecting;
});
