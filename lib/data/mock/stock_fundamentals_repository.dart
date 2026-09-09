import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_fundamentals.dart';

final stockFundamentalsRepositoryProvider =
    Provider<StockFundamentalsRepository>((ref) {
  return StockFundamentalsRepository();
});

final stockFundamentalsProvider =
    Provider.family<StockFundamentals, String>((ref, symbol) {
  final repo = ref.watch(stockFundamentalsRepositoryProvider);
  return repo.getFundamentals(symbol);
});

class StockFundamentalsRepository {
  final Map<String, StockFundamentals> _curatedFundamentals = {
    // 1. Reliance Industries Ltd
    'RELIANCE': const StockFundamentals(
      symbol: 'RELIANCE',
      companyName: 'Reliance Industries Ltd',
      sector: 'Energy & Conglomerate',
      industry: 'Oil, Gas & Consumables, Telecom & Retail',
      about:
          'Reliance Industries Limited is an Indian multinational conglomerate headquartered in Mumbai. Its diverse businesses include energy, petrochemicals, natural gas, retail, telecommunications (Jio), and digital services.',
      ratios: ValuationRatios(
        peRatio: 28.45,
        sectorPe: 24.10,
        pbRatio: 2.38,
        debtToEquity: 0.42,
        roe: 10.25,
        roce: 11.80,
        dividendYield: 0.35,
        marketCap: 2015400.0,
        marketCapCategory: 'Large Cap',
        bookValuePerShare: 1256.40,
        faceValue: 10.0,
        beta: 1.08,
        evToEbitda: 14.20,
      ),
      quarterlyResults: [
        FinancialPeriod(
          period: 'Q1 FY25',
          revenue: 236217.0,
          netProfit: 17448.0,
          ebitda: 42748.0,
          ebitdaMargin: 18.10,
          eps: 25.80,
          yoyRevenueGrowth: 11.50,
          yoyProfitGrowth: 5.20,
        ),
        FinancialPeriod(
          period: 'Q4 FY24',
          revenue: 240715.0,
          netProfit: 18951.0,
          ebitda: 47150.0,
          ebitdaMargin: 19.58,
          eps: 28.02,
          yoyRevenueGrowth: 10.80,
          yoyProfitGrowth: 1.80,
        ),
        FinancialPeriod(
          period: 'Q3 FY24',
          revenue: 228080.0,
          netProfit: 17265.0,
          ebitda: 44678.0,
          ebitdaMargin: 19.59,
          eps: 25.53,
          yoyRevenueGrowth: 3.50,
          yoyProfitGrowth: 9.30,
        ),
        FinancialPeriod(
          period: 'Q2 FY24',
          revenue: 234956.0,
          netProfit: 17394.0,
          ebitda: 44867.0,
          ebitdaMargin: 19.10,
          eps: 25.72,
          yoyRevenueGrowth: 1.20,
          yoyProfitGrowth: 27.40,
        ),
      ],
      annualResults: [
        FinancialPeriod(
          period: 'FY 2024',
          revenue: 914472.0,
          netProfit: 69621.0,
          ebitda: 178677.0,
          ebitdaMargin: 19.54,
          eps: 102.80,
          yoyRevenueGrowth: 2.60,
          yoyProfitGrowth: 4.40,
        ),
        FinancialPeriod(
          period: 'FY 2023',
          revenue: 891311.0,
          netProfit: 66702.0,
          ebitda: 154690.0,
          ebitdaMargin: 17.35,
          eps: 98.60,
          yoyRevenueGrowth: 23.40,
          yoyProfitGrowth: 14.10,
        ),
        FinancialPeriod(
          period: 'FY 2022',
          revenue: 721634.0,
          netProfit: 58426.0,
          ebitda: 125687.0,
          ebitdaMargin: 17.42,
          eps: 86.40,
          yoyRevenueGrowth: 47.00,
          yoyProfitGrowth: 26.20,
        ),
      ],
      balanceSheet: BalanceSheetSummary(
        asOfDate: '31 Mar 2024',
        totalAssets: 1812540.0,
        totalLiabilities: 961540.0,
        shareholderEquity: 851000.0,
        totalDebt: 324500.0,
        cashAndEquivalents: 168240.0,
      ),
      cashFlow: CashFlowSummary(
        asOfDate: 'FY 2024',
        operatingCashFlow: 143200.0,
        investingCashFlow: -131800.0,
        financingCashFlow: -8400.0,
        freeCashFlow: 48500.0,
      ),
      shareholding: ShareholdingPattern(
        asOfQuarter: 'June 2026',
        promoterPercent: 50.31,
        promoterPledgedPercent: 0.00,
        fiiPercent: 22.15,
        diiPercent: 16.42,
        publicPercent: 11.12,
        promoterChangeQoq: 0.00,
        fiiChangeQoq: 0.45,
        diiChangeQoq: 0.28,
      ),
    ),

    // 2. Tata Consultancy Services Ltd
    'TCS': const StockFundamentals(
      symbol: 'TCS',
      companyName: 'Tata Consultancy Services Ltd',
      sector: 'Information Technology',
      industry: 'IT Services & Consulting',
      about:
          'Tata Consultancy Services is an Indian multinational IT services and consulting company headquartered in Mumbai. Part of the Tata Group, TCS operates in 150+ locations across 50+ countries with world-class margins.',
      ratios: ValuationRatios(
        peRatio: 32.10,
        sectorPe: 30.80,
        pbRatio: 15.80,
        debtToEquity: 0.00,
        roe: 48.50,
        roce: 61.20,
        dividendYield: 1.25,
        marketCap: 1542000.0,
        marketCapCategory: 'Large Cap',
        bookValuePerShare: 268.50,
        faceValue: 1.0,
        beta: 0.72,
        evToEbitda: 22.40,
      ),
      quarterlyResults: [
        FinancialPeriod(
          period: 'Q1 FY25',
          revenue: 62613.0,
          netProfit: 12040.0,
          ebitda: 16850.0,
          ebitdaMargin: 26.91,
          eps: 33.28,
          yoyRevenueGrowth: 5.40,
          yoyProfitGrowth: 8.70,
        ),
        FinancialPeriod(
          period: 'Q4 FY24',
          revenue: 61237.0,
          netProfit: 12434.0,
          ebitda: 17200.0,
          ebitdaMargin: 28.08,
          eps: 34.37,
          yoyRevenueGrowth: 3.50,
          yoyProfitGrowth: 9.10,
        ),
        FinancialPeriod(
          period: 'Q3 FY24',
          revenue: 60583.0,
          netProfit: 11058.0,
          ebitda: 16250.0,
          ebitdaMargin: 26.82,
          eps: 30.56,
          yoyRevenueGrowth: 4.00,
          yoyProfitGrowth: 2.00,
        ),
        FinancialPeriod(
          period: 'Q2 FY24',
          revenue: 59692.0,
          netProfit: 11342.0,
          ebitda: 16300.0,
          ebitdaMargin: 27.30,
          eps: 31.35,
          yoyRevenueGrowth: 7.90,
          yoyProfitGrowth: 8.70,
        ),
      ],
      annualResults: [
        FinancialPeriod(
          period: 'FY 2024',
          revenue: 240893.0,
          netProfit: 45908.0,
          ebitda: 65120.0,
          ebitdaMargin: 27.03,
          eps: 126.90,
          yoyRevenueGrowth: 6.80,
          yoyProfitGrowth: 8.90,
        ),
        FinancialPeriod(
          period: 'FY 2023',
          revenue: 225458.0,
          netProfit: 42147.0,
          ebitda: 59260.0,
          ebitdaMargin: 26.28,
          eps: 115.20,
          yoyRevenueGrowth: 17.60,
          yoyProfitGrowth: 10.00,
        ),
        FinancialPeriod(
          period: 'FY 2022',
          revenue: 191754.0,
          netProfit: 38327.0,
          ebitda: 53057.0,
          ebitdaMargin: 27.67,
          eps: 103.60,
          yoyRevenueGrowth: 16.80,
          yoyProfitGrowth: 14.80,
        ),
      ],
      balanceSheet: BalanceSheetSummary(
        asOfDate: '31 Mar 2024',
        totalAssets: 142850.0,
        totalLiabilities: 45200.0,
        shareholderEquity: 97650.0,
        totalDebt: 0.0,
        cashAndEquivalents: 41250.0,
      ),
      cashFlow: CashFlowSummary(
        asOfDate: 'FY 2024',
        operatingCashFlow: 44300.0,
        investingCashFlow: -3800.0,
        financingCashFlow: -39500.0,
        freeCashFlow: 39800.0,
      ),
      shareholding: ShareholdingPattern(
        asOfQuarter: 'June 2026',
        promoterPercent: 71.77,
        promoterPledgedPercent: 0.00,
        fiiPercent: 12.46,
        diiPercent: 10.22,
        publicPercent: 5.55,
        promoterChangeQoq: -0.10,
        fiiChangeQoq: 0.15,
        diiChangeQoq: 0.20,
      ),
    ),

    // 3. Infosys Ltd
    'INFY': const StockFundamentals(
      symbol: 'INFY',
      companyName: 'Infosys Ltd',
      sector: 'Information Technology',
      industry: 'IT Services & Consulting',
      about:
          'Infosys is a global leader in next-generation digital services and consulting. It enables clients in more than 56 countries to navigate their digital transformation, powered by Cloud and AI-first solutions.',
      ratios: ValuationRatios(
        peRatio: 27.60,
        sectorPe: 30.80,
        pbRatio: 9.15,
        debtToEquity: 0.08,
        roe: 31.40,
        roce: 40.20,
        dividendYield: 2.10,
        marketCap: 782400.0,
        marketCapCategory: 'Large Cap',
        bookValuePerShare: 206.80,
        faceValue: 5.0,
        beta: 0.85,
        evToEbitda: 19.10,
      ),
      quarterlyResults: [
        FinancialPeriod(
          period: 'Q1 FY25',
          revenue: 39315.0,
          netProfit: 6368.0,
          ebitda: 9280.0,
          ebitdaMargin: 23.60,
          eps: 15.35,
          yoyRevenueGrowth: 3.60,
          yoyProfitGrowth: 7.10,
        ),
        FinancialPeriod(
          period: 'Q4 FY24',
          revenue: 37923.0,
          netProfit: 7969.0,
          ebitda: 8950.0,
          ebitdaMargin: 23.60,
          eps: 19.21,
          yoyRevenueGrowth: -2.30,
          yoyProfitGrowth: 30.00,
        ),
        FinancialPeriod(
          period: 'Q3 FY24',
          revenue: 38821.0,
          netProfit: 6106.0,
          ebitda: 8910.0,
          ebitdaMargin: 22.95,
          eps: 14.72,
          yoyRevenueGrowth: -0.40,
          yoyProfitGrowth: -7.30,
        ),
        FinancialPeriod(
          period: 'Q2 FY24',
          revenue: 38994.0,
          netProfit: 6212.0,
          ebitda: 9120.0,
          ebitdaMargin: 23.39,
          eps: 14.98,
          yoyRevenueGrowth: 6.70,
          yoyProfitGrowth: 3.20,
        ),
      ],
      annualResults: [
        FinancialPeriod(
          period: 'FY 2024',
          revenue: 153670.0,
          netProfit: 26233.0,
          ebitda: 36840.0,
          ebitdaMargin: 23.97,
          eps: 63.20,
          yoyRevenueGrowth: 4.70,
          yoyProfitGrowth: 8.90,
        ),
        FinancialPeriod(
          period: 'FY 2023',
          revenue: 146767.0,
          netProfit: 24095.0,
          ebitda: 35130.0,
          ebitdaMargin: 23.94,
          eps: 57.60,
          yoyRevenueGrowth: 20.70,
          yoyProfitGrowth: 9.00,
        ),
        FinancialPeriod(
          period: 'FY 2022',
          revenue: 121641.0,
          netProfit: 22110.0,
          ebitda: 31491.0,
          ebitdaMargin: 25.89,
          eps: 52.40,
          yoyRevenueGrowth: 21.10,
          yoyProfitGrowth: 14.30,
        ),
      ],
      balanceSheet: BalanceSheetSummary(
        asOfDate: '31 Mar 2024',
        totalAssets: 126400.0,
        totalLiabilities: 39800.0,
        shareholderEquity: 86600.0,
        totalDebt: 6800.0,
        cashAndEquivalents: 21500.0,
      ),
      cashFlow: CashFlowSummary(
        asOfDate: 'FY 2024',
        operatingCashFlow: 23400.0,
        investingCashFlow: -2800.0,
        financingCashFlow: -18900.0,
        freeCashFlow: 20200.0,
      ),
      shareholding: ShareholdingPattern(
        asOfQuarter: 'June 2026',
        promoterPercent: 14.65,
        promoterPledgedPercent: 0.00,
        fiiPercent: 34.18,
        diiPercent: 35.12,
        publicPercent: 16.05,
        promoterChangeQoq: 0.00,
        fiiChangeQoq: 0.85,
        diiChangeQoq: 0.12,
      ),
    ),

    // 4. HDFC Bank Ltd
    'HDFCBANK': const StockFundamentals(
      symbol: 'HDFCBANK',
      companyName: 'HDFC Bank Ltd',
      sector: 'Financial Services',
      industry: 'Private Sector Bank',
      about:
          'HDFC Bank is India’s largest private sector bank by assets and market capitalization. Following its landmark merger with parent HDFC Ltd, it provides a comprehensive suite of banking, credit card, and mortgage solutions.',
      ratios: ValuationRatios(
        peRatio: 19.20,
        sectorPe: 18.50,
        pbRatio: 2.85,
        debtToEquity: 1.15,
        roe: 16.80,
        roce: 18.20,
        dividendYield: 1.15,
        marketCap: 1260400.0,
        marketCapCategory: 'Large Cap',
        bookValuePerShare: 580.40,
        faceValue: 1.0,
        beta: 0.98,
        evToEbitda: 15.60,
      ),
      quarterlyResults: [
        FinancialPeriod(
          period: 'Q1 FY25',
          revenue: 83701.0,
          netProfit: 16175.0,
          ebitda: 31200.0,
          ebitdaMargin: 37.28,
          eps: 21.28,
          yoyRevenueGrowth: 44.80,
          yoyProfitGrowth: 35.30,
        ),
        FinancialPeriod(
          period: 'Q4 FY24',
          revenue: 80707.0,
          netProfit: 16512.0,
          ebitda: 30800.0,
          ebitdaMargin: 38.16,
          eps: 21.72,
          yoyRevenueGrowth: 51.20,
          yoyProfitGrowth: 37.10,
        ),
        FinancialPeriod(
          period: 'Q3 FY24',
          revenue: 78008.0,
          netProfit: 16372.0,
          ebitda: 29900.0,
          ebitdaMargin: 38.33,
          eps: 21.54,
          yoyRevenueGrowth: 49.60,
          yoyProfitGrowth: 33.50,
        ),
        FinancialPeriod(
          period: 'Q2 FY24',
          revenue: 66317.0,
          netProfit: 15976.0,
          ebitda: 27800.0,
          ebitdaMargin: 41.92,
          eps: 21.02,
          yoyRevenueGrowth: 42.10,
          yoyProfitGrowth: 50.60,
        ),
      ],
      annualResults: [
        FinancialPeriod(
          period: 'FY 2024',
          revenue: 285400.0,
          netProfit: 60810.0,
          ebitda: 119700.0,
          ebitdaMargin: 41.94,
          eps: 80.00,
          yoyRevenueGrowth: 68.20,
          yoyProfitGrowth: 37.90,
        ),
        FinancialPeriod(
          period: 'FY 2023',
          revenue: 169700.0,
          netProfit: 44110.0,
          ebitda: 71200.0,
          ebitdaMargin: 41.96,
          eps: 79.30,
          yoyRevenueGrowth: 30.90,
          yoyProfitGrowth: 19.30,
        ),
        FinancialPeriod(
          period: 'FY 2022',
          revenue: 127680.0,
          netProfit: 36961.0,
          ebitda: 58900.0,
          ebitdaMargin: 46.13,
          eps: 66.80,
          yoyRevenueGrowth: 6.80,
          yoyProfitGrowth: 18.80,
        ),
      ],
      balanceSheet: BalanceSheetSummary(
        asOfDate: '31 Mar 2024',
        totalAssets: 3617640.0,
        totalLiabilities: 3177640.0,
        shareholderEquity: 440000.0,
        totalDebt: 720000.0,
        cashAndEquivalents: 245000.0,
      ),
      cashFlow: CashFlowSummary(
        asOfDate: 'FY 2024',
        operatingCashFlow: 82500.0,
        investingCashFlow: -12400.0,
        financingCashFlow: -28100.0,
        freeCashFlow: 76200.0,
      ),
      shareholding: ShareholdingPattern(
        asOfQuarter: 'June 2026',
        promoterPercent: 0.00, // Post-merger institutional held
        promoterPledgedPercent: 0.00,
        fiiPercent: 47.18,
        diiPercent: 33.42,
        publicPercent: 19.40,
        promoterChangeQoq: 0.00,
        fiiChangeQoq: -0.65,
        diiChangeQoq: 1.10,
      ),
    ),

    // 5. Tata Motors Ltd
    'TATAMOTORS': const StockFundamentals(
      symbol: 'TATAMOTORS',
      companyName: 'Tata Motors Ltd',
      sector: 'Automobile',
      industry: 'Commercial Vehicles, Passenger Cars & EVs',
      about:
          'Tata Motors Group is a 42-billion-dollar global automobile manufacturer. Its portfolio includes cars, sports utility vehicles, trucks, buses, defense vehicles, and British luxury carmaker Jaguar Land Rover.',
      ratios: ValuationRatios(
        peRatio: 11.40,
        sectorPe: 22.80,
        pbRatio: 3.42,
        debtToEquity: 0.65,
        roe: 34.20,
        roce: 22.10,
        dividendYield: 0.65,
        marketCap: 382400.0,
        marketCapCategory: 'Large Cap',
        bookValuePerShare: 284.20,
        faceValue: 2.0,
        beta: 1.34,
        evToEbitda: 5.80,
      ),
      quarterlyResults: [
        FinancialPeriod(
          period: 'Q1 FY25',
          revenue: 108048.0,
          netProfit: 5566.0,
          ebitda: 15780.0,
          ebitdaMargin: 14.60,
          eps: 14.53,
          yoyRevenueGrowth: 5.70,
          yoyProfitGrowth: 73.80,
        ),
        FinancialPeriod(
          period: 'Q4 FY24',
          revenue: 119986.0,
          netProfit: 17407.0,
          ebitda: 17900.0,
          ebitdaMargin: 14.92,
          eps: 45.44,
          yoyRevenueGrowth: 13.30,
          yoyProfitGrowth: 218.00,
        ),
        FinancialPeriod(
          period: 'Q3 FY24',
          revenue: 110577.0,
          netProfit: 7025.0,
          ebitda: 15800.0,
          ebitdaMargin: 14.29,
          eps: 18.34,
          yoyRevenueGrowth: 24.90,
          yoyProfitGrowth: 137.50,
        ),
        FinancialPeriod(
          period: 'Q2 FY24',
          revenue: 105128.0,
          netProfit: 3764.0,
          ebitda: 14400.0,
          ebitdaMargin: 13.70,
          eps: 9.82,
          yoyRevenueGrowth: 32.10,
          yoyProfitGrowth: 275.00,
        ),
      ],
      annualResults: [
        FinancialPeriod(
          period: 'FY 2024',
          revenue: 437928.0,
          netProfit: 31807.0,
          ebitda: 62800.0,
          ebitdaMargin: 14.34,
          eps: 83.00,
          yoyRevenueGrowth: 26.60,
          yoyProfitGrowth: 1180.00,
        ),
        FinancialPeriod(
          period: 'FY 2023',
          revenue: 345967.0,
          netProfit: 2414.0,
          ebitda: 37000.0,
          ebitdaMargin: 10.70,
          eps: 6.30,
          yoyRevenueGrowth: 24.20,
          yoyProfitGrowth: 121.00,
        ),
        FinancialPeriod(
          period: 'FY 2022',
          revenue: 278454.0,
          netProfit: -11441.0,
          ebitda: 24800.0,
          ebitdaMargin: 8.91,
          eps: -29.80,
          yoyRevenueGrowth: 11.50,
          yoyProfitGrowth: 15.00,
        ),
      ],
      balanceSheet: BalanceSheetSummary(
        asOfDate: '31 Mar 2024',
        totalAssets: 358200.0,
        totalLiabilities: 268400.0,
        shareholderEquity: 89800.0,
        totalDebt: 58200.0,
        cashAndEquivalents: 42100.0,
      ),
      cashFlow: CashFlowSummary(
        asOfDate: 'FY 2024',
        operatingCashFlow: 48900.0,
        investingCashFlow: -24100.0,
        financingCashFlow: -12800.0,
        freeCashFlow: 26800.0,
      ),
      shareholding: ShareholdingPattern(
        asOfQuarter: 'June 2026',
        promoterPercent: 46.36,
        promoterPledgedPercent: 1.15,
        fiiPercent: 19.20,
        diiPercent: 15.82,
        publicPercent: 18.62,
        promoterChangeQoq: 0.00,
        fiiChangeQoq: 0.60,
        diiChangeQoq: -0.15,
      ),
    ),
  };

