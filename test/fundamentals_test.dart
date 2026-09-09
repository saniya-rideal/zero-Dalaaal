import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/data/mock/seed_instruments.dart';
import 'package:zero_dalali/data/mock/stock_fundamentals_repository.dart';
import 'package:zero_dalali/data/models/stock_fundamentals.dart';
import 'package:zero_dalali/features/quote_detail/presentation/quote_detail_screen.dart';

Widget _wrapScreen(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Stock Fundamentals & Financials Unit Tests', () {
    test('Model serialization roundtrip for StockFundamentals', () {
      const ratios = ValuationRatios(
        peRatio: 28.5,
        sectorPe: 24.1,
        pbRatio: 2.4,
        debtToEquity: 0.42,
        roe: 10.2,
        roce: 11.8,
        dividendYield: 0.35,
        marketCap: 2000000.0,
        marketCapCategory: 'Large Cap',
        bookValuePerShare: 1250.0,
        faceValue: 10.0,
        beta: 1.08,
        evToEbitda: 14.2,
      );

      const period = FinancialPeriod(
        period: 'Q1 FY25',
        revenue: 236217.0,
        netProfit: 17448.0,
        ebitda: 42748.0,
        ebitdaMargin: 18.1,
        eps: 25.8,
        yoyRevenueGrowth: 11.5,
        yoyProfitGrowth: 5.2,
      );

      const balanceSheet = BalanceSheetSummary(
        asOfDate: '31 Mar 2024',
        totalAssets: 1800000.0,
        totalLiabilities: 950000.0,
        shareholderEquity: 850000.0,
        totalDebt: 320000.0,
        cashAndEquivalents: 165000.0,
      );

      const cashFlow = CashFlowSummary(
        asOfDate: 'FY 2024',
        operatingCashFlow: 140000.0,
        investingCashFlow: -130000.0,
        financingCashFlow: -8000.0,
        freeCashFlow: 45000.0,
      );

      const shareholding = ShareholdingPattern(
        asOfQuarter: 'June 2026',
        promoterPercent: 50.3,
        promoterPledgedPercent: 0.0,
        fiiPercent: 22.1,
        diiPercent: 16.4,
        publicPercent: 11.2,
        promoterChangeQoq: 0.0,
        fiiChangeQoq: 0.45,
        diiChangeQoq: 0.28,
      );

      const original = StockFundamentals(
        symbol: 'RELIANCE',
        companyName: 'Reliance Industries Ltd',
        sector: 'Energy',
        industry: 'Oil & Gas',
        about: 'Conglomerate operating in energy, retail, telecom.',
        ratios: ratios,
        quarterlyResults: [period],
        annualResults: [period],
        balanceSheet: balanceSheet,
        cashFlow: cashFlow,
        shareholding: shareholding,
      );

      final json = original.toJson();
      final reconstructed = StockFundamentals.fromJson(json);

      expect(reconstructed.symbol, 'RELIANCE');
      expect(reconstructed.ratios.peRatio, 28.5);
      expect(reconstructed.quarterlyResults.first.revenue, 236217.0);
      expect(reconstructed.balanceSheet.totalAssets, 1800000.0);
      expect(reconstructed.cashFlow.freeCashFlow, 45000.0);
      expect(reconstructed.shareholding.promoterPercent, 50.3);
    });

    test('Repository provides curated financials for top Indian stocks', () {
      final repo = StockFundamentalsRepository();

      for (final sym in ['RELIANCE', 'TCS', 'INFY', 'HDFCBANK', 'TATAMOTORS']) {
        final fund = repo.getFundamentals(sym);
        expect(fund.symbol, sym);
        expect(fund.ratios.marketCap, greaterThan(100000.0));
        expect(fund.ratios.peRatio, greaterThan(5.0));
        expect(fund.quarterlyResults.length, 4);
        expect(fund.annualResults.length, greaterThanOrEqualTo(2));
        expect(fund.shareholding.promoterPercent +
            fund.shareholding.fiiPercent +
            fund.shareholding.diiPercent +
            fund.shareholding.publicPercent,
            closeTo(100.0, 1.0));
      }
    });

    test('Repository generates valid procedural fundamentals for arbitrary symbols', () {
      final repo = StockFundamentalsRepository();
      final fund = repo.getFundamentals('WIPRO');

      expect(fund.symbol, 'WIPRO');
      expect(fund.companyName, contains('WIPRO'));
      expect(fund.ratios.peRatio, greaterThan(10.0));
      expect(fund.quarterlyResults, isNotEmpty);
      expect(fund.balanceSheet.totalAssets, greaterThan(0));
      expect(fund.cashFlow.operatingCashFlow, greaterThan(0));
    });
  });

  group('Stock Fundamentals Widget Presentation Tests', () {
    testWidgets('QuoteDetailScreen displays tabs and switches views for Equity', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1000));
      final equityToken = SeedInstruments.equities.first.token;

      await tester.pumpWidget(_wrapScreen(QuoteDetailScreen(token: equityToken)));
      await tester.pumpAndSettle();

      // Check tab pills exist
      expect(find.text('Overview'), findsWidgets);
      expect(find.text('Fundamentals'), findsWidgets);
      expect(find.text('Financials'), findsWidgets);
      expect(find.text('Shareholding'), findsWidgets);

      // 1. Switch to Fundamentals tab
      await tester.tap(find.text('Fundamentals').first);
      await tester.pumpAndSettle();

      expect(find.text('Key Valuation & Performance Ratios'), findsOneWidget);
      expect(find.text('P/E Ratio (TTM)'), findsOneWidget);
      expect(find.text('Price to Book (P/B)'), findsOneWidget);
      expect(find.text('Return on Equity (ROE)'), findsOneWidget);
      expect(find.text('About the Company'), findsOneWidget);

      // 2. Switch to Financials tab
      await tester.tap(find.text('Financials').first);
      await tester.pumpAndSettle();

      expect(find.text('Financial Performance'), findsOneWidget);
      expect(find.text('Quarterly'), findsOneWidget);
      expect(find.text('Annual'), findsOneWidget);
      expect(find.text('Revenue from Operations'), findsWidgets);
      expect(find.text('Net Profit (PAT)'), findsWidgets);

      // 3. Switch to Shareholding tab
      await tester.tap(find.text('Shareholding').first);
      await tester.pumpAndSettle();

      expect(find.text('Shareholding Distribution'), findsOneWidget);
      expect(find.text('Promoters'), findsWidgets);
      expect(find.text('FII'), findsWidgets);
      expect(find.text('DII'), findsWidgets);
      expect(find.text('Public'), findsWidgets);
      expect(find.text('SEBI Minimum Public Shareholding (MPS)'), findsOneWidget);
    });
  });
}
