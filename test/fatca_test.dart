import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/data/mock/fatca_repository.dart';
import 'package:zero_dalali/data/models/fatca_declaration.dart';
import 'package:zero_dalali/features/profile_settings/presentation/fatca_declaration_sheet.dart';
import 'package:zero_dalali/features/profile_settings/presentation/profile_screen.dart';

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

  group('FATCA / CRS & PEP Compliance Unit Tests', () {
    test('Default Indian Resident has verified compliance and proper defaults', () {
      final defaultDecl = FatcaDeclaration.defaultIndianResident();
      expect(defaultDecl.isIndianTaxResidentOnly, isTrue);
      expect(defaultDecl.isUsPerson, isFalse);
      expect(defaultDecl.isPoliticallyExposed, isFalse);
      expect(defaultDecl.isRelatedToPoliticallyExposed, isFalse);
      expect(defaultDecl.birthCountry, 'India');
      expect(defaultDecl.status, 'VERIFIED');
      expect(defaultDecl.taxResidencyCountry, isNull);
      expect(defaultDecl.taxIdentificationNumber, isNull);
    });

    test('FatcaDeclaration serialization roundtrip', () {
      final original = FatcaDeclaration(
        isIndianTaxResidentOnly: false,
        isUsPerson: true,
        isPoliticallyExposed: true,
        isRelatedToPoliticallyExposed: false,
        birthCountry: 'United States',
        birthCity: 'New York',
        taxResidencyCountry: 'United States',
        taxIdentificationNumber: 'SSN-987-65-4321',
        occupation: 'Professional',
        grossAnnualIncomeBracket: '₹10L - ₹25L',
        declarationTimestamp: DateTime(2026, 9, 9, 12, 0),
        status: 'DECLARED',
      );

      final json = original.toJson();
      final restored = FatcaDeclaration.fromJson(json);

      expect(restored.isIndianTaxResidentOnly, isFalse);
      expect(restored.isUsPerson, isTrue);
      expect(restored.isPoliticallyExposed, isTrue);
      expect(restored.isRelatedToPoliticallyExposed, isFalse);
      expect(restored.birthCountry, 'United States');
      expect(restored.birthCity, 'New York');
      expect(restored.taxResidencyCountry, 'United States');
      expect(restored.taxIdentificationNumber, 'SSN-987-65-4321');
      expect(restored.occupation, 'Professional');
      expect(restored.grossAnnualIncomeBracket, '₹10L - ₹25L');
      expect(restored.status, 'DECLARED');
      expect(restored.declarationTimestamp, original.declarationTimestamp);
    });

    test('FatcaDeclaration copyWith updates targeted fields', () {
      final original = FatcaDeclaration.defaultIndianResident();
      final updated = original.copyWith(
        isPoliticallyExposed: true,
        status: 'DECLARED',
        occupation: 'Business / Self-Employed',
      );

      expect(updated.isPoliticallyExposed, isTrue);
      expect(updated.status, 'DECLARED');
      expect(updated.occupation, 'Business / Self-Employed');
      expect(updated.birthCountry, original.birthCountry);
      expect(updated.isIndianTaxResidentOnly, original.isIndianTaxResidentOnly);
    });

    test('FatcaRepository and Notifier state mutation and isComplied', () {
      final repo = FatcaRepository();
      expect(repo.isComplied, isTrue);

      final custom = repo.declaration.copyWith(status: 'PENDING');
      repo.updateDeclaration(custom);
      expect(repo.isComplied, isFalse);

      final declared = custom.copyWith(status: 'DECLARED');
      repo.updateDeclaration(declared);
      expect(repo.isComplied, isTrue);
    });
  });

  group('FATCA / CRS & PEP Declaration Widget Tests', () {
    testWidgets('FatcaDeclarationSheet renders all statutory sections',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FatcaDeclarationSheet.show(context),
              child: const Text('Open FATCA'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open FATCA'));
      await tester.pumpAndSettle();

      // Check header and status
      expect(find.text('FATCA / CRS & PEP Declaration'), findsOneWidget);
      expect(find.textContaining('Status: VERIFIED (Complied)'), findsOneWidget);

      // Check sections
      expect(find.text('1. Tax Residency Declaration'), findsOneWidget);
      expect(find.text('2. US Person Status'), findsOneWidget);
      expect(find.text('3. Politically Exposed Person (PEP)'), findsOneWidget);
      expect(find.text('4. Personal & Financial Profile'), findsOneWidget);
      expect(find.text('Confirm & Update FATCA Declaration'), findsOneWidget);
    });

    testWidgets('Selecting NO for Indian Tax Residency reveals foreign tax fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FatcaDeclarationSheet.show(context),
              child: const Text('Open FATCA'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open FATCA'));
      await tester.pumpAndSettle();

      // Initially, foreign tax fields should not be visible
      expect(find.text('Foreign Tax Details (CRS Mandate)'), findsNothing);

      // Find the NO chip for Tax residency (first NO chip)
      final noChips = find.text('NO');
      expect(noChips, findsWidgets);
      await tester.tap(noChips.first);
      await tester.pumpAndSettle();

      // Now foreign tax inputs should appear
      expect(find.text('Foreign Tax Details (CRS Mandate)'), findsOneWidget);
      expect(find.text('Country of Tax Residency'), findsOneWidget);
      expect(find.text('Tax Identification Number (TIN / SSN)'), findsOneWidget);
    });

    testWidgets('ProfileScreen shows FATCA menu item with COMPLIED badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify FATCA menu item
      expect(find.text('FATCA / CRS & PEP Declaration'), findsOneWidget);
      expect(find.text('COMPLIED'), findsOneWidget);
      expect(find.text('Tax residency (IT Rules 114F–114H)'), findsOneWidget);
    });
  });
}
