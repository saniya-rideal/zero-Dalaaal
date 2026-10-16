import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../market/data/real_market_repository.dart';
import '../../market/domain/market_repository.dart';
import '../domain/search_repository.dart';

class RealSearchRepository implements SearchRepository {
  final MarketRepository _marketRepository;
  final List<String> _recentSearches = ['RELIANCE', 'TCS', 'INFY', 'NIFTY'];

  RealSearchRepository({required MarketRepository marketRepository})
      : _marketRepository = marketRepository;

  @override
  Future<List<Instrument>> search(
    String query, {
    Exchange? exchange,
    InstrumentType? type,
  }) async {
    return _marketRepository.searchInstruments(
      query,
      exchange: exchange,
      type: type,
    );
  }

  @override
  Future<List<Instrument>> getTrending() async {
    final all = await _marketRepository.getInstruments();
    if (all.length >= 6) {
      return all.take(6).toList();
    }
    return all;
  }

  @override
  Future<List<String>> getRecentSearches() async {
    return List.unmodifiable(_recentSearches);
  }

  @override
  Future<void> saveRecentSearch(String query) async {
    final trimmed = query.trim().toUpperCase();
    if (trimmed.isNotEmpty) {
      _recentSearches.remove(trimmed);
      _recentSearches.insert(0, trimmed);
      if (_recentSearches.length > 8) _recentSearches.removeLast();
    }
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final marketRepo = ref.watch(marketRepositoryProvider);
  return RealSearchRepository(marketRepository: marketRepo);
});
