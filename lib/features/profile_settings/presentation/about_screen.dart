import 'package:flutter/material.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared_widgets/zero_app_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Scaffold(
      drawer: const ZeroDrawer(activeRoute: '/about'),
      appBar: const ZeroAppBar(
        title: 'About',
        showCalendarAction: false,
        showFilterAction: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Big Logo Card (Black rounded square with Orange Bull horns)
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '🐂',
                          style: TextStyle(fontSize: 70),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Brand Title
                    Text(
                      'Zero',
                      style: AppTypography.display(
                        color: colors.textPrimary,
                        weight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Website Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.language,
                            color: colors.textPrimary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'www.Zero.life',
                          style: AppTypography.body(
                            color: colors.textPrimary,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Email Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mail_outline,
                            color: colors.textPrimary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'mgmt1@Zero.life',
                          style: AppTypography.body(
                            color: colors.textPrimary,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // WhatsApp & Share Action Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // WhatsApp Green Circle
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Color(0xFF25D366), // WhatsApp Green
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Share Pink Circle
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.share,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Version & Build info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Version 7.1.2160',
                          style: AppTypography.body(
                            color: colors.textSecondary,
                            weight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          height: 14,
                          width: 1,
                          color: colors.divider,
                        ),
                        Text(
                          'Build 2160',
                          style: AppTypography.body(
                            color: colors.textSecondary,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
