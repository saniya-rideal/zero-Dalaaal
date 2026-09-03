# Data Models & API Contracts
## Zero — Frontend Data Layer Spec

These are the contracts every repository interface returns. Written as if a real backend already existed (same shapes usable later when [[trading-learning-platform]]-style backend, or a real broker API, is wired in) — the mock datasource just serves these shapes from local JSON/Hive instead of HTTP.

---

## 1. Core Entities (Dart `freezed` models)

```dart
class Instrument {
  final String token;          // unique instrument identifier
  final String symbol;         // e.g. "RELIANCE"
  final String name;           // "Reliance Industries Ltd"
  final Exchange exchange;     // NSE, BSE, NFO, MCX, CDS
  final InstrumentType type;   // EQ, FUT, CE, PE, INDEX
  final double lotSize;
  final double tickSize;
  final DateTime? expiry;      // for F&O
  final double? strike;        // for options
}

class Quote {
  final String token;
  final double ltp;
  final double open, high, low, close, prevClose;
  final double change, changePercent;
  final int volume;
  final MarketDepth depth;
  final DateTime timestamp;
}

class MarketDepth {
  final List<DepthLevel> buy;   // 5 levels
  final List<DepthLevel> sell;  // 5 levels
}
class DepthLevel { final double price; final int qty; final int orders; }

class Candle {
  final DateTime time;
  final double open, high, low, close;
  final int volume;
}

class WatchlistGroup {
  final String id;
  final String name;
  final List<String> instrumentTokens;
  final List<WatchlistFolder> folders; // custom groups within a watchlist
}
class WatchlistFolder { final String name; final List<String> instrumentTokens; }

enum ProductType { CNC, MIS, NRML }
enum OrderVariety { REGULAR, BO, CO, AMO, GTT }
enum OrderKind { MARKET, LIMIT, SL, SL_M }
enum OrderStatus { OPEN, TRIGGER_PENDING, PARTIALLY_FILLED, COMPLETE, CANCELLED, REJECTED }
enum Validity { DAY, IOC }

class OrderRequest {
  final String instrumentToken;
  final TransactionType side;      // BUY, SELL
  final ProductType product;
  final OrderKind kind;
  final int quantity;
  final double? price;             // required for LIMIT/SL
  final double? triggerPrice;      // required for SL/SL_M
  final Validity validity;
  final int disclosedQty;
  final OrderVariety variety;
  final BracketParams? bracket;    // target/SL/trailingSL for BO
}
class BracketParams { final double target; final double stopLoss; final double? trailingSl; }

class Order {
  final String orderId;
  final String exchangeOrderId;
  final Instrument instrument;
  final OrderRequest request;
  final OrderStatus status;
  final int filledQty;
  final double averagePrice;
  final DateTime placedAt;
  final List<OrderEvent> timeline;
  final ChargesBreakdown charges;
}
class OrderEvent { final OrderStatus status; final DateTime at; }
class ChargesBreakdown {
  final double brokerage;      // 0
  final double stt;
  final double exchangeTxnCharge;
  final double gst;
  final double sebiCharges;
  final double stampDuty;
  double get total => brokerage + stt + exchangeTxnCharge + gst + sebiCharges + stampDuty;
}

class Position {
  final Instrument instrument;
  final ProductType product;
  final int buyQty, sellQty, netQty;
  final double buyAvg, sellAvg;
  final double ltp;
  final double realizedPnl, unrealizedPnl;
  final bool isDayPosition;
}

class Holding {
  final Instrument instrument;
  final int quantity;
  final double averagePrice;
  final double ltp;
  final DateTime firstBuyDate;
}

class FundsSummary {
  final Segment segment;         // EQUITY, COMMODITY
  final double availableMargin;
  final double usedMargin;
  final double openingBalance;
}
class LedgerEntry { final DateTime date; final String narration; final double credit; final double debit; final double runningBalance; }

class Basket {
  final String id;
  final String name;
  final List<OrderRequest> legs;
  final DateTime createdAt;
}

class Sip {
  final String id;
  final Instrument instrument;
  final double amount;
  final SipFrequency frequency;   // DAILY, WEEKLY, MONTHLY
  final DateTime startDate;
  final int totalInstallments;
  final int completedInstallments;
  final SipStatus status;         // ACTIVE, PAUSED, CANCELLED, COMPLETED
}

class PriceAlert {
  final String id;
  final List<String> instrumentTokens;  // supports multi-instrument alert
  final AlertCondition condition;       // ABOVE, BELOW, PERCENT_CHANGE
  final double targetValue;
  final AlertStatus status;             // ACTIVE, TRIGGERED, EXPIRED
}

class IpoListing {
  final String id;
  final String companyName;
  final DateTime openDate, closeDate;
  final double priceBandLow, priceBandHigh;
  final int lotSize;
  final IpoStatus status;   // UPCOMING, CURRENT, CLOSED
}

class OptionChainRow {
  final double strike;
  final OptionLeg call;
  final OptionLeg put;
}
class OptionLeg { final double ltp; final int oi; final int changeInOi; final double iv; final int volume; final String token; }
```