  /// Returns fundamentals for a given symbol or generates a consistent procedural dataset.
  StockFundamentals getFundamentals(String symbol) {
    final cleanSymbol = symbol
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('NSE:', '')
        .replaceAll('BSE:', '')
        .replaceAll('EQ_', '')
        .replaceAll('_EQ', '');

    if (_curatedFundamentals.containsKey(cleanSymbol)) {
      return _curatedFundamentals[cleanSymbol]!;
    }

    // Procedural Fallback generator
    final hash = cleanSymbol.codeUnits.fold<int>(0, (p, c) => p + c);
    final pe = 18.0 + (hash % 25);
    final roe = 12.0 + (hash % 18);
    final pb = 1.8 + (hash % 8) * 0.5;
    final mcap = 25000.0 + (hash % 150) * 1000.0;
    final divYield = 0.5 + (hash % 5) * 0.4;
    final promoter = 45.0 + (hash % 25);
    final fii = 15.0 + (hash % 15);
    final dii = 12.0 + (hash % 12);
    final publicPct = (100.0 - promoter - fii - dii).clamp(5.0, 35.0);

    return StockFundamentals(
      symbol: cleanSymbol,
      companyName: '$cleanSymbol Corporation Ltd',
      sector: _inferSector(cleanSymbol),
      industry: 'Diversified Operations',
      about:
          '$cleanSymbol is a prominent NSE-listed corporation operating across key growth verticals in India with consistent operational cash flows and competitive market positioning.',
      ratios: ValuationRatios(
        peRatio: double.parse(pe.toStringAsFixed(2)),
        sectorPe: 22.50,
        pbRatio: double.parse(pb.toStringAsFixed(2)),
        debtToEquity: 0.35,
        roe: double.parse(roe.toStringAsFixed(2)),
        roce: double.parse((roe * 1.2).toStringAsFixed(2)),
        dividendYield: double.parse(divYield.toStringAsFixed(2)),
        marketCap: mcap,
        marketCapCategory: mcap > 50000.0 ? 'Large Cap' : 'Mid Cap',
        bookValuePerShare: 240.0 + (hash % 200),
        faceValue: (hash % 2 == 0) ? 1.0 : 10.0,
        beta: 1.02,
        evToEbitda: 12.80,
      ),
      quarterlyResults: [
        FinancialPeriod(
          period: 'Q1 FY25',
          revenue: mcap * 0.12,
          netProfit: mcap * 0.015,
          ebitda: mcap * 0.025,
          ebitdaMargin: 20.83,
          eps: 18.40,
          yoyRevenueGrowth: 8.5,
          yoyProfitGrowth: 11.2,
        ),
        FinancialPeriod(
          period: 'Q4 FY24',
          revenue: mcap * 0.118,
          netProfit: mcap * 0.014,
          ebitda: mcap * 0.024,
          ebitdaMargin: 20.34,
          eps: 17.80,
          yoyRevenueGrowth: 7.2,
          yoyProfitGrowth: 9.8,
        ),
        FinancialPeriod(
          period: 'Q3 FY24',
          revenue: mcap * 0.112,
          netProfit: mcap * 0.013,
          ebitda: mcap * 0.023,
          ebitdaMargin: 20.54,
          eps: 16.50,
          yoyRevenueGrowth: 6.1,
          yoyProfitGrowth: 8.4,
        ),
        FinancialPeriod(
          period: 'Q2 FY24',
          revenue: mcap * 0.108,
          netProfit: mcap * 0.012,
          ebitda: mcap * 0.022,
          ebitdaMargin: 20.37,
          eps: 15.20,
          yoyRevenueGrowth: 5.4,
          yoyProfitGrowth: 7.1,
        ),
      ],
      annualResults: [
        FinancialPeriod(
          period: 'FY 2024',
          revenue: mcap * 0.45,
          netProfit: mcap * 0.054,
          ebitda: mcap * 0.093,
          ebitdaMargin: 20.67,
          eps: 67.90,
          yoyRevenueGrowth: 11.4,
          yoyProfitGrowth: 14.8,
        ),
        FinancialPeriod(
          period: 'FY 2023',
          revenue: mcap * 0.40,
          netProfit: mcap * 0.047,
          ebitda: mcap * 0.081,
          ebitdaMargin: 20.25,
          eps: 59.10,
          yoyRevenueGrowth: 15.2,
          yoyProfitGrowth: 18.0,
        ),
      ],
      balanceSheet: BalanceSheetSummary(
        asOfDate: '31 Mar 2024',
        totalAssets: mcap * 0.9,
        totalLiabilities: mcap * 0.4,
        shareholderEquity: mcap * 0.5,
        totalDebt: mcap * 0.18,
        cashAndEquivalents: mcap * 0.08,
      ),
      cashFlow: CashFlowSummary(
        asOfDate: 'FY 2024',
        operatingCashFlow: mcap * 0.065,
        investingCashFlow: -(mcap * 0.035),
        financingCashFlow: -(mcap * 0.015),
        freeCashFlow: mcap * 0.032,
      ),
      shareholding: ShareholdingPattern(
        asOfQuarter: 'June 2026',
        promoterPercent: promoter,
        promoterPledgedPercent: 0.0,
        fiiPercent: fii,
        diiPercent: dii,
        publicPercent: publicPct,
        promoterChangeQoq: 0.0,
        fiiChangeQoq: 0.25,
        diiChangeQoq: 0.15,
      ),
    );
  }

  String _inferSector(String symbol) {
    final s = symbol.toUpperCase();
    if (s.contains('BANK') || s.contains('FIN') || s.contains('HDFC')) {
      return 'Financial Services';
    }
    if (s.contains('TECH') || s.contains('INFY') || s.contains('TCS')) {
      return 'Information Technology';
    }
    if (s.contains('AUTO') || s.contains('MOTOR') || s.contains('MARUTI')) {
      return 'Automobile';
    }
    if (s.contains('PHARMA') || s.contains('HEALTH') || s.contains('DRREDDY')) {
      return 'Healthcare & Pharma';
    }
    if (s.contains('OIL') || s.contains('GAS') || s.contains('POWER')) {
      return 'Energy & Utilities';
    }
    return 'Industrial & Manufacturing';
  }
}
