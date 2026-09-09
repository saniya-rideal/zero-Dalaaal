import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/trading_colors.dart';
import '../core/theme/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PinInputPad extends StatefulWidget {
  final int pinLength;
  final ValueChanged<String> onCompleted;
  final bool hasError;
  final bool showBiometric;
  final VoidCallback? onBiometricPressed;
  final String title;
  final String? subtitle;

  const PinInputPad({
    super.key,
    this.pinLength = 6,
    required this.onCompleted,
    this.hasError = false,
    this.showBiometric = false,
    this.onBiometricPressed,
    this.title = 'Enter App PIN',
    this.subtitle,
  });

  @override
  State<PinInputPad> createState() => _PinInputPadState();
}

class _PinInputPadState extends State<PinInputPad> with SingleTickerProviderStateMixin {
  String _currentPin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void didUpdateWidget(covariant PinInputPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _shakeController.forward(from: 0.0).then((_) {
        setState(() {
          _currentPin = '';
        });
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    HapticFeedback.lightImpact();
    if (_currentPin.length < widget.pinLength) {
      setState(() {
        _currentPin += digit;
      });

      if (_currentPin.length == widget.pinLength) {
        widget.onCompleted(_currentPin);
      }
    }
  }

  void _onDeletePressed() {
    HapticFeedback.lightImpact();
    if (_currentPin.isNotEmpty) {
      setState(() {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.title,
          style: AppTypography.h1(color: colors.textPrimary),
          textAlign: TextAlign.center,
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subtitle!,
            style: AppTypography.body(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 32),

        // PIN Indicator dots with shake animation
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final offset = widget.hasError
                ? (_shakeAnimation.value * (_currentPin.length.isEven ? 1 : -1))
                : 0.0;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.pinLength, (index) {
                  final isFilled = index < _currentPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? colors.primary : Colors.transparent,
                      border: Border.all(
                        color: widget.hasError
                            ? colors.bearish
                            : (isFilled ? colors.primary : colors.divider),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),

        const SizedBox(height: 48),

        // Keypad Grid
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            children: [
              _buildKeypadRow(['1', '2', '3']),
              const SizedBox(height: 16),
              _buildKeypadRow(['4', '5', '6']),
              const SizedBox(height: 16),
              _buildKeypadRow(['7', '8', '9']),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  widget.showBiometric
                      ? _buildActionButton(
                          icon: LucideIcons.fingerprint,
                          onPressed: widget.onBiometricPressed,
                        )
                      : const SizedBox(width: 72, height: 72),
                  _buildDigitButton('0'),
                  _buildActionButton(
                    icon: LucideIcons.delete,
                    onPressed: _onDeletePressed,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_buildDigitButton).toList(),
    );
  }

  Widget _buildDigitButton(String digit) {
    final colors = context.tradingColors;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _onDigitPressed(digit),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surface,
          ),
          child: Text(
            digit,
            style: AppTypography.display(
              color: colors.textPrimary,
              weight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final colors = context.tradingColors;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 28,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
