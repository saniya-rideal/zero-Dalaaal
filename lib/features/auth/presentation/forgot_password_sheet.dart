import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';

class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ForgotPasswordSheet(),
    );
  }

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  int _step = 1; // 1: Input Mobile/User ID, 2: OTP & New Password, 3: Success

  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  int _countdown = 30;
  Timer? _timer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _identifierController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    return strength;
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 1:
        return const Color(0xFFE82B57); // Red
      case 2:
        return const Color(0xFFF5A623); // Orange
      case 3:
        return const Color(0xFF2F80ED); // Blue
      case 4:
        return const Color(0xFF00A854); // Green
      default:
        return Colors.grey.shade400;
    }
  }

  String _getStrengthText(int strength) {
    switch (strength) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Enter password';
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _sendOtp() {
    final id = _identifierController.text.trim();
    if (id.isEmpty) {
      setState(() => _errorMessage = 'Please enter your registered User ID or Mobile number');
      return;
    }
    setState(() {
      _errorMessage = null;
      _step = 2;
    });
    _startCountdown();
  }

  void _resetPassword() {
    final otp = _otpController.text.trim();
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (_countdown == 0) {
      setState(() => _errorMessage = 'OTP has expired. Please click Resend Code.');
      return;
    }
    if (otp != '1234') {
      setState(() => _errorMessage = 'Invalid verification OTP. Please check or resend.');
      return;
    }
    if (newPass.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters long');
      return;
    }
    if (_calculatePasswordStrength(newPass) < 2) {
      setState(() => _errorMessage = 'Please choose a stronger password with letters and numbers');
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'New passwords do not match');
      return;
    }

    _timer?.cancel();
    setState(() {
      _errorMessage = null;
      _step = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _step == 1
                        ? 'Reset Password'
                        : (_step == 2 ? 'Verify & Set New Password' : 'Password Reset Complete'),
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: colors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colors.bearish.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.bearish.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.inter(fontSize: 12, color: colors.bearish, fontWeight: FontWeight.w600),
                  ),
                ),
              ],

              if (_step == 1) _buildStep1(colors),
              if (_step == 2) _buildStep2(colors),
              if (_step == 3) _buildStep3(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1(TradingColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter your registered User ID or 10-digit mobile number. We will send a one-time verification code.',
          style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _identifierController,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: 'User ID or Mobile Number',
            prefixIcon: Icon(LucideIcons.user, color: colors.primary, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('SEND VERIFICATION CODE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(TradingColors colors) {
    final strength = _calculatePasswordStrength(_newPasswordController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the 4-digit code sent to ${_identifierController.text.trim()} (Demo OTP: 1234)',
          style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 16, color: colors.textPrimary),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: const Icon(LucideIcons.lock, size: 18),
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? LucideIcons.eye : LucideIcons.eyeOff, size: 18),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        if (_newPasswordController.text.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: strength / 4,
                    backgroundColor: colors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor(strength)),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _getStrengthText(strength),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _getStrengthColor(strength),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            prefixIcon: const Icon(LucideIcons.keyRound, size: 18),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? LucideIcons.eye : LucideIcons.eyeOff, size: 18),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Didn't get code? ", style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 12.5)),
            if (_countdown > 0)
              Text('Resend in ${_countdown}s', style: GoogleFonts.inter(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 12.5))
            else
              InkWell(
                onTap: _sendOtp,
                child: Text('Resend Code', style: GoogleFonts.inter(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 12.5)),
              ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('UPDATE PASSWORD', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(TradingColors colors) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFF00A854),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.check, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'Password Changed!',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Your password has been securely updated. You can now log in with your new credentials.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('LOG IN NOW', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
