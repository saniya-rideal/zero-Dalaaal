import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/app/app.dart';

void main() {
  testWidgets('Zero app boots, displays splash brand, and settles',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ZeroApp(),
      ),
    );

    expect(find.text('Zero'), findsOneWidget);

    // Fast-forward through splash timer
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
  });
}
