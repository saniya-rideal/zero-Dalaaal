import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/core/theme/app_theme.dart';
import 'package:zero_dalali/core/theme/trading_colors.dart';
import 'package:zero_dalali/features/calendar/presentation/economic_calendar_screen.dart';
import 'package:zero_dalali/shared_widgets/zero_bottom_nav_bar.dart';
import 'package:zero_dalali/shared_widgets/zero_drawer.dart';

void main() {
  group('Dark Mode Visibility & Contrast Test Suite', () {
    test('TradingColors.dark defines high-contrast text and background tokens', () {
      const darkColors = TradingColors.dark;

      // Dark background is deep OLED black
      expect(darkColors.background, const Color(0xFF0B0E14));

      // TextPrimary must be bright high-contrast (#F8FAFC)
      expect(darkColors.textPrimary, const Color(0xFFF8FAFC));

      // TextSecondary must be clear readable slate (#94A3B8)
      expect(darkColors.textSecondary, const Color(0xFF94A3B8));

      // Divider must be subtle but distinct (#2D3748)
      expect(darkColors.divider, const Color(0xFF2D3748));
    });

    testWidgets('ZeroBottomNavBar in Dark Mode renders readable labels with textSecondary',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            bottomNavigationBar: ZeroBottomNavBar(
              currentIndex: 0,
              isExpanded: false,
              onCenterToggle: () {},
              onTabSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // All 4 tabs must be found
      expect(find.text('Quotes'), findsOneWidget);
      expect(find.text('Deals'), findsOneWidget);
      expect(find.text('Net Deals'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);

      // Verify unselected text ('Deals') uses TradingColors.dark.textSecondary, NOT hardcoded pitch black
      final dealsText = tester.widget<Text>(find.text('Deals'));
      expect(dealsText.style?.color, TradingColors.dark.textSecondary);
    });

    testWidgets('ZeroDrawer in Dark Mode renders with high-contrast text and soft primary pill',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              drawer: ZeroDrawer(activeRoute: '/quotes'),
              body: Center(child: Text('Main')),
            ),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Verify drawer items mount
      expect(find.text('Quotes'), findsWidgets);
      expect(find.text('Chart'), findsOneWidget);
      expect(find.text('Deals'), findsOneWidget);
    });

    testWidgets('EconomicCalendarScreen in Dark Mode renders event title and metrics clearly',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const EconomicCalendarScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure the screen and event title mount
      expect(find.text('Economic Calendar'), findsOneWidget);
      expect(find.text('HSBC: SERVICES - BUSINESS ACTIVITY'), findsOneWidget);

      // Verify event title color is textPrimary (#F8FAFC in dark mode)
      final titleWidget = tester.widget<Text>(find.text('HSBC: SERVICES - BUSINESS ACTIVITY'));
      expect(titleWidget.style?.color, TradingColors.dark.textPrimary);
    });
  });
}
