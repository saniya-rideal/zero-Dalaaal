import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/core/services/push_notification_service.dart';
import 'package:zero_dalali/data/models/notification_item.dart';

void main() {
  group('PushNotificationService Route Resolution & Payload Mapping', () {
    test('resolves standard route aliases correctly', () {
      expect(PushNotificationService.resolveNotificationRoute(null), '/notifications');
      expect(PushNotificationService.resolveNotificationRoute(''), '/notifications');
      expect(PushNotificationService.resolveNotificationRoute('/wallet'), '/funds');
      expect(PushNotificationService.resolveNotificationRoute('/gtt'), '/orders');
      expect(PushNotificationService.resolveNotificationRoute('/orders/ord_12345'), '/order-detail/ord_12345');
      expect(PushNotificationService.resolveNotificationRoute('/support/tickets/tkt_999'), '/help/tickets/tkt_999');
      expect(PushNotificationService.resolveNotificationRoute('/portfolio'), '/portfolio');
      expect(PushNotificationService.resolveNotificationRoute('/alerts'), '/alerts');
      expect(PushNotificationService.resolveNotificationRoute('/sip'), '/sip');
      expect(PushNotificationService.resolveNotificationRoute('/kyc'), '/kyc');
    });

    test('NotificationItem.fromJson parses deepLink from data.route', () {
      final json = {
        'id': 'notif_1',
        'type': 'orderFilled',
        'category': 'orders',
        'title': 'Order Filled',
        'body': 'Your order for RELIANCE has been filled.',
        'data': {
          'route': '/orders/ord_abc123',
        },
      };

      final item = NotificationItem.fromJson(json);
      expect(item.id, 'notif_1');
      expect(item.deepLink, '/orders/ord_abc123');
      expect(item.title, 'Order Filled');
    });
  });
}
