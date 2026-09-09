import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/trading_colors.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Step 1: Form Details, Step 2: OTP Verification, Step 3: Success Confirmation
  int _currentStep = 1;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  String _countryCode = '+91';
  String _selectedLanguage = 'English';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Checkboxes
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _acceptRiskDisclosure = false;

  // OTP State
  int _otpCountdown = 30;
  Timer? _countdownTimer;
  int _failedOtpAttempts = 0;
  bool _isRateLimited = false;
  int _rateLimitSeconds = 0;
  Timer? _rateLimitTimer;
  String? _otpError;
  String _generatedOtp = '123456';
  String? _generatedUserId;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _rateLimitTimer?.cancel();
    _nameController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startOtpCountdown() {
    _countdownTimer?.cancel();
    setState(() => _otpCountdown = 30);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpCountdown > 0) {
        setState(() => _otpCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _startRateLimit(int seconds) {
    setState(() {
      _isRateLimited = true;
      _rateLimitSeconds = seconds;
    });
    _rateLimitTimer?.cancel();
    _rateLimitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_rateLimitSeconds > 0) {
        setState(() => _rateLimitSeconds--);
      } else {
        setState(() => _isRateLimited = false);
        timer.cancel();
      }
    });
  }

  // Password strength checker (0 to 4)
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

  bool get _isFormValid {
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasMobile = _mobileController.text.trim().length >= 10;
    final strength = _calculatePasswordStrength(_passwordController.text);
    final passwordsMatch = _passwordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;
    final legalAccepted =
        _acceptTerms && _acceptPrivacy && _acceptRiskDisclosure;
    return hasName && hasMobile && strength >= 2 && passwordsMatch && legalAccepted;
  }

  void _requestOtp() {
    if (ref.read(isOfflineProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot register while offline. Please check your internet connection.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    // Duplicate mobile check simulation
    if (_mobileController.text.trim() == '9999999999') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This mobile number is already registered. Please log in.'),
          backgroundColor: Color(0xFFE65100),
        ),
      );
      return;
    }

    setState(() {
      _currentStep = 2;
      _otpError = null;
      _failedOtpAttempts = 0;
      _generatedOtp = '123456';
    });
    _startOtpCountdown();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP sent to $_countryCode ${_mobileController.text.trim()} (Demo OTP: 123456)'),
        backgroundColor: const Color(0xFF00A854),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _verifyOtp() {
    if (_isRateLimited) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Too many failed attempts. Try again in $_rateLimitSeconds seconds.'),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
      return;
    }

    final entered = _otpController.text.trim();
    if (entered == _generatedOtp) {
      _countdownTimer?.cancel();
      final randomNum = 100000 + DateTime.now().millisecond * 89;
      setState(() {
        _generatedUserId = 'ZD-$randomNum';
        _currentStep = 3;
      });
    } else {
      setState(() {
        _failedOtpAttempts++;
        _otpError = 'Invalid OTP entered. Please try again.';
      });
      if (_failedOtpAttempts >= 3) {
        _startRateLimit(60);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary, size: 22),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() => _currentStep = 1);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          _currentStep == 1
              ? 'Create Zero Account'
              : (_currentStep == 2 ? 'Verify Mobile OTP' : 'Account Created'),
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_currentStep == 1)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  dropdownColor: colors.cardBackground,
                  icon: Icon(LucideIcons.globe, color: colors.primary, size: 18),
                  items: ['English'].map((lang) {
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(
                        lang,
                        style: GoogleFonts.inter(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedLanguage = val);
                  },
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _currentStep == 1
              ? _buildStep1Form(colors)
              : (_currentStep == 2 ? _buildStep2Otp(colors) : _buildStep3Success(colors)),
        ),
      ),
    );
  }

  // STEP 1: REGISTRATION FORM
  Widget _buildStep1Form(TradingColors colors) {
    final strength = _calculatePasswordStrength(_passwordController.text);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Zero Brokerage Trading Account',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your details to register in minutes',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // 1. Full Name Field
          TextFormField(
            controller: _nameController,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Full Name (as per PAN)',
              labelStyle: TextStyle(color: colors.textSecondary),
              prefixIcon: Icon(LucideIcons.user, color: colors.primary, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // 2. Mobile Number & Country Code Field
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Country Code Selector
              Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.divider),
                  borderRadius: BorderRadius.circular(8),
                  color: colors.cardBackground,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _countryCode,
                    dropdownColor: colors.cardBackground,
                    items: ['+91', '+1', '+44', '+971', '+65'].map((code) {
                      return DropdownMenuItem(
                        value: code,
                        child: Text(
                          code,
                          style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _countryCode = val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Mobile Number Field
              Expanded(
                child: TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    labelStyle: TextStyle(color: colors.textSecondary),
                    prefixIcon: Icon(LucideIcons.smartphone, color: colors.primary, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Password Creation Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: colors.textSecondary),
              prefixIcon: Icon(LucideIcons.lock, color: colors.primary, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                  color: colors.textSecondary,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 6),

          // Password Strength Bar
          if (_passwordController.text.isNotEmpty) ...[
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
            const SizedBox(height: 4),
            Text(
              'Minimum 8 chars with uppercase, number & symbol',
              style: GoogleFonts.inter(fontSize: 10.5, color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: 14),

          // 4. Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              labelStyle: TextStyle(color: colors.textSecondary),
              prefixIcon: Icon(LucideIcons.keyRound, color: colors.primary, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? LucideIcons.eye : LucideIcons.eyeOff,
                  color: colors.textSecondary,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          if (_confirmPasswordController.text.isNotEmpty &&
              _passwordController.text != _confirmPasswordController.text) ...[
            const SizedBox(height: 4),
            Text(
              'Passwords do not match',
              style: GoogleFonts.inter(fontSize: 11, color: colors.bearish),
            ),
          ],
          const SizedBox(height: 18),

          // 5. Legal Checkboxes & Risk Disclosure
          _buildCheckboxTile(
            title: 'I accept the Terms & Conditions',
            value: _acceptTerms,
            onChanged: (val) => setState(() => _acceptTerms = val ?? false),
            colors: colors,
            onInfoTap: () => _showDialogInfo(
              context,
              'Terms & Conditions',
              'By opening a Zero account, you agree to exchange rules (NSE/BSE/MCX) and standard client broking agreements.',
            ),
          ),
          _buildCheckboxTile(
            title: 'I accept the Privacy Policy',
            value: _acceptPrivacy,
            onChanged: (val) => setState(() => _acceptPrivacy = val ?? false),
            colors: colors,
            onInfoTap: () => _showDialogInfo(
              context,
              'Privacy Policy',
              'Your PAN, mobile, KYC and banking records are protected with bank-grade 256-bit encryption.',
            ),
          ),
          _buildCheckboxTile(
            title: 'Risk Disclosure: 9 out of 10 individual traders in F&O incur net losses.',
            value: _acceptRiskDisclosure,
            onChanged: (val) => setState(() => _acceptRiskDisclosure = val ?? false),
            colors: colors,
            isWarning: true,
            onInfoTap: () => _showDialogInfo(
              context,
              'SEBI Risk Disclosure',
              'Derivative trading carries substantial capital risk. Over 90% of active retail traders incur losses.',
            ),
          ),

          const SizedBox(height: 24),

          // 6. Create Account Button (Disabled until valid)
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isFormValid ? _requestOtp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                disabledBackgroundColor: colors.surface,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(
                'CONTINUE & REQUEST OTP',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Back to Login Link
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Already have an account? ',
                  style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 13)),
              InkWell(
                onTap: () => context.pop(),
                child: Text(
                  'Log In',
                  style: GoogleFonts.inter(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // STEP 2: OTP VERIFICATION
  Widget _buildStep2Otp(TradingColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.messageSquare, size: 36, color: colors.primary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Enter Verification Code',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'A 6-digit OTP has been sent to $_countryCode ${_mobileController.text.trim()}',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 24),

        // OTP Input Field
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 12,
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (val) {
            if (val.length == 6) {
              _verifyOtp();
            }
          },
        ),

        if (_otpError != null) ...[
          const SizedBox(height: 8),
          Text(
            _otpError!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 12.5,
                color: colors.bearish,
                fontWeight: FontWeight.w600),
          ),
        ],

        if (_isRateLimited) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bearish.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Too many failed attempts. Cooldown: $_rateLimitSeconds seconds remaining.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.bearish,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Resend Timer / Action
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Didn't receive code? ",
                style: GoogleFonts.inter(
                    color: colors.textSecondary, fontSize: 13)),
            if (_otpCountdown > 0)
              Text(
                'Resend in ${_otpCountdown}s',
                style: GoogleFonts.inter(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              )
            else
              InkWell(
                onTap: _isRateLimited ? null : _requestOtp,
                child: Text(
                  'Resend OTP',
                  style: GoogleFonts.inter(
                    color: _isRateLimited ? Colors.grey : colors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 24),

        // Verify Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _otpController.text.length == 6 ? _verifyOtp : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'VERIFY & REGISTER',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // STEP 3: SUCCESS CONFIRMATION
  Widget _buildStep3Success(TradingColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFF00A854),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.check, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          'Registration Complete!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome to Zero Dalali. Your trading account has been successfully initialized.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13.5, color: colors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 24),

        // Account Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Client User ID',
                      style: GoogleFonts.inter(
                          color: colors.textSecondary, fontSize: 13)),
                  Text(_generatedUserId ?? 'ZD-159537',
                      style: GoogleFonts.inter(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Registered Name',
                      style: GoogleFonts.inter(
                          color: colors.textSecondary, fontSize: 13)),
                  Text(_nameController.text.trim(),
                      style: GoogleFonts.inter(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mobile',
                      style: GoogleFonts.inter(
                          color: colors.textSecondary, fontSize: 13)),
                  Text('$_countryCode ${_mobileController.text.trim()}',
                      style: GoogleFonts.inter(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Proceed to Trade Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              ref.read(authControllerProvider.notifier).login(
                    _generatedUserId ?? 'ZD-159537',
                    _passwordController.text,
                  );
              context.go('/quotes');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'PROCEED TO TRADE',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required TradingColors colors,
    required VoidCallback onInfoTap,
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: isWarning ? colors.bearish : colors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => onChanged(!value),
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: isWarning ? FontWeight.w700 : FontWeight.w500,
                  color: isWarning ? colors.bearish : colors.textPrimary,
                  height: 1.3,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.info, size: 16, color: colors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onInfoTap,
          ),
        ],
      ),
    );
  }

  void _showDialogInfo(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(message, style: const TextStyle(fontSize: 13, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}
