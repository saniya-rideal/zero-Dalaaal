import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/services/connectivity_service.dart';

class NetworkStatusBanner extends ConsumerWidget {
  const NetworkStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityServiceProvider);

    if (status == NetworkStatus.online) {
      return const SizedBox.shrink();
    }

    final isOffline = status == NetworkStatus.offline;
    final isReconnecting = status == NetworkStatus.reconnecting;

    final bannerBg = isOffline ? const Color(0xFFC62828) : const Color(0xFFE65100);

    return Material(
      color: bannerBg,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              if (isReconnecting)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isOffline
                      ? 'You are offline. Showing cached market quotes.'
                      : 'Connecting to market server...',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isOffline)
                InkWell(
                  onTap: () {
                    ref.read(connectivityServiceProvider.notifier).retryConnection();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'RETRY',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
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
