import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared_widgets/pin_input_pad.dart';
import 'auth_controller.dart';

class PinUnlockScreen extends ConsumerStatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  ConsumerState<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends ConsumerState<PinUnlockScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final authState = ref.watch(authControllerProvider);
    final userName = authState.session?.profile.name ?? AppConstants.demoUserName;
    final userId = authState.session?.profile.userId ?? AppConstants.demoUserId;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // User Avatar
              CircleAvatar(
                radius: 36,
                backgroundColor: colors.surface,
                child: Text(
                  userId.length >= 2 ? userId.substring(0, 2) : 'ZD',
                  style: AppTypography.h1(color: colors.primary, weight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                userName,
                style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w600),
              ),

              Text(
                userId,
                style: AppTypography.caption(color: colors.textSecondary),
              ),

              const SizedBox(height: 32),

              PinInputPad(
                title: 'Enter App PIN',
                subtitle: 'Unlock Kite with your 6-digit PIN',
                hasError: authState.errorMessage != null,
                showBiometric: true,
                onBiometricPressed: () async {
                  // Simulate biometric success
                  final success = await ref.read(authControllerProvider.notifier).verifyPin(AppConstants.defaultPin);
                  if (success && context.mounted) {
                    context.go('/quotes');
                  }
                },
                onCompleted: (pin) async {
                  final success = await ref.read(authControllerProvider.notifier).verifyPin(pin);
                  if (success && context.mounted) {
                    context.go('/quotes');
                  }
                },
              ),

              const SizedBox(height: 24),

              TextButton(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: Text(
                  'Switch Account / Login Again',
                  style: AppTypography.caption(color: colors.primary, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
