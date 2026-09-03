import '../../../data/models/models.dart';

abstract class SearchRepository {
  Future<List<Instrument>> search(String query, {Exchange? exchange, InstrumentType? type});
  Future<List<Instrument>> getTrending();
  Future<List<String>> getRecentSearches();
  Future<void> saveRecentSearch(String query);
}
