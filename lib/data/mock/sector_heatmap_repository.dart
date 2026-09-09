import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

@immutable
class SectorHeatmapFilterState {
  final HeatmapTimeframe timeframe;
  final HeatmapScope scope;
  final HeatmapViewMode viewMode;
  final String? selectedSectorName;

  const SectorHeatmapFilterState({
    this.timeframe = HeatmapTimeframe.oneDay,
    this.scope = HeatmapScope.allSectors,
    this.viewMode = HeatmapViewMode.treemap,
    this.selectedSectorName,
  });

  SectorHeatmapFilterState copyWith({
    HeatmapTimeframe? timeframe,
    HeatmapScope? scope,
    HeatmapViewMode? viewMode,
    String? selectedSectorName,
    bool clearSelectedSector = false,
  }) {
    return SectorHeatmapFilterState(
      timeframe: timeframe ?? this.timeframe,
      scope: scope ?? this.scope,
      viewMode: viewMode ?? this.viewMode,
      selectedSectorName: clearSelectedSector
          ? null
          : (selectedSectorName ?? this.selectedSectorName),
    );
  }
}

class SectorHeatmapFilterNotifier
    extends StateNotifier<SectorHeatmapFilterState> {
  SectorHeatmapFilterNotifier() : super(const SectorHeatmapFilterState());

  void setTimeframe(HeatmapTimeframe timeframe) {
    state = state.copyWith(timeframe: timeframe);
  }

  void setScope(HeatmapScope scope) {
    state = state.copyWith(scope: scope);
  }

  void setViewMode(HeatmapViewMode viewMode) {
    state = state.copyWith(viewMode: viewMode);
  }

  void selectSector(String? sectorName) {
    if (state.selectedSectorName == sectorName) {
      state = state.copyWith(clearSelectedSector: true);
    } else {
      state = state.copyWith(selectedSectorName: sectorName);
    }
  }

  void resetFilters() {
    state = const SectorHeatmapFilterState();
  }
}

final sectorHeatmapFilterProvider =
    StateNotifierProvider<SectorHeatmapFilterNotifier, SectorHeatmapFilterState>(
  (ref) => SectorHeatmapFilterNotifier(),
);

@immutable
class MarketBreadthSummary {
  final int totalAdvances;
  final int totalDeclines;
  final int totalUnchanged;
  final String topSectorName;
  final double topSectorChange;
  final String laggingSectorName;
  final double laggingSectorChange;

  const MarketBreadthSummary({
    required this.totalAdvances,
    required this.totalDeclines,
    required this.totalUnchanged,
    required this.topSectorName,
    required this.topSectorChange,
    required this.laggingSectorName,
    required this.laggingSectorChange,
  });
}

@immutable
class SectorHeatmapPayload {
  final List<SectorPerformance> sectors;
  final MarketBreadthSummary summary;
  final HeatmapTimeframe timeframe;
  final HeatmapScope scope;
  final HeatmapViewMode viewMode;

  const SectorHeatmapPayload({
    required this.sectors,
    required this.summary,
    required this.timeframe,
    required this.scope,
    required this.viewMode,
  });
}

class SectorHeatmapRepository {
  SectorHeatmapRepository._();

