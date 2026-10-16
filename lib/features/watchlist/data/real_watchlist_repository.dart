import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/models.dart';
import '../domain/watchlist_repository.dart';

class RealWatchlistRepository implements WatchlistRepository {
  final ApiClient _apiClient;
  List<WatchlistGroup> _cache = [];

  RealWatchlistRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<WatchlistGroup>> getAllWatchlists() async {
    final data = await _apiClient.get(ApiPaths.watchlists);
    final items = ResponseReader.list(data, 'watchlists');
    final list = items
        .whereType<Map<String, dynamic>>()
        .map((e) => WatchlistGroup.fromJson(e))
        .toList();
    _cache = list;
    return list;
  }

  @override
  Future<WatchlistGroup> createWatchlist(String name) async {
    final data = await _apiClient.post(
      ApiPaths.watchlists,
      data: {'name': name.trim()},
    );

    final obj = ResponseReader.object(data, 'watchlist');
    final group = WatchlistGroup.fromJson(obj.isNotEmpty ? obj : {'name': name});
    _cache.add(group);
    return group;
  }

  @override
  Future<void> renameWatchlist(String id, String newName) async {
    await _apiClient.put(
      ApiPaths.watchlistDetail(id),
      data: {'name': newName.trim()},
    );

    final index = _cache.indexWhere((w) => w.id == id);
    if (index != -1) {
      _cache[index] = _cache[index].copyWith(name: newName);
    }
  }

  @override
  Future<void> deleteWatchlist(String id) async {
    await _apiClient.delete(ApiPaths.watchlistDetail(id));
    _cache.removeWhere((w) => w.id == id);
  }

  @override
  Future<void> addInstrument(String watchlistId, String token) async {
    if (_cache.isEmpty) {
      await getAllWatchlists();
    }

    final index = _cache.indexWhere((w) => w.id == watchlistId);
    List<String> currentTokens = index != -1 ? List.from(_cache[index].instrumentTokens) : [];

    if (!currentTokens.contains(token)) {
      currentTokens.add(token);
      if (currentTokens.length > 50) {
        currentTokens = currentTokens.take(50).toList();
      }

      await _apiClient.put(
        ApiPaths.watchlistDetail(watchlistId),
        data: {'symbols': currentTokens},
      );

      if (index != -1) {
        _cache[index] = _cache[index].copyWith(instrumentTokens: currentTokens);
      }
    }
  }

  @override
  Future<void> removeInstrument(String watchlistId, String token) async {
    if (_cache.isEmpty) {
      await getAllWatchlists();
    }

    final index = _cache.indexWhere((w) => w.id == watchlistId);
    if (index != -1) {
      final currentTokens = List<String>.from(_cache[index].instrumentTokens)..remove(token);

      await _apiClient.put(
        ApiPaths.watchlistDetail(watchlistId),
        data: {'symbols': currentTokens},
      );

      _cache[index] = _cache[index].copyWith(instrumentTokens: currentTokens);
    }
  }

  @override
  Future<void> reorderInstruments(String watchlistId, int oldIndex, int newIndex) async {
    if (_cache.isEmpty) {
      await getAllWatchlists();
    }

    final index = _cache.indexWhere((w) => w.id == watchlistId);
    if (index != -1) {
      final list = List<String>.from(_cache[index].instrumentTokens);
      if (newIndex > oldIndex) newIndex -= 1;
      if (oldIndex < list.length && newIndex <= list.length) {
        final item = list.removeAt(oldIndex);
        list.insert(newIndex, item);

        await _apiClient.put(
          ApiPaths.watchlistDetail(watchlistId),
          data: {'symbols': list},
        );

        _cache[index] = _cache[index].copyWith(instrumentTokens: list);
      }
    }
  }
}

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RealWatchlistRepository(apiClient: apiClient);
});
