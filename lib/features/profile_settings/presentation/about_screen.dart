import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
                        child: Icon(
                          LucideIcons.trendingUp,
                          size: 64,
                          color: Colors.white,
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
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse('https://zerodalali.com');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          Clipboard.setData(const ClipboardData(text: 'https://zerodalali.com'));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: const Text('Website URL copied to clipboard: https://zerodalali.com'), backgroundColor: colors.surface),
                            );
                          }
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.globe,
                              color: colors.textPrimary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'www.Zero.life',
                            style: AppTypography.body(
                              color: colors.primary,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Email Link
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse('mailto:support@zerodalali.com');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          Clipboard.setData(const ClipboardData(text: 'support@zerodalali.com'));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: const Text('Support email copied to clipboard: support@zerodalali.com'), backgroundColor: colors.surface),
                            );
                          }
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.mail,
                              color: colors.textPrimary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'support@zerodalali.com',
                            style: AppTypography.body(
                              color: colors.primary,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // WhatsApp & Share Action Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // WhatsApp Green Circle
                        GestureDetector(
                          onTap: () async {
                            const phone = '+919876543210';
                            final whatsappUrl = Uri.parse('whatsapp://send?phone=$phone&text=Hello%20Zero%20Support');
                            if (await canLaunchUrl(whatsappUrl)) {
                              await launchUrl(whatsappUrl);
                            } else {
                              Clipboard.setData(const ClipboardData(text: phone));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('WhatsApp support number copied: +91 98765 43210'),
                                    backgroundColor: colors.surface,
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Color(0xFF25D366), // WhatsApp Green
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.messageCircle,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Share Pink Circle
                        GestureDetector(
                          onTap: () {
                            const shareUrl = 'https://zerodalali.com/invite/TRADE';
                            Clipboard.setData(const ClipboardData(text: shareUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Referral link copied to clipboard: https://zerodalali.com/invite/TRADE'),
                                backgroundColor: colors.primary,
                              ),
                            );
                          },
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.share2,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Version & Build info
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
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
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
