import 'package:zero_dalali/data/models/models.dart';
import 'package:zero_dalali/features/watchlist/domain/watchlist_repository.dart';

class FakeWatchlistRepository implements WatchlistRepository {
  final List<WatchlistGroup> _watchlists = [
    const WatchlistGroup(id: 'wl_default', name: 'Nifty 50', instrumentTokens: []),
  ];

  @override
  Future<List<WatchlistGroup>> getAllWatchlists() async => List.unmodifiable(_watchlists);

  @override
  Future<WatchlistGroup> createWatchlist(String name) async {
    final group = WatchlistGroup(
      id: 'wl_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      instrumentTokens: const [],
    );
    _watchlists.add(group);
    return group;
  }

  @override
  Future<void> renameWatchlist(String id, String newName) async {
    final idx = _watchlists.indexWhere((w) => w.id == id);
    if (idx != -1) {
      _watchlists[idx] = _watchlists[idx].copyWith(name: newName);
    }
  }

  @override
  Future<void> deleteWatchlist(String id) async {
    _watchlists.removeWhere((w) => w.id == id);
  }

  @override
  Future<void> addInstrument(String watchlistId, String instrumentToken) async {}

  @override
  Future<void> removeInstrument(String watchlistId, String instrumentToken) async {}

  @override
  Future<void> reorderInstruments(String watchlistId, int oldIndex, int newIndex) async {}
}
