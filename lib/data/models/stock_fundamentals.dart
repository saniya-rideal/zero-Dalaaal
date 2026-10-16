/// Strongly typed data models representing Company Fundamentals, Valuation Ratios,
/// Financial Results (Income Statement, Balance Sheet, Cash Flow), and Shareholding Patterns.
library;

class FinancialPeriod {
  final String period; // e.g. 'Q1 FY25', 'FY24'
  final double revenue; // in ₹ Crores
  final double netProfit; // in ₹ Crores
  final double ebitda; // in ₹ Crores
  final double ebitdaMargin; // percentage e.g. 24.5%
  final double eps; // in ₹
  final double yoyRevenueGrowth; // percentage e.g. 12.4%
  final double yoyProfitGrowth; // percentage e.g. 8.2%

  const FinancialPeriod({
    required this.period,
    required this.revenue,
    required this.netProfit,
    required this.ebitda,
    required this.ebitdaMargin,
    required this.eps,
    required this.yoyRevenueGrowth,
    required this.yoyProfitGrowth,
  });

  Map<String, dynamic> toJson() => {
        'period': period,
        'revenue': revenue,
        'netProfit': netProfit,
        'ebitda': ebitda,
        'ebitdaMargin': ebitdaMargin,
        'eps': eps,
        'yoyRevenueGrowth': yoyRevenueGrowth,
        'yoyProfitGrowth': yoyProfitGrowth,
      };

  factory FinancialPeriod.fromJson(Map<String, dynamic> json) =>
      FinancialPeriod(
        period: json['period'] as String,
        revenue: (json['revenue'] as num).toDouble(),
        netProfit: (json['netProfit'] as num).toDouble(),
        ebitda: (json['ebitda'] as num).toDouble(),
        ebitdaMargin: (json['ebitdaMargin'] as num).toDouble(),
        eps: (json['eps'] as num).toDouble(),
        yoyRevenueGrowth: (json['yoyRevenueGrowth'] as num).toDouble(),
        yoyProfitGrowth: (json['yoyProfitGrowth'] as num).toDouble(),
      );
}

class BalanceSheetSummary {
  final String asOfDate; // e.g. '31 Mar 2024'
  final double totalAssets; // in ₹ Crores
  final double totalLiabilities; // in ₹ Crores
  final double shareholderEquity; // in ₹ Crores
  final double totalDebt; // in ₹ Crores
  final double cashAndEquivalents; // in ₹ Crores

  const BalanceSheetSummary({
    required this.asOfDate,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.shareholderEquity,
    required this.totalDebt,
    required this.cashAndEquivalents,
  });

  Map<String, dynamic> toJson() => {
        'asOfDate': asOfDate,
        'totalAssets': totalAssets,
        'totalLiabilities': totalLiabilities,
        'shareholderEquity': shareholderEquity,
        'totalDebt': totalDebt,
        'cashAndEquivalents': cashAndEquivalents,
      };

  factory BalanceSheetSummary.fromJson(Map<String, dynamic> json) =>
      BalanceSheetSummary(
        asOfDate: json['asOfDate'] as String,
        totalAssets: (json['totalAssets'] as num).toDouble(),
        totalLiabilities: (json['totalLiabilities'] as num).toDouble(),
        shareholderEquity: (json['shareholderEquity'] as num).toDouble(),
        totalDebt: (json['totalDebt'] as num).toDouble(),
        cashAndEquivalents: (json['cashAndEquivalents'] as num).toDouble(),
      );
}

class CashFlowSummary {
  final String asOfDate; // e.g. 'FY 2024'
  final double operatingCashFlow; // CFO in ₹ Crores
  final double investingCashFlow; // CFI in ₹ Crores
  final double financingCashFlow; // CFF in ₹ Crores
  final double freeCashFlow; // FCF in ₹ Crores

  const CashFlowSummary({
    required this.asOfDate,
    required this.operatingCashFlow,
    required this.investingCashFlow,
    required this.financingCashFlow,
    required this.freeCashFlow,
  });

  Map<String, dynamic> toJson() => {
        'asOfDate': asOfDate,
        'operatingCashFlow': operatingCashFlow,
        'investingCashFlow': investingCashFlow,
        'financingCashFlow': financingCashFlow,
        'freeCashFlow': freeCashFlow,
      };

  factory CashFlowSummary.fromJson(Map<String, dynamic> json) =>
      CashFlowSummary(
        asOfDate: json['asOfDate'] as String,
        operatingCashFlow: (json['operatingCashFlow'] as num).toDouble(),
        investingCashFlow: (json['investingCashFlow'] as num).toDouble(),
        financingCashFlow: (json['financingCashFlow'] as num).toDouble(),
        freeCashFlow: (json['freeCashFlow'] as num).toDouble(),
      );
}

