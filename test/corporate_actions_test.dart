import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/data/models/corporate_action.dart';
import 'package:zero_dalali/features/calendar/data/calendar_repository.dart';
import 'package:zero_dalali/features/calendar/presentation/economic_calendar_screen.dart';
import 'package:zero_dalali/features/calendar/presentation/widgets/corporate_actions_view.dart';
import 'package:zero_dalali/features/quote_detail/data/fundamentals_repository.dart';

final _testActions = [
  CorporateAction(
    id: 'act_vedl',
    symbol: 'VEDL',
    companyName: 'Vedanta Limited',
    actionType: CorporateActionType.dividend,
    details: 'Dividend ₹28.50',
    exDate: DateTime(2026, 10, 20),
    recordDate: DateTime(2026, 10, 21),
    announcementDate: DateTime(2026, 10, 1),
    currentPrice: 432.80,
    dividendYield: 7.2,
    remarks: 'High yield dividend',
  ),
  CorporateAction(
    id: 'act_wipro',
    symbol: 'WIPRO',
    companyName: 'Wipro Limited',
    actionType: CorporateActionType.bonus,
    details: 'Bonus 1:1',
    exDate: DateTime(2026, 10, 25),
    recordDate: DateTime(2026, 10, 26),
    announcementDate: DateTime(2026, 10, 5),
    currentPrice: 540.0,
  ),
  CorporateAction(
    id: 'act_irctc',
    symbol: 'IRCTC',
    companyName: 'Indian Railway Catering and Tourism Corp',
    actionType: CorporateActionType.split,
    details: 'Split 1:5',
    exDate: DateTime(2026, 10, 30),
    recordDate: DateTime(2026, 10, 31),
    announcementDate: DateTime(2026, 10, 10),
    currentPrice: 920.0,
  ),
  CorporateAction(
    id: 'act_tcs',
    symbol: 'TCS',
    companyName: 'Tata Consultancy Services',
    actionType: CorporateActionType.split,
    details: 'Split 1:2',
    exDate: DateTime(2026, 10, 30),
    recordDate: DateTime(2026, 10, 31),
    announcementDate: DateTime(2026, 10, 10),
    currentPrice: 4200.0,
  ),
];

