import '../../../data/models/models.dart';

abstract class MarketRepository {
  Future<List<Instrument>> getInstruments();
  List<Instrument> get cachedInstruments;
  Instrument? findBySymbol(String symbol);
  Future<Map<String, Quote>> getQuotes({List<String>? symbols});
  Future<Quote?> getQuote(String symbol);
  Future<List<Candle>> getCandles(
    String symbol, {
    String interval = '1m',
    int limit = 100,
    int? from,
    int? to,
  });
  Future<List<Instrument>> searchInstruments(
    String query, {
    Exchange? exchange,
    InstrumentType? type,
  });
  Future<Map<String, dynamic>> getMarketStatus();
  Future<List<dynamic>> getMarketHolidays({int? year});
}