class ValuationRatios {
  final double peRatio; // Price-to-Earnings (TTM)
  final double sectorPe; // Industry Sector Benchmark P/E
  final double pbRatio; // Price-to-Book
  final double debtToEquity; // Debt/Equity ratio (<1 is healthy)
  final double roe; // Return on Equity (%)
  final double roce; // Return on Capital Employed (%)
  final double dividendYield; // Dividend Yield (%)
  final double marketCap; // in ₹ Crores
  final String marketCapCategory; // Large Cap, Mid Cap, Small Cap
  final double bookValuePerShare; // in ₹
  final double faceValue; // in ₹
  final double beta; // Volatility measure against benchmark
  final double evToEbitda; // Enterprise Value to EBITDA

  const ValuationRatios({
    required this.peRatio,
    required this.sectorPe,
    required this.pbRatio,
    required this.debtToEquity,
    required this.roe,
    required this.roce,
    required this.dividendYield,
    required this.marketCap,
    required this.marketCapCategory,
    required this.bookValuePerShare,
    required this.faceValue,
    required this.beta,
    required this.evToEbitda,
  });

  Map<String, dynamic> toJson() => {
        'peRatio': peRatio,
        'sectorPe': sectorPe,
        'pbRatio': pbRatio,
        'debtToEquity': debtToEquity,
        'roe': roe,
        'roce': roce,
        'dividendYield': dividendYield,
        'marketCap': marketCap,
        'marketCapCategory': marketCapCategory,
        'bookValuePerShare': bookValuePerShare,
        'faceValue': faceValue,
        'beta': beta,
        'evToEbitda': evToEbitda,
      };

  factory ValuationRatios.fromJson(Map<String, dynamic> json) => ValuationRatios(
        peRatio: (json['peRatio'] ?? json['pe'] as num?)?.toDouble() ?? 0.0,
        sectorPe: (json['sectorPe'] as num?)?.toDouble() ?? 0.0,
        pbRatio: (json['pbRatio'] ?? json['pb'] as num?)?.toDouble() ?? 0.0,
        debtToEquity: (json['debtToEquity'] as num?)?.toDouble() ?? 0.0,
        roe: (json['roe'] as num?)?.toDouble() ?? 0.0,
        roce: (json['roce'] as num?)?.toDouble() ?? 0.0,
        dividendYield: (json['dividendYield'] ?? json['divYield'] as num?)?.toDouble() ?? 0.0,
        marketCap: (json['marketCap'] ?? json['mcap'] as num?)?.toDouble() ?? 0.0,
        marketCapCategory: (json['marketCapCategory'] ?? 'Large Cap').toString(),
        bookValuePerShare: (json['bookValuePerShare'] as num?)?.toDouble() ?? 0.0,
        faceValue: (json['faceValue'] as num?)?.toDouble() ?? 10.0,
        beta: (json['beta'] as num?)?.toDouble() ?? 1.0,
        evToEbitda: (json['evToEbitda'] as num?)?.toDouble() ?? 0.0,
      );
}

class ShareholdingPattern {
  final String asOfQuarter; // e.g. 'June 2026'
  final double promoterPercent; // Promoter & Promoter Group
  final double promoterPledgedPercent; // Encumbered / Pledged promoter shares
  final double fiiPercent; // Foreign Institutional Investors
  final double diiPercent; // Domestic Institutional Investors / Mutual Funds
  final double publicPercent; // Retail & Other Public Shareholders
  final double promoterChangeQoq; // % change compared to previous quarter
  final double fiiChangeQoq;
  final double diiChangeQoq;

  const ShareholdingPattern({
    required this.asOfQuarter,
    required this.promoterPercent,
    required this.promoterPledgedPercent,
    required this.fiiPercent,
    required this.diiPercent,
    required this.publicPercent,
    required this.promoterChangeQoq,
    required this.fiiChangeQoq,
    required this.diiChangeQoq,
  });

  Map<String, dynamic> toJson() => {
        'asOfQuarter': asOfQuarter,
        'promoterPercent': promoterPercent,
        'promoterPledgedPercent': promoterPledgedPercent,
        'fiiPercent': fiiPercent,
        'diiPercent': diiPercent,
        'publicPercent': publicPercent,
        'promoterChangeQoq': promoterChangeQoq,
        'fiiChangeQoq': fiiChangeQoq,
        'diiChangeQoq': diiChangeQoq,
      };

