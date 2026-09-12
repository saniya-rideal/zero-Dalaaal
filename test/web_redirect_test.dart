import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/core/constants/app_constants.dart';
import 'package:zero_dalali/core/services/web_redirect_service.dart';

void main() {
  group('WebRedirectService Tests', () {
    test('Default deposit and withdraw URLs match AppConstants domain', () {
      expect(WebRedirectService.depositUrl, contains(AppConstants.officialWebsiteUrl));
      expect(WebRedirectService.depositUrl, contains('/deposit'));

      expect(WebRedirectService.withdrawUrl, contains(AppConstants.officialWebsiteUrl));
      expect(WebRedirectService.withdrawUrl, contains('/withdraw'));
    });

    test('Custom deposit and withdraw URLs can be configured', () {
      WebRedirectService.depositUrl = 'https://custom-gateway.com/pay';
      WebRedirectService.withdrawUrl = 'https://custom-gateway.com/payout';

      expect(WebRedirectService.depositUrl, equals('https://custom-gateway.com/pay'));
      expect(WebRedirectService.withdrawUrl, equals('https://custom-gateway.com/payout'));

      // Restore defaults
      WebRedirectService.depositUrl = '${AppConstants.officialWebsiteUrl}/deposit';
      WebRedirectService.withdrawUrl = '${AppConstants.officialWebsiteUrl}/withdraw';
    });

    test('openUrl validates URI parsing correctly', () async {
      final invalidResult = await WebRedirectService.openUrl('');
      expect(invalidResult, isFalse);
    });
  });
}
