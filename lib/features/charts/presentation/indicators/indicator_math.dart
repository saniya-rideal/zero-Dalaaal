import 'dart:math';
import '../../../../data/models/models.dart';

class IndicatorMath {
  IndicatorMath._();

  static List<double?> calculateSma(List<Candle> candles, int period) {
    final List<double?> result = List.filled(candles.length, null);
    if (candles.length < period) return result;

    double sum = 0.0;
    for (int i = 0; i < period; i++) {
      sum += candles[i].close;
    }
    result[period - 1] = sum / period;

    for (int i = period; i < candles.length; i++) {
      sum += candles[i].close - candles[i - period].close;
      result[i] = sum / period;
    }
    return result;
  }

  static List<double?> calculateEma(List<Candle> candles, int period) {
    final List<double?> result = List.filled(candles.length, null);
    if (candles.length < period) return result;

    final k = 2.0 / (period + 1);
    double sum = 0.0;
    for (int i = 0; i < period; i++) {
      sum += candles[i].close;
    }
    double ema = sum / period;
    result[period - 1] = ema;

    for (int i = period; i < candles.length; i++) {
      ema = (candles[i].close * k) + (ema * (1 - k));
      result[i] = ema;
    }
    return result;
  }

  static Map<String, List<double?>> calculateBollinger(List<Candle> candles, int period, double stdDevMultiplier) {
    final sma = calculateSma(candles, period);
    final List<double?> upper = List.filled(candles.length, null);
    final List<double?> lower = List.filled(candles.length, null);

    for (int i = period - 1; i < candles.length; i++) {
      final mean = sma[i]!;
      double sumSquares = 0.0;
      for (int j = i - period + 1; j <= i; j++) {
        sumSquares += pow(candles[j].close - mean, 2);
      }
      final stdDev = sqrt(sumSquares / period);
      upper[i] = mean + (stdDevMultiplier * stdDev);
      lower[i] = mean - (stdDevMultiplier * stdDev);
    }

    return {'middle': sma, 'upper': upper, 'lower': lower};
  }

  static List<double?> calculateRsi(List<Candle> candles, int period) {
    final List<double?> rsi = List.filled(candles.length, null);
    if (candles.length <= period) return rsi;

    double gainSum = 0.0;
    double lossSum = 0.0;

    for (int i = 1; i <= period; i++) {
      final change = candles[i].close - candles[i - 1].close;
      if (change > 0) {
        gainSum += change;
      } else {
        lossSum += change.abs();
      }
    }

    double avgGain = gainSum / period;
    double avgLoss = lossSum / period;

    double rs = avgLoss == 0 ? 100 : avgGain / avgLoss;
    rsi[period] = 100 - (100 / (1 + rs));

    for (int i = period + 1; i < candles.length; i++) {
      final change = candles[i].close - candles[i - 1].close;
      final gain = change > 0 ? change : 0.0;
      final loss = change < 0 ? change.abs() : 0.0;

      avgGain = ((avgGain * (period - 1)) + gain) / period;
      avgLoss = ((avgLoss * (period - 1)) + loss) / period;

      rs = avgLoss == 0 ? 100 : avgGain / avgLoss;
      rsi[i] = 100 - (100 / (1 + rs));
    }

    return rsi;
  }

