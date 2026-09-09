import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:zero_dalali/data/models/corporate_action.dart';
import 'package:zero_dalali/data/models/enums.dart';
import 'package:zero_dalali/shared_widgets/shared_widgets.dart';

void main() {
  group('Shared Widgets & Components Tests', () {
    testWidgets('TransactionSideBadge renders BUY side in bullish style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionSideBadge(side: TransactionType.BUY),
          ),
        ),
      );

      expect(find.text('BUY'), findsOneWidget);
    });

    testWidgets('TransactionSideBadge renders SELL side in bearish style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionSideBadge(side: TransactionType.SELL),
          ),
        ),
      );

      expect(find.text('SELL'), findsOneWidget);
    });

    testWidgets('ZeroDragHandle renders container handle with given padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ZeroDragHandle(padding: EdgeInsets.all(8)),
          ),
        ),
      );

      expect(find.byType(ZeroDragHandle), findsOneWidget);
    });

    testWidgets('AdaptiveLeadingButton renders menu icon when at root route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: const Drawer(child: Text('DrawerContent')),
            appBar: AppBar(
              leading: const AdaptiveLeadingButton(),
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.menu), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowLeft), findsNothing);

      // Tap drawer icon
      await tester.tap(find.byIcon(LucideIcons.menu));
      await tester.pumpAndSettle();
      expect(find.text('DrawerContent'), findsOneWidget);
    });

    testWidgets('AdaptiveLeadingButton renders back icon when navigator can pop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            leading: const AdaptiveLeadingButton(),
                          ),
                          body: const Text('Detail Page'),
                        ),
                      ),
                    );
                  },
                  child: const Text('Push'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
      expect(find.byIcon(LucideIcons.menu), findsNothing);

      // Tap back button
      await tester.tap(find.byIcon(LucideIcons.arrowLeft));
      await tester.pumpAndSettle();

      expect(find.text('Push'), findsOneWidget);
      expect(find.text('Detail Page'), findsNothing);
    });

    testWidgets('ZeroMarketHeaderStrip mounts news ticker and script selector', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ZeroMarketHeaderStrip(),
            ),
          ),
        ),
      );

      expect(find.byType(ZeroMarketHeaderStrip), findsOneWidget);
      expect(find.byType(NewsTickerStrip), findsOneWidget);
      expect(find.byType(ScriptSelectorBar), findsOneWidget);
    });

    test('CorporateActionType.pluralLabel returns verified plural strings', () {
      expect(CorporateActionType.dividend.pluralLabel, 'Dividends');
      expect(CorporateActionType.split.pluralLabel, 'Splits');
      expect(CorporateActionType.bonus.pluralLabel, 'Bonus');
      expect(CorporateActionType.buyback.pluralLabel, 'Buybacks');
      expect(CorporateActionType.rights.pluralLabel, 'Rights');
    });
  });
}
