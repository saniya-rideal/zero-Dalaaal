import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../data/mock_watchlist_repository.dart';
import '../domain/watchlist_repository.dart';

class WatchlistState {
  final bool isLoading;
  final List<WatchlistGroup> watchlists;
  final int activeIndex;
  final String? errorMessage;

  const WatchlistState({
    this.isLoading = false,
    this.watchlists = const [],
    this.activeIndex = 0,
    this.errorMessage,
  });

  WatchlistGroup? get activeWatchlist =>
      watchlists.isNotEmpty && activeIndex < watchlists.length
          ? watchlists[activeIndex]
          : null;

  WatchlistState copyWith({
    bool? isLoading,
    List<WatchlistGroup>? watchlists,
    int? activeIndex,
    String? errorMessage,
  }) {
    return WatchlistState(
      isLoading: isLoading ?? this.isLoading,
      watchlists: watchlists ?? this.watchlists,
      activeIndex: activeIndex ?? this.activeIndex,
      errorMessage: errorMessage,
    );
  }
}

class WatchlistController extends StateNotifier<WatchlistState> {
  final WatchlistRepository _repo;

  WatchlistController(this._repo) : super(const WatchlistState()) {
    loadWatchlists();
  }

  Future<void> loadWatchlists() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getAllWatchlists();
      state = state.copyWith(
        isLoading: false,
        watchlists: list,
        activeIndex: state.activeIndex < list.length ? state.activeIndex : 0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setActiveIndex(int index) {
    if (index >= 0 && index < state.watchlists.length) {
      state = state.copyWith(activeIndex: index);
    }
  }

  Future<void> createWatchlist(String name) async {
    final newGroup = await _repo.createWatchlist(name);
    final updated = List<WatchlistGroup>.from(state.watchlists)..add(newGroup);
    state = state.copyWith(
      watchlists: updated,
      activeIndex: updated.length - 1,
    );
  }

  Future<void> renameWatchlist(String id, String newName) async {
    await _repo.renameWatchlist(id, newName);
    await loadWatchlists();
  }

  Future<void> deleteWatchlist(String id) async {
    await _repo.deleteWatchlist(id);
    await loadWatchlists();
  }

  Future<void> removeInstrument(String token) async {
    final active = state.activeWatchlist;
    if (active == null) return;
    await _repo.removeInstrument(active.id, token);
    await loadWatchlists();
  }

  Future<void> addInstrumentToActive(String token) async {
    final active = state.activeWatchlist;
    if (active == null) return;
    await _repo.addInstrument(active.id, token);
    await loadWatchlists();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final active = state.activeWatchlist;
    if (active == null) return;
    await _repo.reorderInstruments(active.id, oldIndex, newIndex);
    await loadWatchlists();
  }
}

final watchlistControllerProvider =
    StateNotifierProvider<WatchlistController, WatchlistState>((ref) {
  final repo = ref.watch(watchlistRepositoryProvider);
  return WatchlistController(repo);
});
