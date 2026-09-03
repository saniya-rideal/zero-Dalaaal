import '../../../data/models/models.dart';

abstract class WatchlistRepository {
  Future<List<WatchlistGroup>> getAllWatchlists();
  Future<WatchlistGroup> createWatchlist(String name);
  Future<void> renameWatchlist(String id, String newName);
  Future<void> deleteWatchlist(String id);
  Future<void> addInstrument(String watchlistId, String token);
  Future<void> removeInstrument(String watchlistId, String token);
  Future<void> reorderInstruments(String watchlistId, int oldIndex, int newIndex);
}