  static Map<String, List<double?>> calculateMacd(List<Candle> candles, {int fastPeriod = 12, int slowPeriod = 26, int signalPeriod = 9}) {
    final fastEma = calculateEma(candles, fastPeriod);
    final slowEma = calculateEma(candles, slowPeriod);
    final List<double?> macdLine = List.filled(candles.length, null);

    for (int i = slowPeriod - 1; i < candles.length; i++) {
      if (fastEma[i] != null && slowEma[i] != null) {
        macdLine[i] = fastEma[i]! - slowEma[i]!;
      }
    }

    // Signal line is EMA of MACD Line
    final List<double?> signalLine = List.filled(candles.length, null);
    final validMacd = <double>[];
    for (int i = 0; i < candles.length; i++) {
      if (macdLine[i] != null) validMacd.add(macdLine[i]!);
    }

    if (validMacd.length >= signalPeriod) {
      final k = 2.0 / (signalPeriod + 1);
      double sum = 0.0;
      for (int i = 0; i < signalPeriod; i++) {
        sum += validMacd[i];
      }
      double ema = sum / signalPeriod;
      final int macdStartIndex = candles.length - validMacd.length;
      signalLine[macdStartIndex + signalPeriod - 1] = ema;

      for (int i = signalPeriod; i < validMacd.length; i++) {
        ema = (validMacd[i] * k) + (ema * (1 - k));
        signalLine[macdStartIndex + i] = ema;
      }
    }

    final List<double?> histogram = List.filled(candles.length, null);
    for (int i = 0; i < candles.length; i++) {
      if (macdLine[i] != null && signalLine[i] != null) {
        histogram[i] = macdLine[i]! - signalLine[i]!;
      }
    }

    return {'macd': macdLine, 'signal': signalLine, 'histogram': histogram};
  }

  static List<double?> calculateATR(List<Candle> candles, int period) {
    final List<double?> atr = List.filled(candles.length, null);
    if (candles.length <= period) return atr;

    final List<double> trueRanges = [];
    trueRanges.add(candles[0].high - candles[0].low);

    for (int i = 1; i < candles.length; i++) {
      final h = candles[i].high;
      final l = candles[i].low;
      final prevC = candles[i - 1].close;
      final tr = max(h - l, max((h - prevC).abs(), (l - prevC).abs()));
      trueRanges.add(tr);
    }

    double sum = 0.0;
    for (int i = 0; i < period; i++) {
      sum += trueRanges[i];
    }
    double currentAtr = sum / period;
    atr[period - 1] = currentAtr;

    for (int i = period; i < candles.length; i++) {
      currentAtr = ((currentAtr * (period - 1)) + trueRanges[i]) / period;
      atr[i] = currentAtr;
    }

    return atr;
  }

  static Map<String, List<double?>> calculateStochastic(List<Candle> candles, {int period = 14, int smoothK = 3, int smoothD = 3}) {
    final List<double?> percentK = List.filled(candles.length, null);
    final List<double?> percentD = List.filled(candles.length, null);
    if (candles.length < period) return {'k': percentK, 'd': percentD};

    for (int i = period - 1; i < candles.length; i++) {
      double highestHigh = -double.infinity;
      double lowestLow = double.infinity;

      for (int j = i - period + 1; j <= i; j++) {
        highestHigh = max(highestHigh, candles[j].high);
        lowestLow = min(lowestLow, candles[j].low);
      }

      final range = highestHigh - lowestLow;
      if (range > 0) {
        percentK[i] = ((candles[i].close - lowestLow) / range) * 100.0;
      } else {
        percentK[i] = 50.0;
      }
    }

    // Smooth D
    for (int i = period + smoothD - 2; i < candles.length; i++) {
      double sum = 0.0;
      int count = 0;
      for (int j = i - smoothD + 1; j <= i; j++) {
        if (percentK[j] != null) {
          sum += percentK[j]!;
          count++;
        }
      }
      if (count > 0) percentD[i] = sum / count;
    }

    return {'k': percentK, 'd': percentD};
  }

  static List<double?> calculateVWAP(List<Candle> candles) {
    final List<double?> vwap = List.filled(candles.length, null);
    double cumulativeVolumePrice = 0.0;
    double cumulativeVolume = 0.0;

    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final typicalPrice = (c.high + c.low + c.close) / 3.0;
      final volume = c.volume > 0 ? c.volume.toDouble() : 100.0;

      cumulativeVolumePrice += (typicalPrice * volume);
      cumulativeVolume += volume;

      vwap[i] = cumulativeVolume > 0 ? (cumulativeVolumePrice / cumulativeVolume) : typicalPrice;
    }
    return vwap;
  }
}
