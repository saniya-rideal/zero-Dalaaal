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
    try {
      final data = await _apiClient.get(ApiPaths.watchlists);
      final items = ResponseReader.list(data, 'watchlists');
      final rawList = items.isNotEmpty ? items : ResponseReader.list(data, 'items');
      final list = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => WatchlistGroup.fromJson(e))
          .toList();
      if (list.isNotEmpty) {
        _cache = list;
        return list;
      }
    } catch (_) {}

    if (_cache.isEmpty) {
      _cache = [
        const WatchlistGroup(
          id: 'wl_default',
          name: 'Watchlist',
          instrumentTokens: [],
          isDefault: true,
        ),
      ];
    }
    return _cache;
  }

  @override
  Future<WatchlistGroup> createWatchlist(String name) async {
    WatchlistGroup? group;
    final wlName = name.trim().isEmpty ? 'Watchlist' : name.trim();
    try {
      final data = await _apiClient.post(
        ApiPaths.watchlists,
        data: {'name': wlName},
      );

      final obj = ResponseReader.object(data, 'watchlist');
      if (obj.isNotEmpty) {
        group = WatchlistGroup.fromJson(obj);
      }
    } catch (_) {}

    group ??= WatchlistGroup(
      id: 'wl_${DateTime.now().millisecondsSinceEpoch}',
      name: wlName,
      instrumentTokens: [],
      isDefault: true,
    );

    _cache.removeWhere((w) => w.id == 'wl_default');
    _cache.add(group);
    return group;
  }

  @override
  Future<void> renameWatchlist(String id, String newName) async {
    final index = _cache.indexWhere((w) => w.id == id);
    if (index != -1) {
      _cache[index] = _cache[index].copyWith(name: newName.trim());
    }

    await _apiClient.put(
      ApiPaths.watchlistDetail(id),
      data: {'name': newName.trim()},
    );
  }

  @override
  Future<void> deleteWatchlist(String id) async {
    _cache.removeWhere((w) => w.id == id);
    await _apiClient.delete(ApiPaths.watchlistDetail(id));
  }

  @override
  Future<void> addInstrument(String watchlistId, String token) async {
    if (_cache.isEmpty) {
      await getAllWatchlists();
    }

    final tokenClean = token.trim();
    final index = _cache.indexWhere((w) => w.id == watchlistId);
    final List<String> currentTokens = index != -1
        ? List<String>.from(_cache[index].instrumentTokens)
        : [];

    final exists = currentTokens.any((t) => t.trim().toUpperCase() == tokenClean.toUpperCase());
    if (!exists) {
      if (currentTokens.length >= 50) {
        throw Exception('MAX_SYMBOLS_EXCEEDED');
      }
      currentTokens.insert(0, tokenClean);
      if (index != -1) {
        _cache[index] = _cache[index].copyWith(instrumentTokens: currentTokens);
      }
    }

    try {
      await _apiClient.put(
        ApiPaths.watchlistDetail(watchlistId),
        data: {'symbols': currentTokens},
      );
    } catch (e) {
      if (e.toString().contains('MAX_SYMBOLS_EXCEEDED')) {
        throw Exception('MAX_SYMBOLS_EXCEEDED');
      }
      rethrow;
    }
  }

  @override
  Future<void> removeInstrument(String watchlistId, String token) async {
    if (_cache.isEmpty) {
      await getAllWatchlists();
    }

    final tokenClean = token.trim().toUpperCase();
    final index = _cache.indexWhere((w) => w.id == watchlistId);
    final List<String> currentTokens = index != -1
        ? List<String>.from(_cache[index].instrumentTokens)
        : [];
    currentTokens.removeWhere((t) => t.trim().toUpperCase() == tokenClean);

    if (index != -1) {
      _cache[index] = _cache[index].copyWith(instrumentTokens: currentTokens);
    }

    await _apiClient.put(
      ApiPaths.watchlistDetail(watchlistId),
      data: {'symbols': currentTokens},
    );
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
        _cache[index] = _cache[index].copyWith(instrumentTokens: list);

        await _apiClient.put(
          ApiPaths.watchlistDetail(watchlistId),
          data: {'symbols': list},
        );
      }
    }
  }
}

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RealWatchlistRepository(apiClient: apiClient);
});
