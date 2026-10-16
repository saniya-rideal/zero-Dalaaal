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
  int _currentStep = 1; // 1: Form, 2: Success

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  String _countryCode = '+91';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _acceptRiskDisclosure = false;

  String? _generatedClientId;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
    _pinController.addListener(() => setState(() {}));
    _confirmPinController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int strength = 0;
    if (password.length >= 10) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    return strength;
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 1:
        return const Color(0xFFE82B57);
      case 2:
        return const Color(0xFFF5A623);
      case 3:
        return const Color(0xFF2F80ED);
      case 4:
        return const Color(0xFF00A854);
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
    final hasEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim());
    final hasMobile = _mobileController.text.trim().length >= 10;
    final hasMinPassword = _passwordController.text.length >= 10;
    final strength = _calculatePasswordStrength(_passwordController.text);
    final passwordsMatch = _passwordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;
    final pinValid = RegExp(r'^\d{6}$').hasMatch(_pinController.text.trim()) &&
        _pinController.text.trim() == _confirmPinController.text.trim();
    final legalAccepted = _acceptTerms && _acceptPrivacy && _acceptRiskDisclosure;

    return hasName && hasEmail && hasMobile && hasMinPassword && strength >= 2 && passwordsMatch && pinValid && legalAccepted;
  }

  Future<void> _handleRegister() async {
    if (ref.read(isOfflineProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot register while offline. Please check your internet connection.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    final formattedPhone = _mobileController.text.trim().startsWith('+')
        ? _mobileController.text.trim()
        : '$_countryCode${_mobileController.text.trim()}';

    final result = await ref.read(authControllerProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: formattedPhone,
          password: _passwordController.text,
          pin: _pinController.text.trim(),
        );

    if (result != null && mounted) {
      setState(() {
        _generatedClientId = result.clientId;
        _currentStep = 2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _currentStep == 1 ? 'Create Zero Account' : 'Account Created',
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _currentStep == 1
              ? _buildForm(colors, authState)
              : _buildSuccess(colors),
        ),
      ),
    );
  }

  Widget _buildForm(TradingColors colors, AuthState authState) {
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
          const SizedBox(height: 16),

          if (authState.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colors.bearish.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.bearish.withValues(alpha: 0.3)),
              ),
              child: Text(
                authState.errorMessage!,
                style: GoogleFonts.inter(color: colors.bearish, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],

          // 1. Full Name
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
          const SizedBox(height: 12),

          // 2. Email Address
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Email Address',
              labelStyle: TextStyle(color: colors.textSecondary),
              prefixIcon: Icon(LucideIcons.mail, color: colors.primary, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // 3. Mobile Number
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    items: ['+91', '+1', '+44', '+971'].map((code) {
                      return DropdownMenuItem(
                        value: code,
                        child: Text(
                          code,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
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
          const SizedBox(height: 12),

          // 4. Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Password',
              helperText: _passwordController.text.isNotEmpty && _passwordController.text.length < 10
                  ? 'Must be at least 10 characters (${_passwordController.text.length}/10)'
                  : 'At least 10 characters with numbers/symbols',
              helperStyle: TextStyle(
                color: _passwordController.text.isNotEmpty && _passwordController.text.length < 10
                    ? colors.bearish
                    : colors.textSecondary,
                fontSize: 11,
              ),
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
          if (_passwordController.text.isNotEmpty) ...[
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

          // 5. Confirm Password
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
          const SizedBox(height: 12),

          // 6. Security PIN (6 digits)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _pinController,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: '6-digit PIN',
                    counterText: '',
                    labelStyle: TextStyle(color: colors.textSecondary),
                    prefixIcon: Icon(LucideIcons.shieldCheck, color: colors.primary, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePin ? LucideIcons.eye : LucideIcons.eyeOff,
                        color: colors.textSecondary,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _confirmPinController,
                  obscureText: _obscureConfirmPin,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Confirm PIN',
                    counterText: '',
                    labelStyle: TextStyle(color: colors.textSecondary),
                    prefixIcon: Icon(LucideIcons.shieldCheck, color: colors.primary, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPin ? LucideIcons.eye : LucideIcons.eyeOff,
                        color: colors.textSecondary,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Legal Checkboxes
          CheckboxListTile(
            title: Text('I accept the Terms & Conditions', style: GoogleFonts.inter(fontSize: 12, color: colors.textPrimary)),
            value: _acceptTerms,
            onChanged: (val) => setState(() => _acceptTerms = val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          CheckboxListTile(
            title: Text('I accept the Privacy Policy', style: GoogleFonts.inter(fontSize: 12, color: colors.textPrimary)),
            value: _acceptPrivacy,
            onChanged: (val) => setState(() => _acceptPrivacy = val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          CheckboxListTile(
            title: Text('Risk Disclosure: 9 out of 10 traders incur losses in F&O.', style: GoogleFonts.inter(fontSize: 12, color: colors.bearish)),
            value: _acceptRiskDisclosure,
            onChanged: (val) => setState(() => _acceptRiskDisclosure = val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: (_isFormValid && !authState.isLoading) ? _handleRegister : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                disabledBackgroundColor: colors.surface,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: authState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'CREATE ACCOUNT',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          Center(
            child: Wrap(
              children: [
                Text('Already registered? ', style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 13)),
                InkWell(
                  onTap: () => context.pop(),
                  child: Text('Log In', style: GoogleFonts.inter(color: colors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(TradingColors colors) {
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
          'Please note your permanent Client ID below. You will use it to log in.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13.5, color: colors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 24),

        // Generated Client ID Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Text('Your Client ID', style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              Text(
                _generatedClientId ?? '-',
                style: GoogleFonts.inter(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  letterSpacing: 2,
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Name', style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 13)),
                  Text(_nameController.text.trim(), style: GoogleFonts.inter(color: colors.textPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Email', style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 13)),
                  Text(_emailController.text.trim(), style: GoogleFonts.inter(color: colors.textPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => context.go('/quotes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('PROCEED TO TRADE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}