  factory ShareholdingPattern.fromJson(Map<String, dynamic> json) =>
      ShareholdingPattern(
        asOfQuarter: (json['asOfQuarter'] ?? 'Current Quarter').toString(),
        promoterPercent: (json['promoterPercent'] ?? json['promoter'] as num?)?.toDouble() ?? 0.0,
        promoterPledgedPercent:
            (json['promoterPledgedPercent'] as num?)?.toDouble() ?? 0.0,
        fiiPercent: (json['fiiPercent'] ?? json['fii'] as num?)?.toDouble() ?? 0.0,
        diiPercent: (json['diiPercent'] ?? json['dii'] as num?)?.toDouble() ?? 0.0,
        publicPercent: (json['publicPercent'] ?? json['retail'] as num?)?.toDouble() ?? 0.0,
        promoterChangeQoq: (json['promoterChangeQoq'] as num?)?.toDouble() ?? 0.0,
        fiiChangeQoq: (json['fiiChangeQoq'] as num?)?.toDouble() ?? 0.0,
        diiChangeQoq: (json['diiChangeQoq'] as num?)?.toDouble() ?? 0.0,
      );
}

class StockFundamentals {
  final String symbol;
  final String companyName;
  final String sector;
  final String industry;
  final String about;
  final ValuationRatios ratios;
  final List<FinancialPeriod> quarterlyResults;
  final List<FinancialPeriod> annualResults;
  final BalanceSheetSummary balanceSheet;
  final CashFlowSummary cashFlow;
  final ShareholdingPattern shareholding;

  const StockFundamentals({
    required this.symbol,
    required this.companyName,
    required this.sector,
    required this.industry,
    required this.about,
    required this.ratios,
    required this.quarterlyResults,
    required this.annualResults,
    required this.balanceSheet,
    required this.cashFlow,
    required this.shareholding,
  });

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'companyName': companyName,
        'sector': sector,
        'industry': industry,
        'about': about,
        'ratios': ratios.toJson(),
        'quarterlyResults': quarterlyResults.map((e) => e.toJson()).toList(),
        'annualResults': annualResults.map((e) => e.toJson()).toList(),
        'balanceSheet': balanceSheet.toJson(),
        'cashFlow': cashFlow.toJson(),
        'shareholding': shareholding.toJson(),
      };

  factory StockFundamentals.fromJson(Map<String, dynamic> json) {
    ValuationRatios rat;
    if (json['ratios'] is Map<String, dynamic>) {
      rat = ValuationRatios.fromJson(json['ratios'] as Map<String, dynamic>);
    } else {
      rat = ValuationRatios.fromJson(json);
    }

    ShareholdingPattern sh;
    if (json['shareholding'] is Map<String, dynamic>) {
      sh = ShareholdingPattern.fromJson(json['shareholding'] as Map<String, dynamic>);
    } else {
      sh = ShareholdingPattern.fromJson(json);
    }

    List<FinancialPeriod> qResults = [];
    if (json['quarterlyResults'] is List) {
      qResults = (json['quarterlyResults'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => FinancialPeriod.fromJson(e))
          .toList();
    }

    List<FinancialPeriod> aResults = [];
    if (json['annualResults'] is List) {
      aResults = (json['annualResults'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => FinancialPeriod.fromJson(e))
          .toList();
    }

    BalanceSheetSummary bs = const BalanceSheetSummary(
      asOfDate: '',
      totalAssets: 0,
      totalLiabilities: 0,
      shareholderEquity: 0,
      totalDebt: 0,
      cashAndEquivalents: 0,
    );
    if (json['balanceSheet'] is Map<String, dynamic>) {
      bs = BalanceSheetSummary.fromJson(json['balanceSheet'] as Map<String, dynamic>);
    }

    CashFlowSummary cf = const CashFlowSummary(
      asOfDate: '',
      operatingCashFlow: 0,
      investingCashFlow: 0,
      financingCashFlow: 0,
      freeCashFlow: 0,
    );
    if (json['cashFlow'] is Map<String, dynamic>) {
      cf = CashFlowSummary.fromJson(json['cashFlow'] as Map<String, dynamic>);
    }

    return StockFundamentals(
      symbol: (json['symbol'] ?? '').toString(),
      companyName: (json['companyName'] ?? json['name'] ?? json['symbol'] ?? '').toString(),
      sector: (json['sector'] ?? '').toString(),
      industry: (json['industry'] ?? '').toString(),
      about: (json['about'] ?? '').toString(),
      ratios: rat,
      quarterlyResults: qResults,
      annualResults: aResults,
      balanceSheet: bs,
      cashFlow: cf,
      shareholding: sh,
    );
  }
}
