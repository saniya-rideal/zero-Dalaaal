import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/security_privacy_service.dart';
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
  int _failedAttempts = 0;
  bool _isLocked = false;
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;
  late final SecurityPrivacyService _securityService;

  @override
  void initState() {
    super.initState();
    _securityService = ref.read(securityPrivacyServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _securityService.setScreenProtection(true);
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _securityService.setScreenProtection(false);
    super.dispose();
  }

  void _startLockoutTimer(int seconds) {
    setState(() {
      _isLocked = true;
      _lockoutSeconds = seconds;
    });
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockoutSeconds > 0) {
        setState(() => _lockoutSeconds--);
      } else {
        setState(() {
          _isLocked = false;
          _failedAttempts = 0;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _handlePinSubmitted(String pin) async {
    if (_isLocked) return;

    final security = ref.read(securityPrivacyServiceProvider);
    final success = await ref.read(authControllerProvider.notifier).verifyPin(pin);

    if (success) {
      _failedAttempts = 0;
      security.resetAttempts('app_pin_unlock');
      if (mounted) {
        context.go('/quotes');
      }
    } else {
      setState(() => _failedAttempts++);
      security.recordFailedAttempt('app_pin_unlock', maxAttempts: 3, lockoutDurationSeconds: 60);

      if (_failedAttempts >= 3) {
        _startLockoutTimer(60);
      }
    }
  }

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

              const SizedBox(height: 24),

              if (_isLocked)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bearish.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.bearish.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.clock, color: colors.bearish, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'PIN Locked. Try again in $_lockoutSeconds s',
                        style: AppTypography.body(
                          color: colors.bearish,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

              PinInputPad(
                title: 'Enter App PIN',
                subtitle: _isLocked
                    ? 'Too many failed attempts. Cooldown active.'
                    : 'Unlock Kite with your 6-digit PIN',
                hasError: authState.errorMessage != null || _isLocked,
                showBiometric: false,
                onBiometricPressed: null,
                onCompleted: _isLocked ? (_) {} : _handlePinSubmitted,
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
