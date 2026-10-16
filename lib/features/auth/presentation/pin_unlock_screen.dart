import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _securityService = ref.read(securityPrivacyServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _securityService.setScreenProtection(true);
      _checkBiometrics();
    });
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (mounted) setState(() => _canCheckBiometrics = canCheck);
    } catch (_) {}
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
    final success = await ref.read(authControllerProvider.notifier).verifyAppPin(pin);

    if (success) {
      _failedAttempts = 0;
      security.resetAttempts('app_pin_unlock');
      if (mounted) {
        context.go('/quotes');
      }
    } else {
      final currentAuthState = ref.read(authControllerProvider);
      if (currentAuthState.errorMessage != null && currentAuthState.errorMessage!.contains('ACCOUNT_LOCKED')) {
        _startLockoutTimer(900);
      } else {
        setState(() => _failedAttempts++);
        security.recordFailedAttempt('app_pin_unlock', maxAttempts: 5, lockoutDurationSeconds: 900);

        if (_failedAttempts >= 5) {
          _startLockoutTimer(900);
        }
      }
    }
  }

  Future<void> _handleBiometricAuth() async {
    if (_isLocked) return;
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Unlock Zero Dalali',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
      if (didAuthenticate && mounted) {
        context.go('/quotes');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final authState = ref.watch(authControllerProvider);
    final userName = authState.session?.profile.name ?? 'Trader';
    final userId = authState.session?.profile.userId ?? '-';

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
                        'Account Locked. Try again in ${(_lockoutSeconds / 60).ceil()}m',
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
                    : 'Unlock Zero with your 6-digit PIN',
                hasError: authState.errorMessage != null || _isLocked,
                showBiometric: _canCheckBiometrics && !_isLocked,
                onBiometricPressed: _handleBiometricAuth,
                onCompleted: _isLocked ? (_) {} : _handlePinSubmitted,
              ),

              if (authState.errorMessage != null && !_isLocked) ...[
                const SizedBox(height: 12),
                Text(
                  authState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption(color: colors.bearish),
                ),
              ],

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
