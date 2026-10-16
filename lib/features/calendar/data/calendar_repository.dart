import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/corporate_action.dart';
import '../../quote_detail/data/fundamentals_repository.dart';

class EconomicEvent {
  final String id;
  final String title;
  final String country;
  final String flag;
  final String time;
  final String impact; // HIGH, MEDIUM, LOW
  final String actual;
  final String forecast;
  final String previous;
  final String description;
  final DateTime date;

  const EconomicEvent({
    required this.id,
    required this.title,
    required this.country,
    this.flag = '🇮🇳',
    required this.time,
    this.impact = 'MEDIUM',
    this.actual = '',
    this.forecast = '',
    this.previous = '',
    this.description = '',
    required this.date,
  });

  factory EconomicEvent.fromJson(Map<String, dynamic> json) {
    return EconomicEvent(
      id: (json['id'] ?? json['_id'] ?? 'ev_${DateTime.now().millisecondsSinceEpoch}').toString(),
      title: (json['title'] ?? json['event'] ?? '').toString(),
      country: (json['country'] ?? 'India').toString(),
      flag: (json['flag'] ?? (json['country']?.toString().toLowerCase().contains('india') == true ? '🇮🇳' : '🌐')).toString(),
      time: (json['time'] ?? '').toString(),
      impact: (json['impact'] ?? json['priority'] ?? 'MEDIUM').toString().toUpperCase(),
      actual: (json['actual'] ?? '').toString(),
      forecast: (json['forecast'] ?? '').toString(),
      previous: (json['previous'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class CalendarRepository {
  final ApiClient _apiClient;

  CalendarRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<EconomicEvent>> getCalendarEvents() async {
    final data = await _apiClient.get(ApiPaths.marketCalendar);
    final items = ResponseReader.list(data, 'events');
    final rawList = items.isNotEmpty ? items : ResponseReader.list(data, 'items');
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => EconomicEvent.fromJson(e))
        .toList();
  }
}

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CalendarRepository(apiClient: apiClient);
});

final calendarEventsProvider = FutureProvider<List<EconomicEvent>>((ref) async {
  final repo = ref.watch(calendarRepositoryProvider);
  return repo.getCalendarEvents();
});

class CorporateActionsFilter {
  final CorporateActionType? type;
  final String searchQuery;
  final bool upcomingOnly;

  const CorporateActionsFilter({
    this.type,
    this.searchQuery = '',
    this.upcomingOnly = false,
  });

  CorporateActionsFilter copyWith({
    CorporateActionType? type,
    String? searchQuery,
    bool? upcomingOnly,
    bool clearType = false,
  }) {
    return CorporateActionsFilter(
      type: clearType ? null : (type ?? this.type),
      searchQuery: searchQuery ?? this.searchQuery,
      upcomingOnly: upcomingOnly ?? this.upcomingOnly,
    );
  }
}

class CorporateActionsFilterNotifier extends StateNotifier<CorporateActionsFilter> {
  CorporateActionsFilterNotifier() : super(const CorporateActionsFilter());

  void setType(CorporateActionType? type) {
    state = state.copyWith(type: type, clearType: type == null);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setUpcomingOnly(bool upcoming) {
    state = state.copyWith(upcomingOnly: upcoming);
  }

  void reset() {
    state = const CorporateActionsFilter();
  }
}

final corporateActionsFilterProvider = StateNotifierProvider<
    CorporateActionsFilterNotifier, CorporateActionsFilter>((ref) {
  return CorporateActionsFilterNotifier();
});

final filteredCorporateActionsProvider = Provider<List<CorporateAction>>((ref) {
  final allActionsAsync = ref.watch(corporateActionsProvider(null));
  final allActions = allActionsAsync.valueOrNull ?? const [];
  final filter = ref.watch(corporateActionsFilterProvider);

  return allActions.where((action) {
    if (filter.type != null && action.actionType != filter.type) {
      return false;
    }
    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      final matchSym = action.symbol.toLowerCase().contains(q);
      final matchComp = action.companyName.toLowerCase().contains(q);
      if (!matchSym && !matchComp) return false;
    }
    if (filter.upcomingOnly) {
      if (action.exDate.isBefore(DateTime.now())) {
        return false;
      }
    }
    return true;
  }).toList();
});

