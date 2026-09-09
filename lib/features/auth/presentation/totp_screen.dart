import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/services/security_privacy_service.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../shared_widgets/pin_input_pad.dart';
import 'auth_controller.dart';

class TotpScreen extends ConsumerStatefulWidget {
  const TotpScreen({super.key});

  @override
  ConsumerState<TotpScreen> createState() => _TotpScreenState();
}

class _TotpScreenState extends ConsumerState<TotpScreen> {
  int _failedAttempts = 0;
  bool _isLocked = false;
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;

  int _resendCooldown = 30;
  Timer? _resendTimer;
  late final SecurityPrivacyService _securityService;

  @override
  void initState() {
    super.initState();
    _securityService = ref.read(securityPrivacyServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _securityService.setScreenProtection(true);
    });
    _startResendTimer();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _resendTimer?.cancel();
    _securityService.setScreenProtection(false);
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendCooldown = 30);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
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

  Future<void> _handleTotpSubmitted(String pin) async {
    if (_isLocked) return;

    final security = ref.read(securityPrivacyServiceProvider);
    final success = await ref.read(authControllerProvider.notifier).verifyTotp(pin);

    if (success) {
      _failedAttempts = 0;
      security.resetAttempts('totp_verification');
      if (mounted) {
        context.go('/quotes');
      }
    } else {
      setState(() => _failedAttempts++);
      security.recordFailedAttempt('totp_verification', maxAttempts: 3, lockoutDurationSeconds: 60);

      if (_failedAttempts >= 3) {
        _startLockoutTimer(60);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 22),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
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
                        'OTP Locked. Try again in $_lockoutSeconds s',
                        style: GoogleFonts.inter(
                          color: colors.bearish,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

              PinInputPad(
                title: 'Two-Factor Auth (2FA)',
                subtitle: _isLocked
                    ? 'Too many incorrect OTP entries. Cooldown active.'
                    : 'Enter the 6-digit TOTP / App PIN to authenticate',
                hasError: authState.errorMessage != null || _isLocked,
                onCompleted: _isLocked ? (_) {} : _handleTotpSubmitted,
              ),

              const SizedBox(height: 20),

              // Resend OTP Countdown & Action
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _resendCooldown > 0
                        ? 'Resend OTP via SMS in $_resendCooldown s'
                        : 'Did not receive code?',
                    style: GoogleFonts.inter(fontSize: 12.5, color: colors.textSecondary),
                  ),
                  if (_resendCooldown == 0 && !_isLocked) ...[
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: () {
                        _startResendTimer();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('New 6-digit OTP dispatched to verified mobile.')),
                        );
                      },
                      child: Text('Resend OTP', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),

              if (authState.isLoading) ...[
                const SizedBox(height: 24),
                CircularProgressIndicator(color: colors.primary, strokeWidth: 2),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
