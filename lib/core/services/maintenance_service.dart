import 'package:flutter_riverpod/flutter_riverpod.dart';

class MaintenanceState {
  final bool isMaintenanceActive;
  final String title;
  final String message;
  final DateTime? estimatedEndTime;
  final List<String> affectedSegments;
  final bool isHardBlock; // True = Fullscreen block, False = Warning banner

  const MaintenanceState({
    this.isMaintenanceActive = false,
    this.title = 'Scheduled System Maintenance',
    this.message =
        'Zero core exchange gateways are undergoing scheduled optimization. Regular trading sessions will resume shortly.',
    this.estimatedEndTime,
    this.affectedSegments = const ['NSE Equity', 'BSE', 'MCX Commodities', 'UPI Funds Gateway'],
    this.isHardBlock = true,
  });

  MaintenanceState copyWith({
    bool? isMaintenanceActive,
    String? title,
    String? message,
    DateTime? estimatedEndTime,
    List<String>? affectedSegments,
    bool? isHardBlock,
  }) {
    return MaintenanceState(
      isMaintenanceActive: isMaintenanceActive ?? this.isMaintenanceActive,
      title: title ?? this.title,
      message: message ?? this.message,
      estimatedEndTime: estimatedEndTime ?? this.estimatedEndTime,
      affectedSegments: affectedSegments ?? this.affectedSegments,
      isHardBlock: isHardBlock ?? this.isHardBlock,
    );
  }
}

class MaintenanceService extends StateNotifier<MaintenanceState> {
  MaintenanceService() : super(const MaintenanceState());

  void enableMaintenance({
    String? title,
    String? message,
    DateTime? estimatedEndTime,
    List<String>? affectedSegments,
    bool isHardBlock = true,
  }) {
    state = state.copyWith(
      isMaintenanceActive: true,
      title: title ?? 'Scheduled System Maintenance',
      message: message ??
          'Zero trading gateways are undergoing scheduled optimization. Trading sessions will resume shortly.',
      estimatedEndTime: estimatedEndTime ??
          DateTime.now().add(const Duration(hours: 2)),
      affectedSegments: affectedSegments ??
          const ['NSE Equity', 'BSE', 'MCX Commodities', 'UPI Funds Gateway'],
      isHardBlock: isHardBlock,
    );
  }

  void disableMaintenance() {
    state = state.copyWith(isMaintenanceActive: false);
  }
}

final maintenanceServiceProvider =
    StateNotifierProvider<MaintenanceService, MaintenanceState>((ref) {
  return MaintenanceService();
});

final isMaintenanceActiveProvider = Provider<bool>((ref) {
  return ref.watch(maintenanceServiceProvider).isMaintenanceActive;
});