  static const List<SectorPerformance> _rawSectors = [
    // 1. Banking & Financials (Weight ~33.5%)
    SectorPerformance(
      name: 'Banking & Financials',
      indexSymbol: 'NIFTY BANK',
      weight: 33.5,
      avgChangePercent: 1.12,
      advancesCount: 6,
      declinesCount: 1,
      unchangedCount: 0,
      stocks: [
        HeatmapStockItem(
          token: 'eq_hdfcbank',
          symbol: 'HDFCBANK',
          name: 'HDFC Bank Ltd',
          sector: 'Banking & Financials',
          marketCap: 12.8,
          weight: 11.2,
          ltp: 1648.20,
          change: 18.40,
          changePercent: 1.13,
          changePercent1W: 2.40,
          changePercent1M: 4.80,
          changePercent1Y: 14.20,
          volume: 14850000,
          dayHigh: 1656.00,
          dayLow: 1635.50,
        ),
        HeatmapStockItem(
          token: 'eq_icicibank',
          symbol: 'ICICIBANK',
          name: 'ICICI Bank Ltd',
          sector: 'Banking & Financials',
          marketCap: 8.6,
          weight: 8.1,
          ltp: 1224.75,
          change: 14.50,
          changePercent: 1.20,
          changePercent1W: 1.80,
          changePercent1M: 5.10,
          changePercent1Y: 28.40,
          volume: 9800000,
          dayHigh: 1232.00,
          dayLow: 1215.00,
        ),
        HeatmapStockItem(
          token: 'eq_sbin',
          symbol: 'SBIN',
          name: 'State Bank of India',
          sector: 'Banking & Financials',
          marketCap: 7.2,
          weight: 5.4,
          ltp: 815.20,
          change: 6.80,
          changePercent: 0.84,
          changePercent1W: -0.50,
          changePercent1M: 3.20,
          changePercent1Y: 38.60,
          volume: 12400000,
          dayHigh: 822.40,
          dayLow: 810.00,
        ),
        HeatmapStockItem(
          token: 'eq_kotakbank',
          symbol: 'KOTAKBANK',
          name: 'Kotak Mahindra Bank',
          sector: 'Banking & Financials',
          marketCap: 3.6,
          weight: 2.8,
          ltp: 1810.00,
          change: -12.40,
          changePercent: -0.68,
          changePercent1W: -1.20,
          changePercent1M: 0.80,
          changePercent1Y: 5.20,
          volume: 4200000,
          dayHigh: 1828.00,
          dayLow: 1802.00,
        ),
        HeatmapStockItem(
          token: 'eq_axisbank',
          symbol: 'AXISBANK',
          name: 'Axis Bank Ltd',
          sector: 'Banking & Financials',
          marketCap: 3.6,
          weight: 2.7,
          ltp: 1180.00,
          change: 8.60,
          changePercent: 0.73,
          changePercent1W: 1.10,
          changePercent1M: 2.90,
          changePercent1Y: 18.50,
          volume: 6500000,
          dayHigh: 1192.00,
          dayLow: 1172.00,
        ),
        HeatmapStockItem(
          token: 'eq_bajfinance',
          symbol: 'BAJFINANCE',
          name: 'Bajaj Finance Ltd',
          sector: 'Banking & Financials',
          marketCap: 4.4,
          weight: 2.1,
          ltp: 7350.00,
          change: 110.00,
          changePercent: 1.52,
          changePercent1W: 3.40,
          changePercent1M: 6.50,
          changePercent1Y: 11.80,
          volume: 1200000,
          dayHigh: 7410.00,
          dayLow: 7280.00,
        ),
        HeatmapStockItem(
          token: 'eq_bajajfinsv',
          symbol: 'BAJAJFINSV',
          name: 'Bajaj Finserv Ltd',
          sector: 'Banking & Financials',
          marketCap: 2.9,
          weight: 1.2,
          ltp: 1845.00,
          change: 22.00,
          changePercent: 1.21,
          changePercent1W: 2.80,
          changePercent1M: 4.10,
          changePercent1Y: 22.00,
          volume: 1800000,
          dayHigh: 1860.00,
          dayLow: 1825.00,
        ),
      ],
    ),

    // 2. Automobiles (Weight ~7.8%)
    SectorPerformance(
      name: 'Automobiles',
      indexSymbol: 'NIFTY AUTO',
      weight: 7.8,
      avgChangePercent: 1.78,
      advancesCount: 4,
      declinesCount: 1,
      unchangedCount: 0,
      stocks: [
        HeatmapStockItem(
          token: 'eq_tatamotors',
          symbol: 'TATAMOTORS',
          name: 'Tata Motors Ltd',
          sector: 'Automobiles',
          marketCap: 3.9,
          weight: 2.4,
          ltp: 1085.00,
          change: 34.50,
          changePercent: 3.28,
          changePercent1W: 5.20,
          changePercent1M: 9.80,
          changePercent1Y: 62.40,
          volume: 18500000,
          dayHigh: 1094.00,
          dayLow: 1055.00,
        ),
        HeatmapStockItem(
          token: 'eq_maruti',
          symbol: 'MARUTI',
          name: 'Maruti Suzuki India',
          sector: 'Automobiles',
          marketCap: 3.9,
          weight: 2.1,
          ltp: 12450.00,
          change: 180.00,
          changePercent: 1.47,
          changePercent1W: 1.60,
          changePercent1M: 3.40,
          changePercent1Y: 21.80,
          volume: 850000,
          dayHigh: 12520.00,
          dayLow: 12310.00,
        ),
        HeatmapStockItem(
          token: 'eq_mm',
          symbol: 'M&M',
          name: 'Mahindra & Mahindra',
          sector: 'Automobiles',
          marketCap: 3.4,
          weight: 1.8,
          ltp: 2780.00,
          change: 58.00,
          changePercent: 2.13,
          changePercent1W: 4.10,
          changePercent1M: 8.20,
          changePercent1Y: 76.50,
          volume: 3400000,
          dayHigh: 2810.00,
          dayLow: 2735.00,
        ),
        HeatmapStockItem(
          token: 'eq_bajajauto',
          symbol: 'BAJAJ-AUTO',
          name: 'Bajaj Auto Ltd',
          sector: 'Automobiles',
          marketCap: 2.8,
          weight: 0.9,
          ltp: 9850.00,
          change: 145.00,
          changePercent: 1.49,
          changePercent1W: 2.20,
          changePercent1M: 6.50,
          changePercent1Y: 94.10,
          volume: 620000,
          dayHigh: 9940.00,
          dayLow: 9730.00,
        ),
        HeatmapStockItem(
          token: 'eq_heromotoco',
          symbol: 'HEROMOTOCO',
          name: 'Hero MotoCorp',
          sector: 'Automobiles',
          marketCap: 1.1,
          weight: 0.6,
          ltp: 5450.00,
          change: -28.00,
          changePercent: -0.51,
          changePercent1W: 0.80,
          changePercent1M: 3.10,
          changePercent1Y: 78.20,
          volume: 890000,
          dayHigh: 5510.00,
          dayLow: 5420.00,
        ),
      ],
    ),

    // 3. Oil, Gas & Energy (Weight ~13.8%)
    SectorPerformance(
      name: 'Oil, Gas & Energy',
      indexSymbol: 'NIFTY ENERGY',
      weight: 13.8,
      avgChangePercent: 1.25,
      advancesCount: 4,
      declinesCount: 1,
      unchangedCount: 0,
      stocks: [
        HeatmapStockItem(
          token: 'eq_reliance',
          symbol: 'RELIANCE',
          name: 'Reliance Industries',
          sector: 'Oil, Gas & Energy',
          marketCap: 20.1,
          weight: 9.4,
          ltp: 2985.50,
          change: 38.50,
          changePercent: 1.31,
          changePercent1W: 2.50,
          changePercent1M: 4.20,
          changePercent1Y: 22.80,
          volume: 7200000,
          dayHigh: 2998.00,
          dayLow: 2950.00,
        ),
        HeatmapStockItem(
          token: 'eq_ntpc',
          symbol: 'NTPC',
          name: 'NTPC Ltd',
          sector: 'Oil, Gas & Energy',
          marketCap: 4.0,
          weight: 1.4,
          ltp: 412.00,
          change: 6.50,
          changePercent: 1.60,
          changePercent1W: 3.10,
          changePercent1M: 8.50,
          changePercent1Y: 72.40,
          volume: 11200000,
          dayHigh: 416.50,
          dayLow: 407.00,
        ),
        HeatmapStockItem(
          token: 'eq_powergrid',
          symbol: 'POWERGRID',
          name: 'Power Grid Corp',
          sector: 'Oil, Gas & Energy',
          marketCap: 3.1,
          weight: 1.2,
          ltp: 338.00,
          change: 4.20,
          changePercent: 1.26,
          changePercent1W: 1.90,
          changePercent1M: 5.20,
          changePercent1Y: 68.90,
          volume: 9500000,
          dayHigh: 341.00,
          dayLow: 334.50,
        ),
        HeatmapStockItem(
          token: 'eq_coalindia',
          symbol: 'COALINDIA',
          name: 'Coal India Ltd',
          sector: 'Oil, Gas & Energy',
          marketCap: 3.2,
          weight: 1.1,
          ltp: 518.00,
          change: 9.20,
          changePercent: 1.81,
          changePercent1W: 2.80,
          changePercent1M: 7.10,
          changePercent1Y: 84.20,
          volume: 8400000,
          dayHigh: 522.00,
          dayLow: 511.00,
        ),
        HeatmapStockItem(
          token: 'eq_ongc',
          symbol: 'ONGC',
          name: 'ONGC Ltd',
          sector: 'Oil, Gas & Energy',
          marketCap: 4.1,
          weight: 1.6,
          ltp: 324.00,
          change: -1.80,
          changePercent: -0.55,
          changePercent1W: 1.20,
          changePercent1M: 6.40,
          changePercent1Y: 78.50,
          volume: 14200000,
          dayHigh: 328.00,
          dayLow: 322.00,
        ),
      ],
    ),

    // 4. Information Technology (Weight ~14.2%)
    SectorPerformance(
      name: 'Information Technology',
      indexSymbol: 'NIFTY IT',
      weight: 14.2,
      avgChangePercent: -1.05,
      advancesCount: 1,
      declinesCount: 4,
      unchangedCount: 0,
      stocks: [
        HeatmapStockItem(
          token: 'eq_tcs',
          symbol: 'TCS',
          name: 'Tata Consultancy Services',
          sector: 'Information Technology',
          marketCap: 15.2,
          weight: 5.8,
          ltp: 4215.00,
          change: -45.00,
          changePercent: -1.06,
          changePercent1W: -2.10,
          changePercent1M: 3.50,
          changePercent1Y: 24.60,
          volume: 2400000,
          dayHigh: 4268.00,
          dayLow: 4202.00,
        ),
        HeatmapStockItem(
          token: 'eq_infy',
          symbol: 'INFY',
          name: 'Infosys Ltd',
          sector: 'Information Technology',
          marketCap: 7.8,
          weight: 4.6,
          ltp: 1885.30,
          change: -32.50,
          changePercent: -1.69,
          changePercent1W: -3.20,
          changePercent1M: 1.80,
          changePercent1Y: 28.90,
          volume: 6800000,
          dayHigh: 1918.00,
          dayLow: 1878.00,
        ),
        HeatmapStockItem(
          token: 'eq_hcltech',
          symbol: 'HCLTECH',
          name: 'HCL Technologies',
          sector: 'Information Technology',
          marketCap: 4.8,
          weight: 1.8,
          ltp: 1760.00,
          change: -14.00,
          changePercent: -0.79,
          changePercent1W: -1.40,
          changePercent1M: 4.20,
          changePercent1Y: 39.10,
          volume: 2900000,
          dayHigh: 1782.00,
          dayLow: 1751.00,
        ),
        HeatmapStockItem(
          token: 'eq_wipro',
          symbol: 'WIPRO',
          name: 'Wipro Ltd',
          sector: 'Information Technology',
          marketCap: 2.8,
          weight: 1.0,
          ltp: 532.00,
          change: -2.80,
          changePercent: -0.52,
          changePercent1W: -0.90,
          changePercent1M: 2.10,
          changePercent1Y: 25.40,
          volume: 5400000,
          dayHigh: 537.00,
          dayLow: 529.50,
        ),
        HeatmapStockItem(
          token: 'eq_techm',
          symbol: 'TECHM',
          name: 'Tech Mahindra Ltd',
          sector: 'Information Technology',
          marketCap: 1.5,
          weight: 0.8,
          ltp: 1610.00,
          change: 8.50,
          changePercent: 0.53,
          changePercent1W: 0.40,
          changePercent1M: 5.80,
          changePercent1Y: 34.20,
          volume: 1800000,
          dayHigh: 1622.00,
          dayLow: 1598.00,
        ),
      ],
    ),

    // 5. Metals & Mining (Weight ~4.5%)
    SectorPerformance(
      name: 'Metals & Mining',
      indexSymbol: 'NIFTY METAL',
      weight: 4.5,
      avgChangePercent: 1.82,
      advancesCount: 4,
      declinesCount: 0,
      unchangedCount: 0,
      stocks: [
        HeatmapStockItem(
          token: 'eq_tatasteel',
          symbol: 'TATASTEEL',
          name: 'Tata Steel Ltd',
          sector: 'Metals & Mining',
          marketCap: 1.9,
          weight: 1.8,
          ltp: 154.50,
          change: 3.20,
          changePercent: 2.11,
          changePercent1W: 3.80,
          changePercent1M: -1.20,
          changePercent1Y: 18.40,
          volume: 38000000,
          dayHigh: 156.20,
          dayLow: 151.80,
        ),
        HeatmapStockItem(
          token: 'eq_jswsteel',
          symbol: 'JSWSTEEL',
          name: 'JSW Steel Ltd',
          sector: 'Metals & Mining',
          marketCap: 2.3,
          weight: 1.5,
          ltp: 945.00,
          change: 14.20,
          changePercent: 1.53,
          changePercent1W: 2.40,
          changePercent1M: 1.80,
          changePercent1Y: 16.90,
          volume: 3100000,
          dayHigh: 952.00,
          dayLow: 933.00,
        ),
        HeatmapStockItem(
          token: 'eq_hindalco',
          symbol: 'HINDALCO',
          name: 'Hindalco Industries',
          sector: 'Metals & Mining',
          marketCap: 1.5,
          weight: 1.2,
          ltp: 682.00,
          change: 11.50,
          changePercent: 1.71,
          changePercent1W: 2.90,
          changePercent1M: 3.40,
          changePercent1Y: 42.10,
          volume: 5800000,
          dayHigh: 688.00,
          dayLow: 672.00,
        ),
        HeatmapStockItem(
          token: 'eq_vedl',
          symbol: 'VEDL',
          name: 'Vedanta Ltd',
          sector: 'Metals & Mining',
          marketCap: 1.7,
          weight: 0.9,
          ltp: 452.00,
          change: 8.80,
          changePercent: 1.99,
          changePercent1W: 4.20,
          changePercent1M: 5.60,
          changePercent1Y: 88.50,
          volume: 9400000,
          dayHigh: 458.00,
          dayLow: 444.00,
        ),
      ],
    ),

    // 6. Pharmaceuticals & Healthcare (Weight ~4.2%)
    SectorPerformance(
      name: 'Pharma & Healthcare',
      indexSymbol: 'NIFTY PHARMA',
      weight: 4.2,
      avgChangePercent: -0.15,
      advancesCount: 2,
      declinesCount: 2,
      unchangedCount: 0,
      stocks: [
        HeatmapStockItem(
          token: 'eq_sunpharma',
          symbol: 'SUNPHARMA',
          name: 'Sun Pharmaceutical',
          sector: 'Pharma & Healthcare',
          marketCap: 4.3,
          weight: 1.9,
          ltp: 1820.00,
          change: -16.50,
          changePercent: -0.90,
          changePercent1W: -1.10,
          changePercent1M: 4.50,
          changePercent1Y: 54.20,
          volume: 2400000,
          dayHigh: 1845.00,
          dayLow: 1812.00,
        ),
        HeatmapStockItem(
          token: 'eq_cipla',
          symbol: 'CIPLA',
          name: 'Cipla Ltd',
          sector: 'Pharma & Healthcare',
          marketCap: 1.3,
          weight: 0.8,
          ltp: 1640.00,
          change: 12.00,
          changePercent: 0.74,
          changePercent1W: 1.50,
          changePercent1M: 5.20,
          changePercent1Y: 38.90,
          volume: 1900000,
          dayHigh: 1655.00,
          dayLow: 1630.00,
        ),
        HeatmapStockItem(
          token: 'eq_drreddy',
          symbol: 'DRREDDY',
          name: 'Dr Reddys Labs',
          sector: 'Pharma & Healthcare',
          marketCap: 1.1,
          weight: 0.7,
          ltp: 6680.00,
          change: -48.00,
          changePercent: -0.71,
          changePercent1W: -0.80,
          changePercent1M: 2.40,
          changePercent1Y: 22.10,
          volume: 680000,
          dayHigh: 6740.00,
          dayLow: 6645.00,
        ),
        HeatmapStockItem(
          token: 'eq_divislab',
          symbol: 'DIVISLAB',
          name: 'Divis Laboratories',
          sector: 'Pharma & Healthcare',
          marketCap: 1.4,
          weight: 0.8,
          ltp: 5230.00,
          change: 35.00,
          changePercent: 0.67,
          changePercent1W: 1.80,
          changePercent1M: 7.20,
          changePercent1Y: 38.50,
          volume: 720000,
          dayHigh: 5280.00,
          dayLow: 5190.00,
        ),
      ],
    ),

    // 7. FMCG & Consumption (Weight ~8.9%)
    SectorPerformance(
      name: 'FMCG & Consumption',
      indexSymbol: 'NIFTY FMCG',
      weight: 8.9,
      avgChangePercent: 0.12,
      advancesCount: 2,
      declinesCount: 2,
      unchangedCount: 0,
      stocks: [
        HeatmapStockItem(
          token: 'eq_itc',
          symbol: 'ITC',
          name: 'ITC Ltd',
          sector: 'FMCG & Consumption',
          marketCap: 6.2,
          weight: 3.8,
          ltp: 502.40,
          change: 2.80,
          changePercent: 0.56,
          changePercent1W: 1.20,
          changePercent1M: 2.80,
          changePercent1Y: 14.80,
          volume: 12800000,
          dayHigh: 506.00,
          dayLow: 499.50,
        ),
        HeatmapStockItem(
          token: 'eq_hindunilvr',
          symbol: 'HINDUNILVR',
          name: 'Hindustan Unilever',
          sector: 'FMCG & Consumption',
          marketCap: 6.5,
          weight: 3.2,
          ltp: 2780.00,
          change: -18.50,
          changePercent: -0.66,
          changePercent1W: -1.40,
          changePercent1M: 1.50,
          changePercent1Y: 9.40,
          volume: 1450000,
          dayHigh: 2805.00,
          dayLow: 2772.00,
        ),
        HeatmapStockItem(
          token: 'eq_nestleind',
          symbol: 'NESTLEIND',
          name: 'Nestle India Ltd',
          sector: 'FMCG & Consumption',
          marketCap: 2.4,
          weight: 1.1,
          ltp: 2520.00,
          change: -12.00,
          changePercent: -0.47,
          changePercent1W: -0.80,
          changePercent1M: 0.40,
          changePercent1Y: 12.10,
          volume: 480000,
          dayHigh: 2542.00,
          dayLow: 2510.00,
        ),
        HeatmapStockItem(
          token: 'eq_britannia',
          symbol: 'BRITANNIA',
          name: 'Britannia Industries',
          sector: 'FMCG & Consumption',
          marketCap: 1.4,
          weight: 0.8,
          ltp: 5920.00,
          change: 42.00,
          changePercent: 0.71,
          changePercent1W: 1.60,
          changePercent1M: 4.80,
          changePercent1Y: 28.50,
          volume: 520000,
          dayHigh: 5960.00,
          dayLow: 5880.00,
        ),
      ],
    ),

    // 8. Infrastructure & Industrials (Weight ~7.2%)
    SectorPerformance(
      name: 'Infra & Industrials',
      indexSymbol: 'NIFTY INFRA',
      weight: 7.2,
      avgChangePercent: 0.88,
      advancesCount: 3,
      declinesCount: 1,
      unchangedCount: 0,
      stocks: [
        HeatmapStockItem(
          token: 'eq_lt',
          symbol: 'LT',
          name: 'Larsen & Toubro',
          sector: 'Infra & Industrials',
          marketCap: 5.0,
          weight: 3.6,
          ltp: 3650.00,
          change: 52.00,
          changePercent: 1.45,
          changePercent1W: 2.60,
          changePercent1M: -0.50,
          changePercent1Y: 24.80,
          volume: 2400000,
          dayHigh: 3680.00,
          dayLow: 3615.00,
        ),
        HeatmapStockItem(
          token: 'eq_adaniports',
          symbol: 'ADANIPORTS',
          name: 'Adani Ports & SEZ',
          sector: 'Infra & Industrials',
          marketCap: 3.2,
          weight: 1.4,
          ltp: 1485.00,
          change: 18.50,
          changePercent: 1.26,
          changePercent1W: 1.80,
          changePercent1M: 2.40,
          changePercent1Y: 82.40,
          volume: 4800000,
          dayHigh: 1498.00,
          dayLow: 1465.00,
        ),
        HeatmapStockItem(
          token: 'eq_ultracemco',
          symbol: 'ULTRACEMCO',
          name: 'UltraTech Cement',
          sector: 'Infra & Industrials',
          marketCap: 3.2,
          weight: 1.2,
          ltp: 11250.00,
          change: 140.00,
          changePercent: 1.26,
          changePercent1W: 1.90,
          changePercent1M: 4.80,
          changePercent1Y: 34.20,
          volume: 420000,
          dayHigh: 11340.00,
          dayLow: 11120.00,
        ),
        HeatmapStockItem(
          token: 'eq_adanient',
          symbol: 'ADANIENT',
          name: 'Adani Enterprises',
          sector: 'Infra & Industrials',
          marketCap: 3.4,
          weight: 1.8,
          ltp: 3040.00,
          change: -35.00,
          changePercent: -1.14,
          changePercent1W: -2.40,
          changePercent1M: -3.20,
          changePercent1Y: 21.40,
          volume: 3800000,
          dayHigh: 3090.00,
          dayLow: 3010.00,
        ),
      ],
    ),
  ];

