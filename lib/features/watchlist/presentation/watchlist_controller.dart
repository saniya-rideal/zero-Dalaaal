import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../data/real_watchlist_repository.dart';
import '../domain/watchlist_repository.dart';

class WatchlistState {
  final bool isLoading;
  final WatchlistGroup? watchlist;
  final String? errorMessage;
  final String? lastAddedSymbol;

  const WatchlistState({
    this.isLoading = false,
    this.watchlist,
    this.errorMessage,
    this.lastAddedSymbol,
  });

  // Backward compatibility getters
  List<WatchlistGroup> get watchlists => watchlist != null ? [watchlist!] : const [];
  WatchlistGroup? get activeWatchlist => watchlist;
  int get activeIndex => 0;
  int get symbolCount => watchlist?.instrumentTokens.length ?? 0;
  bool get isFull => symbolCount >= 50;

  WatchlistState copyWith({
    bool? isLoading,
    WatchlistGroup? watchlist,
    String? errorMessage,
    String? lastAddedSymbol,
    bool clearError = false,
    bool clearLastAdded = false,
  }) {
    return WatchlistState(
      isLoading: isLoading ?? this.isLoading,
      watchlist: watchlist ?? this.watchlist,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastAddedSymbol: clearLastAdded ? null : (lastAddedSymbol ?? this.lastAddedSymbol),
    );
  }
}

class WatchlistController extends StateNotifier<WatchlistState> {
  final WatchlistRepository _repo;
  static const int maxSymbols = 50;

  WatchlistController(this._repo) : super(const WatchlistState()) {
    loadWatchlist();
  }

  Future<void> loadWatchlist() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getAllWatchlists();
      WatchlistGroup? defaultGroup;
      for (final w in list) {
        if (w.isDefault) {
          defaultGroup = w;
          break;
        }
      }
      if (defaultGroup == null) {
        if (list.isNotEmpty) {
          defaultGroup = list.first;
        } else {
          defaultGroup = await _repo.createWatchlist('Watchlist');
        }
      }
      state = state.copyWith(
        isLoading: false,
        watchlist: defaultGroup,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Alias for backward compatibility
  Future<void> loadWatchlists() => loadWatchlist();

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  void clearLastAdded() {
    if (state.lastAddedSymbol != null) {
      state = state.copyWith(clearLastAdded: true);
    }
  }

  // Multi-watchlist deprecated stubs for compatibility
  void setActiveIndex(int index) {}
  Future<void> createWatchlist(String name) async => loadWatchlist();
  Future<void> renameWatchlist(String id, String newName) async => loadWatchlist();
  Future<void> deleteWatchlist(String id) async => loadWatchlist();

  Future<bool> addInstrument(String token) async {
    var wl = state.watchlist;
    if (wl == null) {
      await loadWatchlist();
      wl = state.watchlist;
      if (wl == null) return false;
    }

    final tokenClean = token.trim();
    final tokens = List<String>.from(wl.instrumentTokens);
    final exists = tokens.any((t) => t.trim().toUpperCase() == tokenClean.toUpperCase());
    if (exists) return true;

    // Check 50-symbol limit
    if (tokens.length >= maxSymbols) {
      state = state.copyWith(errorMessage: 'MAX_SYMBOLS_EXCEEDED');
      return false;
    }

    final previousTokens = List<String>.from(tokens);
    tokens.insert(0, tokenClean);
    final updatedWl = wl.copyWith(instrumentTokens: tokens);

    // Optimistically show at top and trigger scroll
    state = state.copyWith(
      watchlist: updatedWl,
      lastAddedSymbol: tokenClean,
      clearError: true,
    );

    try {
      await _repo.addInstrument(wl.id, tokenClean);
      return true;
    } catch (e) {
      // Rollback on failure
      final rolledBack = wl.copyWith(instrumentTokens: previousTokens);
      final errMsg = e.toString().contains('MAX_SYMBOLS_EXCEEDED')
          ? 'MAX_SYMBOLS_EXCEEDED'
          : e.toString();
      state = state.copyWith(
        watchlist: rolledBack,
        errorMessage: errMsg,
        clearLastAdded: true,
      );
      return false;
    }
  }

  // Alias for backward compatibility
  Future<bool> addInstrumentToActive(String token) => addInstrument(token);

  Future<bool> removeInstrument(String token) async {
    var wl = state.watchlist;
    if (wl == null) {
      await loadWatchlist();
      wl = state.watchlist;
      if (wl == null) return false;
    }

    final tokenClean = token.trim().toUpperCase();
    final previousTokens = List<String>.from(wl.instrumentTokens);
    if (!previousTokens.any((t) => t.trim().toUpperCase() == tokenClean)) {
      return true;
    }

    final newTokens = List<String>.from(previousTokens)
      ..removeWhere((t) => t.trim().toUpperCase() == tokenClean);

    // Await backend response first, update UI only after success (or roll back with error)
    try {
      await _repo.removeInstrument(wl.id, token.trim());
      final updatedWl = wl.copyWith(instrumentTokens: newTokens);
      state = state.copyWith(watchlist: updatedWl, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove $token: $e');
      return false;
    }
  }

  Future<bool> removeMultiple(List<String> tokensToRemove) async {
    var wl = state.watchlist;
    if (wl == null) {
      await loadWatchlist();
      wl = state.watchlist;
      if (wl == null) return false;
    }
    if (tokensToRemove.isEmpty) return false;

    final previousTokens = List<String>.from(wl.instrumentTokens);
    final removeSet = tokensToRemove.map((t) => t.trim().toUpperCase()).toSet();
    final newTokens = previousTokens
        .where((t) => !removeSet.contains(t.trim().toUpperCase()))
        .toList();

    try {
      for (final t in tokensToRemove) {
        await _repo.removeInstrument(wl.id, t.trim());
      }
      final updatedWl = wl.copyWith(instrumentTokens: newTokens);
      state = state.copyWith(watchlist: updatedWl, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove selected scripts: $e');
      return false;
    }
  }

  Future<bool> reorder(int oldIndex, int newIndex) async {
    var wl = state.watchlist;
    if (wl == null) {
      await loadWatchlist();
      wl = state.watchlist;
      if (wl == null) return false;
    }

    final tokens = List<String>.from(wl.instrumentTokens);
    if (oldIndex < 0 || oldIndex >= tokens.length) return false;
    int targetIndex = newIndex;
    if (targetIndex > oldIndex) targetIndex -= 1;
    if (targetIndex < 0 || targetIndex >= tokens.length) return false;

    final previousTokens = List<String>.from(tokens);
    final item = tokens.removeAt(oldIndex);
    tokens.insert(targetIndex, item);

    // Optimistically update
    state = state.copyWith(watchlist: wl.copyWith(instrumentTokens: tokens), clearError: true);

    try {
      await _repo.reorderInstruments(wl.id, oldIndex, newIndex);
      return true;
    } catch (e) {
      // Rollback
      state = state.copyWith(
        watchlist: wl.copyWith(instrumentTokens: previousTokens),
        errorMessage: 'Failed to persist reorder: $e',
      );
      return false;
    }
  }
}

final watchlistControllerProvider =
    StateNotifierProvider<WatchlistController, WatchlistState>((ref) {
  final repo = ref.watch(watchlistRepositoryProvider);
  return WatchlistController(repo);
});
