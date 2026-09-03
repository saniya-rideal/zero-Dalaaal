import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/services/maintenance_service.dart';

class MaintenanceBanner extends ConsumerWidget {
  const MaintenanceBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenanceState = ref.watch(maintenanceServiceProvider);

    // If maintenance is active and is not a full hard block (or as an info banner)
    if (!maintenanceState.isMaintenanceActive || maintenanceState.isHardBlock) {
      return const SizedBox.shrink();
    }

    return Material(
      color: const Color(0xFFE65100),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Maintenance notice: Some exchange segments may experience delays.',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
