import 'dart:math';
import '../models/models.dart';

class CandleGenerator {
  CandleGenerator._();

  static final Map<String, double> basePrices = {
    'idx_nifty50': 25150.0,
    'idx_niftybank': 51300.0,
    'idx_sensex': 82350.0,
    'idx_niftyit': 42800.0,
    'idx_finnifty': 23450.0,
    'eq_reliance': 2985.50,
    'eq_tcs': 4215.00,
    'eq_hdfcbank': 1648.20,
    'eq_icicibank': 1224.75,
    'eq_infy': 1885.30,
    'eq_itc': 502.40,
    'eq_bhartiartl': 1565.00,
    'eq_sbin': 815.20,
    'eq_lici': 1045.00,
    'eq_hindunilvr': 2780.00,
    'eq_lt': 3650.00,
    'eq_bajfinance': 7350.00,
    'eq_maruti': 12450.00,
    'eq_hcltech': 1760.00,
    'eq_sunpharma': 1820.00,
    'eq_tatamotors': 1085.00,
    'eq_ntpc': 412.00,
    'eq_axisbank': 1180.00,
    'eq_ongc': 324.00,
    'eq_titan': 3620.00,
    'eq_adanient': 3040.00,
    'eq_kotakbank': 1810.00,
    'eq_coalindia': 518.00,
    'eq_powergrid': 338.00,
    'eq_tatasteel': 154.50,
    'eq_mm': 2780.00,
    'eq_bajajfinsv': 1845.00,
    'eq_jswsteel': 945.00,
    'eq_adaniports': 1485.00,
    'eq_ultracemco': 11250.00,
    'eq_asianpaint': 3140.00,
    'eq_siemens': 6850.00,
    'eq_nestleind': 2520.00,
    'eq_wipro': 532.00,
    'eq_ioc': 178.00,
    'eq_bpcl': 354.00,
    'eq_grasim': 2680.00,
    'eq_techm': 1610.00,
    'eq_hindalco': 682.00,
    'eq_heromotoco': 5450.00,
    'eq_cipla': 1640.00,
    'eq_sbilife': 1820.00,
    'eq_drreddy': 6680.00,
    'eq_eichermot': 4850.00,
    'eq_britannia': 5920.00,
    'eq_tataconsum': 1195.00,
    'eq_apollohosp': 6890.00,
    'eq_divislab': 5230.00,
    'eq_bajajauto': 10450.00,
    'eq_indusindbk': 1440.00,
    'eq_zomato': 264.50,
    'eq_paytm': 642.00,
    'eq_jiofin': 348.00,
    'eq_irfc': 178.50,
    'eq_rvnl': 565.00,
    'eq_suzlon': 74.50,
    'eq_trent': 7120.00,
    'eq_bel': 298.00,
    'eq_hal': 4720.00,
    'eq_bhel': 292.00,
    'eq_yesbank': 24.20,
    'eq_idea': 15.80,
    'eq_vedl': 462.00,
    'eq_polycab': 6750.00,
    'eq_cdsl': 1580.00,
    'eq_bse': 2940.00,
    'eq_angelone': 2560.00,
    'eq_mcx': 5480.00,
    'eq_dmart': 4920.00,
    'eq_nykaa': 214.00,
    'eq_policybzr': 1750.00,
    'mcx_copper': 1373.50,
    'mcx_gold': 71450.00,
    'mcx_silver': 83200.00,
    'mcx_crudeoil': 6250.00,
    'mcx_naturalgas': 195.40,
    'copper_mcx': 1373.50,
    'copper': 1373.50,
    'gold_mcx': 71450.00,
    'crude_mcx': 6250.00,
    'natgas_mcx': 195.40,
    'fx_usdinr': 83.94,
    'fx_eurinr': 92.40,
    'fx_gbpinr': 109.85,
    'fx_eurusd': 1.1045,
    'crypto_btcusd': 58450.00,
    'crypto_ethusd': 2510.00,
    'crypto_solusd': 134.20,
    'global_us500': 5520.00,
    'global_nasdaq': 19340.00,
    'global_dow': 40980.00,
  };

  static double getBasePrice(String token) {
    if (basePrices.containsKey(token)) {
      return basePrices[token]!;
    }
    final lower = token.toLowerCase();
    if (lower.contains('btc') || lower.contains('bitcoin')) return 58450.00;
    if (lower.contains('eth') || lower.contains('ethereum')) return 2510.00;
    if (lower.contains('sol') || lower.contains('solana')) return 134.20;
    if (lower.contains('usdinr') || lower.contains('usd_inr')) return 83.94;
    if (lower.contains('eurinr') || lower.contains('eur_inr')) return 92.40;
    if (lower.contains('gbpinr') || lower.contains('gbp_inr')) return 109.85;
    if (lower.contains('eurusd') || lower.contains('eur_usd')) return 1.1045;
    if (lower.contains('us500') || lower.contains('s&p')) return 5520.00;
    if (lower.contains('nasdaq') || lower.contains('tech100')) return 19340.00;
    if (lower.contains('dow') || lower.contains('wallst')) return 40980.00;
    if (lower.contains('copper')) return 1373.50;
    if (lower.contains('gold')) return 71450.00;
    if (lower.contains('silver')) return 83200.00;
    if (lower.contains('crude')) return 6250.00;
    if (lower.contains('natural') || lower.contains('gas')) return 195.40;
    return 1000.0;
  }

  static List<Candle> generateCandles({
    required String token,
    required Timeframe timeframe,
    int count = 100,
  }) {
    final basePrice = getBasePrice(token);
    final random = Random(token.hashCode ^ timeframe.index);
    final List<Candle> candles = [];

    // Duration per candle
    Duration step;
    switch (timeframe) {
      case Timeframe.ONE_MIN:
        step = const Duration(minutes: 1);
        break;
      case Timeframe.FIVE_MIN:
        step = const Duration(minutes: 5);
        break;
      case Timeframe.FIFTEEN_MIN:
        step = const Duration(minutes: 15);
        break;
      case Timeframe.THIRTY_MIN:
        step = const Duration(minutes: 30);
        break;
      case Timeframe.ONE_HOUR:
        step = const Duration(hours: 1);
        break;
      case Timeframe.ONE_DAY:
        step = const Duration(days: 1);
        break;
      case Timeframe.ONE_WEEK:
        step = const Duration(days: 7);
        break;
      case Timeframe.ONE_MONTH:
        step = const Duration(days: 30);
        break;
    }

    final now = DateTime.now();
    double currentPrice = basePrice * (0.92 + (random.nextDouble() * 0.16));

    for (int i = count - 1; i >= 0; i--) {
      final candleTime = now.subtract(step * i);
      final volatility = currentPrice * 0.008;
      
      final open = currentPrice;
      final change = (random.nextDouble() - 0.49) * volatility;
      final close = open + change;
      final high = max(open, close) + (random.nextDouble() * volatility * 0.6);
      final low = min(open, close) - (random.nextDouble() * volatility * 0.6);
      final volume = 5000 + (random.nextInt(45000));

      candles.add(Candle(
        time: candleTime,
        open: double.parse(open.toStringAsFixed(2)),
        high: double.parse(high.toStringAsFixed(2)),
        low: double.parse(low.toStringAsFixed(2)),
        close: double.parse(close.toStringAsFixed(2)),
        volume: volume,
      ));

      currentPrice = close;
    }

    return candles;
  }
}
