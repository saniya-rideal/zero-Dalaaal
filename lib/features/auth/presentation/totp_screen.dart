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

  // For PIN setup mode
  String? _firstEnteredPin;
  bool _isConfirmingSetup = false;
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

    final authState = ref.read(authControllerProvider);
    final isSetup = authState.requiresPinSetup;

    if (isSetup) {
      if (!_isConfirmingSetup) {
        // Step 1 of setup: record first entry and prompt for confirmation
        setState(() {
          _firstEnteredPin = pin;
          _isConfirmingSetup = true;
        });
        return;
      } else {
        // Step 2 of setup: verify matches
        if (pin != _firstEnteredPin) {
          setState(() {
            _firstEnteredPin = null;
            _isConfirmingSetup = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PINs did not match. Please try setting your PIN again.'),
              backgroundColor: Color(0xFFC62828),
            ),
          );
          return;
        }

        final success = await ref.read(authControllerProvider.notifier).setPin(pin);
        if (success && mounted) {
          context.go('/quotes');
        }
        return;
      }
    }

    // Standard verify PIN mode
    final security = ref.read(securityPrivacyServiceProvider);
    final success = await ref.read(authControllerProvider.notifier).verifyPin(pin);

    if (success) {
      _failedAttempts = 0;
      security.resetAttempts('pin_verification');
      if (mounted) {
        context.go('/quotes');
      }
    } else {
      final currentAuthState = ref.read(authControllerProvider);
      if (currentAuthState.errorMessage != null && currentAuthState.errorMessage!.contains('ACCOUNT_LOCKED')) {
        _startLockoutTimer(900);
      } else {
        setState(() => _failedAttempts++);
        security.recordFailedAttempt('pin_verification', maxAttempts: 5, lockoutDurationSeconds: 900);

        if (_failedAttempts >= 5) {
          _startLockoutTimer(900);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final authState = ref.watch(authControllerProvider);
    final isSetup = authState.requiresPinSetup;

    String titleText;
    String subtitleText;

    if (isSetup) {
      if (_isConfirmingSetup) {
        titleText = 'Confirm Security PIN';
        subtitleText = 'Re-enter your 6-digit PIN to confirm';
      } else {
        titleText = 'Create Security PIN';
        subtitleText = 'Set a 6-digit PIN to protect your account';
      }
    } else {
      titleText = 'Security PIN Verification';
      subtitleText = _isLocked
          ? 'Account temporarily locked due to failed attempts.'
          : 'Enter your 6-digit Security PIN to authenticate';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 22),
          onPressed: () {
            if (_isConfirmingSetup) {
              setState(() {
                _firstEnteredPin = null;
                _isConfirmingSetup = false;
              });
            } else {
              context.pop();
            }
          },
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
                        'Account Locked. Try again in ${(_lockoutSeconds / 60).ceil()}m',
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
                title: titleText,
                subtitle: subtitleText,
                hasError: authState.errorMessage != null || _isLocked,
                onCompleted: _isLocked ? (_) {} : _handlePinSubmitted,
              ),

              if (authState.errorMessage != null && !_isLocked) ...[
                const SizedBox(height: 12),
                Text(
                  authState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: colors.bearish,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 20),

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