Widget _wrapWidget(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      corporateActionsProvider(null).overrideWith((ref) async => _testActions),
      calendarEventsProvider.overrideWith((ref) async => const []),
      ...overrides,
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Corporate Actions Unit Tests', () {
    test('CorporateAction getters calculate daysUntilExDate and relative time', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final actionInFuture = CorporateAction(
        id: 'test_1',
        symbol: 'TCS',
        companyName: 'Tata Consultancy Services',
        actionType: CorporateActionType.dividend,
        details: 'Dividend ₹28',
        exDate: today.add(const Duration(days: 4)),
        recordDate: today.add(const Duration(days: 5)),
        announcementDate: today.subtract(const Duration(days: 5)),
        currentPrice: 4200,
        dividendYield: 2.5,
      );

      expect(actionInFuture.daysUntilExDate, 4);
      expect(actionInFuture.isExDatePassed, isFalse);
      expect(actionInFuture.relativeTimeDescription, 'In 4 days');

      final actionPast = actionInFuture.copyWith(
        exDate: today.subtract(const Duration(days: 2)),
      );
      expect(actionPast.daysUntilExDate, -2);
      expect(actionPast.isExDatePassed, isTrue);
      expect(actionPast.relativeTimeDescription, '2 days ago');
    });

    test('CorporateAction serialization roundtrip', () {
      final action = CorporateAction(
        id: 'test_vedl',
        symbol: 'VEDL',
        companyName: 'Vedanta Limited',
        actionType: CorporateActionType.dividend,
        details: 'Interim Dividend ₹28.50',
        exDate: DateTime(2026, 9, 15),
        recordDate: DateTime(2026, 9, 16),
        announcementDate: DateTime(2026, 9, 1),
        currentPrice: 432.80,
        dividendYield: 7.2,
        remarks: 'High yield dividend',
      );

      final json = action.toJson();
      final restored = CorporateAction.fromJson(json);

      expect(restored.id, action.id);
      expect(restored.symbol, action.symbol);
      expect(restored.companyName, action.companyName);
      expect(restored.actionType, CorporateActionType.dividend);
      expect(restored.currentPrice, action.currentPrice);
      expect(restored.dividendYield, action.dividendYield);
      expect(restored.remarks, action.remarks);
    });

    test('CorporateActions filtering by type and search query', () {
      final sampleActions = [
        CorporateAction(
          id: '1',
          symbol: 'TCS',
          companyName: 'Tata Consultancy Services',
          actionType: CorporateActionType.dividend,
          details: 'Dividend ₹28',
          exDate: DateTime(2026, 10, 20),
          recordDate: DateTime(2026, 10, 21),
          announcementDate: DateTime(2026, 10, 1),
          currentPrice: 4200,
        ),
        CorporateAction(
          id: '2',
          symbol: 'INFY',
          companyName: 'Infosys Limited',
          actionType: CorporateActionType.split,
          details: 'Split 1:2',
          exDate: DateTime(2026, 10, 22),
          recordDate: DateTime(2026, 10, 23),
          announcementDate: DateTime(2026, 10, 2),
          currentPrice: 1850,
        ),
      ];

      final dividends = sampleActions.where((a) => a.actionType == CorporateActionType.dividend).toList();
      expect(dividends.length, 1);
      expect(dividends.first.symbol, 'TCS');

      final splits = sampleActions.where((a) => a.actionType == CorporateActionType.split).toList();
      expect(splits.length, 1);
      expect(splits.first.symbol, 'INFY');

      final searchTcs = sampleActions.where((a) => a.symbol.contains('TCS') || a.companyName.contains('Tata')).toList();
      expect(searchTcs.length, 1);
    });

    test('CorporateActionsFilterNotifier updates state properly', () {
      final notifier = CorporateActionsFilterNotifier();
      expect(notifier.state.type, isNull);
      expect(notifier.state.searchQuery, '');

      notifier.setType(CorporateActionType.bonus);
      expect(notifier.state.type, CorporateActionType.bonus);

      notifier.setSearchQuery('Reliance');
      expect(notifier.state.searchQuery, 'Reliance');

      notifier.reset();
      expect(notifier.state.type, isNull);
      expect(notifier.state.searchQuery, '');
    });
  });

  group('Corporate Actions Calendar Widget Tests', () {
    testWidgets('EconomicCalendarScreen displays segmented tabs and switches to Corporate Actions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          const EconomicCalendarScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check title and segmented tabs
      expect(find.text('Economic Calendar'), findsOneWidget);
      expect(find.text('Macro Events'), findsOneWidget);
      expect(find.text('Corporate Actions'), findsOneWidget);

      // Initially on Macro Events tab
      expect(find.text('RBI, Fed, CPI, GDP'), findsOneWidget);

      // Tap on Corporate Actions tab
      await tester.tap(find.text('Corporate Actions'));
      await tester.pumpAndSettle();

      // Verify CorporateActionsView is displayed
      expect(find.byType(CorporateActionsView), findsOneWidget);
      expect(find.textContaining('All ('), findsOneWidget);
      expect(find.textContaining('Dividends ('), findsOneWidget);
      expect(find.textContaining('Splits ('), findsOneWidget);
    });

    testWidgets('Filtering by action type updates the displayed list in CorporateActionsView',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          const Scaffold(body: CorporateActionsView()),
        ),
      );
      await tester.pumpAndSettle();

      // Find 'Dividends' chip and tap it
      final divChip = find.textContaining('Dividends (');
      expect(divChip, findsOneWidget);
      await tester.tap(divChip);
      await tester.pumpAndSettle();

      // Verify dividend items are visible (e.g. VEDL)
      expect(find.text('VEDL'), findsOneWidget);
      expect(find.text('Vedanta Limited'), findsOneWidget);

      // Tap 'Splits' chip
      final splitChip = find.textContaining('Splits (');
      expect(splitChip, findsOneWidget);
      await tester.tap(splitChip);
      await tester.pumpAndSettle();

      // Verify stock split items are visible (e.g. IRCTC)
      expect(find.text('IRCTC'), findsOneWidget);
    });

    testWidgets('Search query filters items by symbol or company',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          const Scaffold(body: CorporateActionsView()),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'WIPRO');
      await tester.pumpAndSettle();

      // Verify WIPRO action is shown and others are filtered out
      expect(find.text('Wipro Limited'), findsOneWidget);
      expect(find.text('Vedanta Limited'), findsNothing);
    });

    testWidgets('Tapping a card expands details and displays eligibility info',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          const Scaffold(body: CorporateActionsView()),
        ),
      );
      await tester.pumpAndSettle();

      // Find first card (VEDL) and tap to expand
      final vedlCard = find.text('VEDL');
      expect(vedlCard, findsOneWidget);
      await tester.tap(vedlCard);
      await tester.pumpAndSettle();

      // Verify expanded section contents
      expect(find.text('Record Date'), findsOneWidget);
      expect(find.text('Current CMP'), findsOneWidget);
      expect(find.textContaining('Eligibility: Must hold or buy before Ex-Date'), findsOneWidget);
    });
  });
}
