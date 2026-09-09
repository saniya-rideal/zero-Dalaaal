import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/data/mock/risk_profile_repository.dart';
import 'package:zero_dalali/data/models/investor_risk_profile.dart';
import 'package:zero_dalali/features/profile_settings/presentation/profile_screen.dart';
import 'package:zero_dalali/features/profile_settings/presentation/risk_profile_sheet.dart';

Widget _wrapWidget(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SEBI Investor Risk Profiling Unit Tests', () {
    test('Default profile has Moderate category and 17 points', () {
      final profile = InvestorRiskProfile.defaultModerate();
      expect(profile.category, RiskCategory.moderate);
      expect(profile.score, 17);
      expect(profile.isFnoSuitable, isTrue);
      expect(profile.answers.length, 5);
      expect(profile.category.label, 'Moderate');
      expect(profile.category.badgeText, 'BALANCED');
    });

    test('Score classification boundaries: Conservative, Moderate, Aggressive', () {
      expect(InvestorRiskProfile.determineCategory(5), RiskCategory.conservative);
      expect(InvestorRiskProfile.determineCategory(10), RiskCategory.conservative);
      expect(InvestorRiskProfile.determineCategory(11), RiskCategory.moderate);
      expect(InvestorRiskProfile.determineCategory(18), RiskCategory.moderate);
      expect(InvestorRiskProfile.determineCategory(19), RiskCategory.aggressive);
      expect(InvestorRiskProfile.determineCategory(25), RiskCategory.aggressive);
    });

    test('Conservative answers result in conservative profile and F&O caution', () {
      // Pick lowest points for all questions (options with 1 pt each)
      final lowAnswers = <int, int>{
        1: 3, // >60 (1 pt)
        2: 0, // Capital protection (1 pt)
        3: 0, // Beginner (1 pt)
        4: 0, // Panic & sell (1 pt)
        5: 0, // <10% (2 pts)
      };
      // Total = 1 + 1 + 1 + 1 + 2 = 6 points
      final profile = InvestorRiskProfile.fromAnswers(lowAnswers);
      expect(profile.score, 6);
      expect(profile.category, RiskCategory.conservative);
      expect(profile.isFnoSuitable, isFalse);
      expect(profile.suitabilityAdvisory, contains('Conservative risk tolerance'));
    });

    test('Aggressive answers result in aggressive profile and F&O eligibility', () {
      // Pick highest points for all questions (options with 5 pts each)
      final highAnswers = <int, int>{
        1: 0, // <30 (5 pts)
        2: 2, // Aggressive wealth (5 pts)
        3: 2, // Experienced (5 pts)
        4: 2, // Buy more (5 pts)
        5: 2, // >30% (5 pts)
      };
      // Total = 5 * 5 = 25 points
      final profile = InvestorRiskProfile.fromAnswers(highAnswers);
      expect(profile.score, 25);
      expect(profile.category, RiskCategory.aggressive);
      expect(profile.isFnoSuitable, isTrue);
      expect(profile.suitabilityAdvisory, contains('Suitability Verified'));
    });

    test('InvestorRiskProfile serialization roundtrip', () {
      final original = InvestorRiskProfile.defaultModerate();
      final json = original.toJson();
      final restored = InvestorRiskProfile.fromJson(json);

      expect(restored.category, original.category);
      expect(restored.score, original.score);
      expect(restored.isFnoSuitable, original.isFnoSuitable);
      expect(restored.suitabilityAdvisory, original.suitabilityAdvisory);
      expect(restored.answers.length, original.answers.length);
    });

    test('InvestorRiskProfile copyWith updates fields correctly', () {
      final original = InvestorRiskProfile.defaultModerate();
      final updated = original.copyWith(
        category: RiskCategory.aggressive,
        score: 22,
        isFnoSuitable: true,
      );

      expect(updated.category, RiskCategory.aggressive);
      expect(updated.score, 22);
      expect(updated.isFnoSuitable, isTrue);
      expect(updated.answers, original.answers);
    });

    test('RiskProfileRepository and Notifier handle state mutation', () {
      final repo = RiskProfileRepository();
      expect(repo.profile.category, RiskCategory.moderate);

      final notifier = RiskProfileNotifier(repo);
      notifier.submitAnswers({
        1: 0, 2: 2, 3: 2, 4: 2, 5: 2,
      });

      expect(notifier.state.category, RiskCategory.aggressive);
      expect(repo.profile.category, RiskCategory.aggressive);
    });
  });

  group('SEBI Investor Risk Profiling Widget Tests', () {
    testWidgets('RiskProfileSheet renders Overview mode with current category and score',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => RiskProfileSheet.show(context),
              child: const Text('Open Risk Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Risk Sheet'));
      await tester.pumpAndSettle();

      // Check header and titles
      expect(find.text('SEBI Investor Risk Profile'), findsOneWidget);
      expect(find.text('Moderate'), findsWidgets);
      expect(find.text('BALANCED'), findsOneWidget);
      expect(find.text('Assessed Score: 17 / 25 points'), findsOneWidget);
      expect(find.text('Risk Tolerance Meter'), findsOneWidget);
      expect(find.text('Retake Risk Assessment Questionnaire'), findsOneWidget);
    });

    testWidgets('Tapping Retake starts interactive 5-question stepper',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => RiskProfileSheet.show(context),
              child: const Text('Open Risk Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Risk Sheet'));
      await tester.pumpAndSettle();

      // Tap Retake
      final retakeBtn = find.text('Retake Risk Assessment Questionnaire');
      await tester.ensureVisible(retakeBtn);
      await tester.pumpAndSettle();
      await tester.tap(retakeBtn);
      await tester.pumpAndSettle();

      // Verify Quiz view is active
      expect(find.text('Question 1 of 5'), findsOneWidget);
      expect(find.text('What is your current age bracket?'), findsOneWidget);
      expect(find.text('Next Question'), findsOneWidget);
    });

    testWidgets('ProfileScreen displays Investor Risk Profile menu item and badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Investor Risk Profile'), findsOneWidget);
      expect(find.text('MODERATE'), findsOneWidget);
      expect(find.text('SEBI suitability & risk tolerance assessment'), findsOneWidget);
    });
  });
}
