import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus {
  online,
  offline,
  reconnecting,
}

class ConnectivityService extends StateNotifier<NetworkStatus> {
  ConnectivityService() : super(NetworkStatus.online);

  /// Manually toggle simulated offline mode for testing
  void setSimulatedOffline(bool isOffline) {
    state = isOffline ? NetworkStatus.offline : NetworkStatus.online;
  }

  /// Trigger manual reconnect attempt
  Future<void> retryConnection() async {
    state = NetworkStatus.reconnecting;
    await Future.delayed(const Duration(milliseconds: 400));
    state = NetworkStatus.online;
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