  static List<SectorPerformance> getAllSectors() => _rawSectors;

  static SectorHeatmapPayload getPayload(SectorHeatmapFilterState filter) {
    int totalAdvances = 0;
    int totalDeclines = 0;
    int totalUnchanged = 0;

    final List<SectorPerformance> processedSectors = [];

    for (final sector in _rawSectors) {
      if (filter.selectedSectorName != null &&
          sector.name != filter.selectedSectorName) {
        continue;
      }

      // Filter constituent stocks by scope
      final List<HeatmapStockItem> filteredStocks = sector.stocks.where((stock) {
        final change = stock.getEffectiveChange(filter.timeframe);
        switch (filter.scope) {
          case HeatmapScope.allSectors:
            return true;
          case HeatmapScope.nifty50:
            return stock.isNifty50;
          case HeatmapScope.gainersOnly:
            return change > 0.05;
          case HeatmapScope.losersOnly:
            return change < -0.05;
        }
      }).toList();

      if (filteredStocks.isEmpty && filter.scope != HeatmapScope.allSectors) {
        continue;
      }

      // Calculate sector stats based on timeframe
      int sectorAdv = 0;
      int sectorDec = 0;
      int sectorUnc = 0;
      double totalWeightedChange = 0.0;
      double totalSectorWeight = 0.0;

      for (final stock in (filteredStocks.isEmpty ? sector.stocks : filteredStocks)) {
        final change = stock.getEffectiveChange(filter.timeframe);
        if (change > 0.05) {
          sectorAdv++;
        } else if (change < -0.05) {
          sectorDec++;
        } else {
          sectorUnc++;
        }

        totalWeightedChange += change * stock.weight;
        totalSectorWeight += stock.weight;
      }

      final avgChange = totalSectorWeight > 0
          ? totalWeightedChange / totalSectorWeight
          : 0.0;

      totalAdvances += sectorAdv;
      totalDeclines += sectorDec;
      totalUnchanged += sectorUnc;

      // Sort stocks by weight descending for proper treemap rendering
      filteredStocks.sort((a, b) => b.weight.compareTo(a.weight));

      processedSectors.add(
        sector.copyWith(
          avgChangePercent: double.parse(avgChange.toStringAsFixed(2)),
          advancesCount: sectorAdv,
          declinesCount: sectorDec,
          unchangedCount: sectorUnc,
          stocks: filteredStocks,
        ),
      );
    }

    // Identify top and lagging sectors
    String topSector = 'Automobiles';
    double topChange = -999.0;
    String laggingSector = 'Information Technology';
    double laggingChange = 999.0;

    for (final s in processedSectors) {
      if (s.avgChangePercent > topChange) {
        topChange = s.avgChangePercent;
        topSector = s.name;
      }
      if (s.avgChangePercent < laggingChange) {
        laggingChange = s.avgChangePercent;
        laggingSector = s.name;
      }
    }

    final summary = MarketBreadthSummary(
      totalAdvances: totalAdvances,
      totalDeclines: totalDeclines,
      totalUnchanged: totalUnchanged,
      topSectorName: topSector,
      topSectorChange: topChange == -999.0 ? 0.0 : topChange,
      laggingSectorName: laggingSector,
      laggingSectorChange: laggingChange == 999.0 ? 0.0 : laggingChange,
    );

    return SectorHeatmapPayload(
      sectors: processedSectors,
      summary: summary,
      timeframe: filter.timeframe,
      scope: filter.scope,
      viewMode: filter.viewMode,
    );
  }
}

final sectorHeatmapDataProvider = Provider<SectorHeatmapPayload>((ref) {
  final filter = ref.watch(sectorHeatmapFilterProvider);
  return SectorHeatmapRepository.getPayload(filter);
});