## 2. Repository Interfaces (one per feature — implemented by Mock now, Remote later)

```dart
abstract class WatchlistRepository {
  Future<List<WatchlistGroup>> getAll();
  Future<void> save(WatchlistGroup group);
  Future<void> addInstrument(String watchlistId, String token);
  Future<void> removeInstrument(String watchlistId, String token);
}

abstract class QuoteRepository {
  Future<Quote> getQuote(String token);
  Stream<Quote> subscribe(String token);       // TickerService-backed
  Future<List<Candle>> getHistory(String token, Timeframe tf, DateTimeRange range);
}

abstract class OrdersRepository {
  Future<Order> placeOrder(OrderRequest req);
  Future<void> modifyOrder(String orderId, OrderRequest updated);
  Future<void> cancelOrder(String orderId);
  Future<List<Order>> getPending();
  Future<List<Order>> getExecuted();
}

abstract class GttRepository {
  Future<List<GttOrder>> getAll();
  Future<GttOrder> create(GttRequest req);
  Future<void> delete(String id);
}

abstract class PositionsRepository {
  Future<List<Position>> getDay();
  Future<List<Position>> getNet();
  Future<void> exit(String positionId, {int? partialQty});
  Future<void> convert(String positionId, ProductType to);
}

abstract class PortfolioRepository {
  Future<List<Holding>> getHoldings();
  Future<PortfolioSummary> getSummary();
}

abstract class FundsRepository {
  Future<FundsSummary> getSummary(Segment segment);
  Future<List<LedgerEntry>> getLedger(Segment segment);
  Future<void> addFunds(double amount, PaymentMethod method);
  Future<void> withdrawFunds(double amount, String bankAccountId);
}

abstract class BasketRepository {
  Future<List<Basket>> getAll();
  Future<Basket> create(String name, List<OrderRequest> legs);
  Future<List<Order>> execute(String basketId);
}

abstract class SipRepository {
  Future<List<Sip>> getAll();
  Future<Sip> create(SipRequest req);
  Future<void> pause(String id);
  Future<void> cancel(String id);
}

abstract class AlertsRepository {
  Future<List<PriceAlert>> getAll();
  Future<PriceAlert> create(AlertRequest req);
  Future<void> delete(String id);
}

abstract class IpoRepository {
  Future<List<IpoListing>> getAll({IpoStatus? filter});
  Future<IpoApplication> apply(String ipoId, IpoApplicationRequest req);
}

abstract class OptionChainRepository {
  Future<List<DateTime>> getExpiries(String underlyingToken);
  Future<List<OptionChainRow>> getChain(String underlyingToken, DateTime expiry);
}

abstract class SearchRepository {
  Future<List<Instrument>> search(String query, {List<Exchange>? exchanges});
}

abstract class AuthRepository {
  Future<Session> login(String userId, String password);
  Future<Session> verifyTotp(String code);
  Future<bool> verifyPin(String pin);
  Future<void> logout();
}
```

## 3. Mock Data Generation Rules

- **Instruments seed set:** ~150 curated NSE/BSE equities (Nifty 50 + Bank Nifty constituents + a handful of BSE-only names) + Nifty/Bank Nifty/Sensex index rows + a generated NFO option chain (weekly + monthly expiries) for NIFTY and BANKNIFTY.
- **Historical candles:** deterministic seeded random-walk generator (fixed seed per instrument so re-runs are visually consistent during dev), producing 1m granularity for the last 60 days + daily granularity for 5 years, then aggregated up to all other timeframes.
- **Live ticks:** `TickerService` mutates LTP by a small seeded-random delta every 1–2s for any subscribed token, recalculates day change and re-emits `Quote`.
- **Order fill simulation:** Market → fill after ~800ms at current LTP ± tiny slippage. Limit/SL/SL-M → checked against each tick; fills when crossed.
- **Charges formulas (illustrative, equity delivery example):** STT = 0.1% on sell side (delivery), Exchange txn charge ≈ 0.00297% of turnover, GST = 18% on (brokerage + exchange txn charge), SEBI charges ≈ ₹10/crore, Stamp duty = 0.015% on buy side — brokerage fixed at ₹0. (Constants live in `core/constants/charges_config.dart` so they're easy to tune without touching business logic.)

## 4. Swap-to-Real-Backend Path (future)

1. Implement `RemoteXRepository` per interface using `dio` against real endpoints (or the [[trading-learning-platform]] Node/Express backend, which already exposes a similar virtual-trading-engine shape).
2. Point `TickerService` at a real WebSocket (Socket.IO, same pattern already used in that backend) instead of the seeded random walk.
3. Flip `AppConfig.useMockData` → `false`; Riverpod provider overrides in `app/providers_bootstrap.dart` are the only edit point.
