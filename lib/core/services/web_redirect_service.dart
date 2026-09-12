import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

class WebRedirectService {
  WebRedirectService._();

  /// Default Deposit Payment Gateway Website URL
  static String depositUrl = '${AppConstants.officialWebsiteUrl}/deposit';

  /// Default Withdrawal Payment Gateway Website URL
  static String withdrawUrl = '${AppConstants.officialWebsiteUrl}/withdraw';

  /// Redirect user to external Deposit website
  static Future<bool> openDepositWebsite({BuildContext? context}) async {
    return openUrl(depositUrl, context: context);
  }

  /// Redirect user to external Withdrawal website
  static Future<bool> openWithdrawWebsite({BuildContext? context}) async {
    return openUrl(withdrawUrl, context: context);
  }

  /// Generic helper to launch any HTTP/HTTPS URL externally
  static Future<bool> openUrl(String urlString, {BuildContext? context}) async {
    final Uri? uri = Uri.tryParse(urlString);
    if (uri == null) return false;

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context != null && context.mounted) {
        _showFallbackSnackBar(context, urlString);
      }
      return launched;
    } catch (e) {
      if (context != null && context.mounted) {
        _showFallbackSnackBar(context, urlString);
      }
      return false;
    }
  }

  static void _showFallbackSnackBar(BuildContext context, String urlString) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Redirecting to website: $urlString'),
        action: SnackBarAction(
          label: 'DISMISS',
          onPressed: () {},
        ),
      ),
    );
  }
}
