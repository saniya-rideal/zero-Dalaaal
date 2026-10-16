import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/models.dart';

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

class SectorHeatmapFilterNotifier extends StateNotifier<SectorHeatmapFilterState> {
  SectorHeatmapFilterNotifier() : super(const SectorHeatmapFilterState());

  void setTimeframe(HeatmapTimeframe timeframe) => state = state.copyWith(timeframe: timeframe);
  void setScope(HeatmapScope scope) => state = state.copyWith(scope: scope);
  void setViewMode(HeatmapViewMode viewMode) => state = state.copyWith(viewMode: viewMode);
  void selectSector(String? name) {
    if (name != null && state.selectedSectorName == name) {
      state = state.copyWith(clearSelectedSector: true);
    } else {
      state = state.copyWith(selectedSectorName: name);
    }
  }
  void clearSelectedSector() => state = state.copyWith(clearSelectedSector: true);
  void resetFilters() => state = const SectorHeatmapFilterState();
}

final sectorHeatmapFilterProvider =
    StateNotifierProvider<SectorHeatmapFilterNotifier, SectorHeatmapFilterState>((ref) {
  return SectorHeatmapFilterNotifier();
});

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

class HeatmapRepository {
  final ApiClient _apiClient;

  HeatmapRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<SectorPerformance>> getHeatmap() async {
    final data = await _apiClient.get(ApiPaths.marketHeatmap);
    final items = ResponseReader.list(data, 'sectors');
    final rawList = items.isNotEmpty ? items : ResponseReader.list(data);

    return rawList.whereType<Map<String, dynamic>>().map((s) {
      final name = (s['name'] ?? s['sector'] ?? '').toString();
      final indexSymbol = (s['indexSymbol'] ?? s['symbol'] ?? name).toString();
      final weight = (s['weight'] as num?)?.toDouble() ?? 10.0;
      final changePct = (s['changePercent'] ?? s['change'] as num?)?.toDouble() ?? 0.0;
      final advances = (s['advances'] ?? s['advancesCount'] as num?)?.toInt() ?? 0;
      final declines = (s['declines'] ?? s['declinesCount'] as num?)?.toInt() ?? 0;
      final unchanged = (s['unchanged'] ?? s['unchangedCount'] as num?)?.toInt() ?? 0;

      final rawStocks = ResponseReader.list(s, 'stocks');
      final stocks = rawStocks.whereType<Map<String, dynamic>>().map((item) {
        return HeatmapStockItem.fromJson(item);
      }).toList();

      return SectorPerformance(
        name: name,
        indexSymbol: indexSymbol,
        weight: weight,
        avgChangePercent: changePct,
        advancesCount: advances,
        declinesCount: declines,
        unchangedCount: unchanged,
        stocks: stocks,
      );
    }).toList();
  }
}

final heatmapRepositoryProvider = Provider<HeatmapRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HeatmapRepository(apiClient: apiClient);
});

final rawSectorHeatmapProvider = FutureProvider<List<SectorPerformance>>((ref) async {
  final repo = ref.watch(heatmapRepositoryProvider);
  return repo.getHeatmap();
});

final sectorHeatmapDataProvider = Provider<SectorHeatmapPayload>((ref) {
  final rawAsync = ref.watch(rawSectorHeatmapProvider);
  final sectors = rawAsync.valueOrNull ?? const [];
  final filter = ref.watch(sectorHeatmapFilterProvider);

  int totalAdv = 0;
  int totalDec = 0;
  int totalUnc = 0;
  String topSec = '';
  double topChange = -999.0;
  String lagSec = '';
  double lagChange = 999.0;

  for (final s in sectors) {
    totalAdv += s.advancesCount;
    totalDec += s.declinesCount;
    totalUnc += s.unchangedCount;
    if (s.avgChangePercent > topChange) {
      topChange = s.avgChangePercent;
      topSec = s.name;
    }
    if (s.avgChangePercent < lagChange) {
      lagChange = s.avgChangePercent;
      lagSec = s.name;
    }
  }

  final summary = MarketBreadthSummary(
    totalAdvances: totalAdv,
    totalDeclines: totalDec,
    totalUnchanged: totalUnc,
    topSectorName: topSec.isNotEmpty ? topSec : 'N/A',
    topSectorChange: topChange != -999.0 ? topChange : 0.0,
    laggingSectorName: lagSec.isNotEmpty ? lagSec : 'N/A',
    laggingSectorChange: lagChange != 999.0 ? lagChange : 0.0,
  );

  final filteredSectors = filter.selectedSectorName != null
      ? sectors.where((s) => s.name == filter.selectedSectorName).toList()
      : sectors;

  return SectorHeatmapPayload(
    sectors: filteredSectors,
    summary: summary,
    timeframe: filter.timeframe,
    scope: filter.scope,
    viewMode: filter.viewMode,
  );
});
