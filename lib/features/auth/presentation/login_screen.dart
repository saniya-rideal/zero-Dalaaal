import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import 'auth_controller.dart';
import 'forgot_password_sheet.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  int _failedAttempts = 0;
  bool _isLocked = false;
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _identifierController.dispose();
    _passwordController.dispose();
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

  bool _isValidIdentifier(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return false;
    // Accept Client ID format ZD + 6 digits (e.g. ZD482915)
    if (RegExp(r'^ZD\d{6}$', caseSensitive: false).hasMatch(clean)) return true;
    // Accept valid Email
    if (RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(clean)) return true;
    // Accept Phone Number (10 to 13 digits with optional +)
    if (RegExp(r'^\+?[0-9]{10,13}$').hasMatch(clean)) return true;
    // Fallback: at least 4 characters
    return clean.length >= 4;
  }

  Future<void> _handleLogin() async {
    if (_isLocked) return;
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(authControllerProvider.notifier).login(
          _identifierController.text.trim(),
          _passwordController.text,
        );

    if (result != null && mounted) {
      _failedAttempts = 0;
      // Navigate to Security PIN / TOTP screen
      context.push('/totp');
    } else {
      final authState = ref.read(authControllerProvider);
      if (authState.errorMessage != null && authState.errorMessage!.contains('ACCOUNT_LOCKED')) {
        _startLockoutTimer(900); // 15 mins
      } else {
        setState(() => _failedAttempts++);
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

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Top Zero Logo
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.trendingUp,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Login to Zero',
                  style: AppTypography.h1(
                    color: colors.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Enter your Client ID, email, or mobile number to continue',
                  style: AppTypography.body(color: colors.textSecondary),
                ),

                if (_isLocked) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.bearish.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: colors.bearish.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.clock, color: colors.bearish, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Account temporarily locked. Please retry in ${(_lockoutSeconds / 60).ceil()} minutes.',
                            style: AppTypography.caption(
                              color: colors.bearish,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (authState.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.bearish.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: colors.bearish.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      authState.errorMessage!,
                      style: AppTypography.caption(color: colors.bearish),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                TextFormField(
                  controller: _identifierController,
                  enabled: !_isLocked,
                  decoration: const InputDecoration(
                    labelText: 'Client ID / Email / Mobile',
                    hintText: 'e.g. ZD482915 or trader@example.com',
                    prefixIcon: Icon(LucideIcons.user, size: 18),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your Client ID, email or phone';
                    }
                    if (!_isValidIdentifier(val)) {
                      return 'Enter a valid Client ID (e.g. ZD482915), email or mobile';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLocked,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(LucideIcons.lock, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? LucideIcons.eye
                          : LucideIcons.eyeOff, size: 18),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty
                      ? 'Please enter your password'
                      : null,
                ),

                const SizedBox(height: 8),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => ForgotPasswordSheet.show(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot User ID or Password?',
                      style: AppTypography.caption(
                        color: colors.primary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: (authState.isLoading || _isLocked) ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    disabledBackgroundColor: colors.surface,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isLocked ? 'LOCKED (${_lockoutSeconds}s)' : 'CONTINUE',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),

                const SizedBox(height: 20),

                // Register Link
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: AppTypography.body(color: colors.textSecondary),
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: InkWell(
                            onTap: () => context.push('/register'),
                            child: Text(
                              'Sign Up',
                              style: AppTypography.body(
                                color: colors.primary,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
