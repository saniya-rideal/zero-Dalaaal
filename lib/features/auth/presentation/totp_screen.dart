import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../shared_widgets/pin_input_pad.dart';
import 'auth_controller.dart';

class TotpScreen extends ConsumerWidget {
  const TotpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.tradingColors;
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              PinInputPad(
                title: 'Two-Factor Auth (2FA)',
                subtitle: 'Enter the 6-digit TOTP / App PIN to authenticate',
                hasError: authState.errorMessage != null,
                onCompleted: (pin) async {
                  final success = await ref.read(authControllerProvider.notifier).verifyTotp(pin);
                  if (success && context.mounted) {
                    context.go('/quotes');
                  }
                },
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
