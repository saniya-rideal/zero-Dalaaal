enum Exchange { NSE, BSE, NFO, MCX, CDS }

enum InstrumentType { EQ, FUT, CE, PE, INDEX }

enum TransactionType { BUY, SELL }

enum ProductType { CNC, MIS, NRML }

enum OrderVariety { REGULAR, BO, CO, AMO, GTT }

enum OrderKind { MARKET, LIMIT, SL, SL_M }

enum OrderStatus {
  OPEN,
  TRIGGER_PENDING,
  PARTIALLY_FILLED,
  COMPLETE,
  CANCELLED,
  REJECTED
}

enum Validity { DAY, IOC }

enum Segment { EQUITY, COMMODITY }

enum SipFrequency { DAILY, WEEKLY, MONTHLY }

enum SipStatus { ACTIVE, PAUSED, CANCELLED, COMPLETED }

enum AlertCondition { ABOVE, BELOW, PERCENT_CHANGE }

enum AlertStatus { ACTIVE, TRIGGERED, EXPIRED }

enum IpoStatus { UPCOMING, CURRENT, CLOSED }

enum Timeframe {
  ONE_MIN('1m'),
  FIVE_MIN('5m'),
  FIFTEEN_MIN('15m'),
  THIRTY_MIN('30m'),
  ONE_HOUR('1H'),
  ONE_DAY('1D'),
  ONE_WEEK('1W'),
  ONE_MONTH('1M');

  final String label;
  const Timeframe(this.label);
}

enum ChartType { candle, line, bar }
