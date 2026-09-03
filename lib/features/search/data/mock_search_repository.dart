import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/mock/seed_instruments.dart';
import '../../../data/models/models.dart';
import '../domain/search_repository.dart';

class MockSearchRepository implements SearchRepository {
  final List<String> _recentSearches = ['RELIANCE', 'TCS', 'ZOMATO', 'NIFTY 50'];

  @override
  Future<List<Instrument>> search(String query, {Exchange? exchange, InstrumentType? type}) async {
    final cleanQuery = query.trim().toUpperCase();
    var list = SeedInstruments.all;

    if (cleanQuery.isNotEmpty) {
      list = list.where((i) {
        return i.symbol.toUpperCase().contains(cleanQuery) ||
            i.name.toUpperCase().contains(cleanQuery);
      }).toList();
    }

    if (exchange != null) {
      list = list.where((i) => i.exchange == exchange).toList();
    }

    if (type != null) {
      list = list.where((i) => i.type == type).toList();
    }

    return list;
  }

  @override
  Future<List<Instrument>> getTrending() async {
    return [
      SeedInstruments.findByToken('eq_zomato')!,
      SeedInstruments.findByToken('eq_jiofin')!,
      SeedInstruments.findByToken('eq_suzlon')!,
      SeedInstruments.findByToken('eq_trent')!,
      SeedInstruments.findByToken('eq_reliance')!,
      SeedInstruments.findByToken('eq_tatamotors')!,
    ];
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
  return MockSearchRepository();
});
