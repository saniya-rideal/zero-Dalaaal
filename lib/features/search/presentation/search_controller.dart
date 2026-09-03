import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../data/mock_search_repository.dart';
import '../domain/search_repository.dart';

class SearchState {
  final bool isLoading;
  final String query;
  final Exchange? selectedExchange;
  final List<Instrument> results;
  final List<Instrument> trending;
  final List<String> recent;

  const SearchState({
    this.isLoading = false,
    this.query = '',
    this.selectedExchange,
    this.results = const [],
    this.trending = const [],
    this.recent = const [],
  });

  SearchState copyWith({
    bool? isLoading,
    String? query,
    Exchange? selectedExchange,
    bool clearExchange = false,
    List<Instrument>? results,
    List<Instrument>? trending,
    List<String>? recent,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      selectedExchange: clearExchange ? null : (selectedExchange ?? this.selectedExchange),
      results: results ?? this.results,
      trending: trending ?? this.trending,
      recent: recent ?? this.recent,
    );
  }
}

class InstrumentSearchController extends StateNotifier<SearchState> {
  final SearchRepository _repo;

  InstrumentSearchController(this._repo) : super(const SearchState()) {
    _init();
  }

  Future<void> _init() async {
    final trending = await _repo.getTrending();
    final recent = await _repo.getRecentSearches();
    state = state.copyWith(trending: trending, recent: recent);
  }

  Future<void> onQueryChanged(String query) async {
    state = state.copyWith(query: query, isLoading: true);
    final results = await _repo.search(
      query,
      exchange: state.selectedExchange,
    );
    state = state.copyWith(results: results, isLoading: false);
  }

  Future<void> setExchangeFilter(Exchange? exchange) async {
    if (state.selectedExchange == exchange) {
      state = state.copyWith(clearExchange: true, isLoading: true);
    } else {
      state = state.copyWith(selectedExchange: exchange, isLoading: true);
    }
    final results = await _repo.search(
      state.query,
      exchange: state.selectedExchange,
    );
    state = state.copyWith(results: results, isLoading: false);
  }

  Future<void> recordSearch(String query) async {
    await _repo.saveRecentSearch(query);
    final recent = await _repo.getRecentSearches();
    state = state.copyWith(recent: recent);
  }
}

final searchControllerProvider =
    StateNotifierProvider<InstrumentSearchController, SearchState>((ref) {
  final repo = ref.watch(searchRepositoryProvider);
  return InstrumentSearchController(repo);
});
