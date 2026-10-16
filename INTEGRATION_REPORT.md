# Zero-Dalaal Flutter App - Integration Report

## 1. Overview & Architecture
- **Repository:** **PART B - Flutter Mobile Application** (`zero-Dalaaal`).
- **Target State:** Zero-Dalaal Paper Trading Shared API Contract (REST + Socket.IO).
- **Core Architecture:** Flutter + Riverpod + Dio with clean domain/data repository pattern, centralized `ResponseReader` envelope unwrap logic, WebSocket real-time quotes with REST polling fallback, session-bound Idempotency keys, and zero frontend financial calculations.

---

## 2. Key Improvements & Fixes

### A. Centralized Response Envelope Unwrapping
- Created [lib/core/network/response_reader.dart](file:///g:/Projects/zero-Dalaaal/lib/core/network/response_reader.dart) to reliably extract payload data and lists from `{ success: true, message: '...', data: { ... } }` and bare structures.
- **Repository Mappings:**
  - **Instruments:** `ResponseReader.list(data, 'items')`
  - **Quotes:** `ResponseReader.list(data, 'quotes')` / symbol-keyed map unwrap
  - **Watchlists:** `ResponseReader.list(data, 'watchlists')` and `ResponseReader.object(data, 'watchlist')`
  - **Orders, Deals, History, Ledger, Deposits, Withdrawals:** `ResponseReader.list(data, 'items')`
  - **Positions:** `ResponseReader.list(data, 'positions')`
  - **Single Order / Position:** `ResponseReader.object(data, 'order')` / `ResponseReader.object(data, 'position')`
  - **Funds Summary:** `ResponseReader.object(data, 'summary')`
  - **Receipt:** `ResponseReader.object(data, 'receipt')`

### B. Strict Error Handling & No Silent Fallbacks
- Removed all silent `catch (_) {}` fallbacks in `Real*Repository` classes.
- When `USE_MOCK_DATA=false`, failures propagate `AppException` so the UI renders clear error states with a Retry action. The app never falls back to `SeedInstruments` in non-mock mode.

### C. Dynamic Backend Instrument Resolution (Non-Mock Mode)
- In non-mock mode (`USE_MOCK_DATA=false`), all screens ([QuotesScreen](file:///g:/Projects/zero-Dalaaal/lib/features/quotes/presentation/quotes_screen.dart), [WatchlistScreen](file:///g:/Projects/zero-Dalaaal/lib/features/watchlist/presentation/watchlist_screen.dart), [QuoteDetailScreen](file:///g:/Projects/zero-Dalaaal/lib/features/quote_detail/presentation/quote_detail_screen.dart), [ChartFullscreenScreen](file:///g:/Projects/zero-Dalaaal/lib/features/charts/presentation/chart_fullscreen_screen.dart), [ScriptSelectorBar](file:///g:/Projects/zero-Dalaaal/lib/shared_widgets/script_selector_bar.dart), [MarginCalculatorScreen](file:///g:/Projects/zero-Dalaaal/lib/features/calculator/presentation/margin_calculator_screen.dart), [ProfitCalculatorScreen](file:///g:/Projects/zero-Dalaaal/lib/features/calculator/presentation/profit_calculator_screen.dart), [StockQuickActionSheet](file:///g:/Projects/zero-Dalaaal/lib/features/heatmap/presentation/widgets/stock_quick_action_sheet.dart)) resolve `Instrument` objects directly from `MarketRepository.findBySymbol(...)` / `marketRepositoryProvider.cachedInstruments`.
- In non-mock mode, screens never fall back to `SeedInstruments.all.first` or a generic placeholder. If an instrument is not found in the loaded backend cache, order placement is halted and a clear user notification is displayed.
- One-click buy and order entry sheet flows always send `instrument.symbol` as the instrument token identifier to the backend.

### D. Parameter-Sensitive & Retry-Preserved Idempotency Keys
- [OrderEntrySheet](file:///g:/Projects/zero-Dalaaal/lib/features/order_entry/presentation/order_entry_sheet.dart) generates idempotency keys based on an active parameter signature (`quantity`, `price`, `triggerPrice`, `stopLoss`, `takeProfit`, `leverage`, `executionType`, `side`).
- **Exact Retry Preservation:** When an order attempt fails (network timeout, connection drop), a retry with unchanged order parameters preserves and reuses the exact same idempotency key, guaranteeing at-most-once execution on the backend.
- **Auto-Refresh on Modification:** If the user alters any order detail (e.g., changes quantity or limits), a fresh unique idempotency key is automatically generated.

### E. Compliance, Cleanliness & Broken Imports Fixed
- Removed user-visible `"TRENDING ON KITE"` text in [search_screen.dart](file:///g:/Projects/zero-Dalaaal/lib/features/search/presentation/search_screen.dart) (replaced with `"TRENDING INSTRUMENTS"`).
- Removed legacy Zerodha/Kite comments across order detail and simulation engine files.
- Fixed broken relative imports in [data/models/option_strategy.dart](file:///g:/Projects/zero-Dalaaal/lib/data/models/option_strategy.dart) and [shared_widgets/script_selector_bar.dart](file:///g:/Projects/zero-Dalaaal/lib/shared_widgets/script_selector_bar.dart).

---

## 3. Real Backend Endpoints Used

| Endpoint | Method | Repository / Service | Payload / Unwrapping Mapping |
|---|---|---|---|
| `/api/auth/login` | `POST` | `RealAuthRepository` | Unwraps `tempToken` / PIN status |
| `/api/auth/register` | `POST` | `RealAuthRepository` | Unwraps user registration result |
| `/api/auth/verify-pin` | `POST` | `RealAuthRepository` | Unwraps session & JWT tokens |
| `/api/auth/set-pin` | `POST` | `RealAuthRepository` | Unwraps session & JWT tokens |
| `/api/auth/refresh-token` | `POST` | `RealAuthRepository` | Refreshes access token |
| `/api/market/instruments` | `GET` | `RealMarketRepository` | `items` -> List of `Instrument` |
| `/api/market/quotes` | `GET` | `RealMarketRepository` | `quotes` -> Map of `Quote` |
| `/api/market/quotes/:symbol` | `GET` | `RealMarketRepository` | `quote` -> `Quote` |
| `/api/market/candles/:symbol` | `GET` | `RealMarketRepository` | `candles` -> List of `Candle` |
| `Socket.IO (quotes:subscribe, quote:update)` | WS | `SocketService` / `TickerService` | Live quote streaming & resubscription |
| `/api/watchlists` | `GET`, `POST` | `RealWatchlistRepository` | `watchlists` / `watchlist` |
| `/api/watchlists/:id` | `PUT`, `DELETE` | `RealWatchlistRepository` | `symbols` array update / deletion |
| `/api/funds/summary` | `GET` | `RealFundsRepository` | `summary` -> `FundsSummary` |
| `/api/wallet/ledger` | `GET` | `RealFundsRepository` | `items` -> List of `LedgerEntry` |
| `/api/wallet/deposit/create` | `POST` | `RealFundsRepository` | `transaction` -> `WalletTransaction` |
| `/api/wallet/deposit/verify` | `POST` | `RealFundsRepository` | `transaction` -> `WalletTransaction` |
| `/api/wallet/withdraw` | `POST` | `RealFundsRepository` | `transaction` -> `WalletTransaction` |
| `/api/wallet/deposits` | `GET` | `RealFundsRepository` | `items` -> List of `WalletTransaction` |
| `/api/wallet/withdrawals` | `GET` | `RealFundsRepository` | `items` -> List of `WalletTransaction` |
| `/api/orders` | `GET`, `POST` | `RealTradingRepository` | `items` / `order` |
| `/api/orders/:id/cancel` | `POST` | `RealTradingRepository` | Order cancellation |
| `/api/positions` | `GET` | `RealTradingRepository` | `positions` -> List of `Position` |
| `/api/positions/:id/close` | `POST` | `RealTradingRepository` | `order` / `position` |
| `/api/trading/deals` | `GET` | `RealTradingRepository` | `items` -> List of `TransactionRecord` |
| `/api/trading/history` | `GET` | `RealTradingRepository` | `items` -> List of `TransactionRecord` |
| `/api/account/summary` | `GET` | `RealTradingRepository` | `summary` -> Account Metrics |

---

---

## 4. Screen Data Source Audit Table (Real / Mock / Hidden)

| Screen / Feature | Data Source | Behavior when `USE_MOCK_DATA=false` | Notes |
|---|---|---|---|
| **Login Screen** | **Real** | Authenticates against `/api/auth/login`. No `'ZD482915'` prefill. | Clean identifier field with real error validation. |
| **Register Screen** | **Real** | Submits KYC and registers via `/api/auth/register`. | Shows dynamic assigned Client ID or `'-'`. |
| **PIN Screen** | **Real** | Verifies / sets PIN via `/api/auth/verify-pin` / `set-pin`. | Uses dynamic user profile name or `'Trader'`. |
| **Quotes Screen** | **Real** | Live WebSocket quotes + REST `/api/market/quotes`. | Resolves real `Instrument` objects; one-click buy sends `symbol`. |
| **Watchlist Screen** | **Real** | Backend `/api/watchlists` CRUD + live ticks. | Dynamic instrument resolution; no fallback to mock tokens. |
| **Quote Detail Screen** | **Real** | `/api/market/quotes/:symbol` + `/api/market/candles/:symbol`. | Live OHLCV, market depth, and real-time bid/ask. |
| **Chart Screen (Fullscreen)** | **Real** | Live WebSocket ticks + backend candle historical data. | Dynamic timeframe candle rendering. |
| **Order Entry Sheet** | **Real** | `/api/orders` POST with parameter-based `Idempotency-Key`. | Unsupported mock order types (Stop/IOC) hidden. Reuses key on retry. |
| **Orders Screen (Open/Executed)** | **Real** | `/api/orders` GET + `/api/orders/:id/cancel` POST. | Real status lifecycle, order details, and execution logs. |
| **Positions Screen** | **Real** | `/api/positions` GET + `/api/positions/:id/close` POST. | Real open/closed positions with live backend P&L. |
| **Deals & Net Deals** | **Real** | `/api/trading/deals` and `/api/trading/history`. | Real executed trade records and gross/net summaries. |
| **Portfolio Holdings (Demat)** | **Real / Empty** | Starts completely empty ("No holdings in Demat"). | `_seedInitialData()` disabled; `DemoDataBadge` hidden in real mode. |
| **Funds Screen** | **Real** | `/api/funds/summary` (available/used margin, ledger balance). | Real ledger entries and verified transaction logs. |
| **Add Funds Sheet** | **Real** | `/api/wallet/deposit/create` + `/api/wallet/deposit/verify`. | Dynamic UPI VPA from profile; real bank options. |
| **Withdraw Funds Sheet** | **Real** | `/api/wallet/withdraw` (Idempotent payout requests). | Dynamic verified linked bank and balance limits. |
| **Account Ledger** | **Real** | `/api/wallet/ledger` GET. | Real timestamped credits, debits, and balance track. |
| **Statement Dialog & Export** | **Real** | Dynamic profile name/ID and real ledger transactions. | Export CSV uses authenticated client ID and name. |
| **Search Screen** | **Real** | `/api/market/instruments` GET with real symbol lookup. | Kite/Zerodha branding removed; dynamic search filter. |
| **Calculators (Margin & Profit)** | **Real** | Uses cached backend `Instrument` lot sizes and margins. | Dynamic symbol lookup; zero hardcoded mock tokens. |
| **Profile & Drawer** | **Real** | Session profile from `/api/profile` (name, email, PAN, bank). | No demo user fallbacks (`Anurag`, `8739039936` removed). |
| **Personal Details Sheet** | **Real** | Displays verified profile fields; shows `'-'` if empty. | No demo placeholders. |
| **Notifications Center** | **Real** | Starts completely empty in real mode; no demo seeding. | Only live real-time push and system alerts populate. |
| **Basket Orders** | **Mock (Blocked)** | `DemoDataBadge(label: 'Basket Orders (Demo)')` displayed. | Order execution is blocked when `useMock == false`. |
| **GTT Triggers Sheet & Tab** | **Mock (Blocked)** | `DemoDataBadge(label: 'GTT Triggers (Demo)')` displayed. | GTT order placement is blocked when `useMock == false`. |
| **Price Alerts** | **Mock** | `DemoDataBadge(label: 'Price Alerts (Demo)')` displayed. | Local simulation badge visible. |
| **Market News Feed** | **Mock** | `DemoDataBadge(label: 'News Feed (Demo)')` displayed. | Simulated news articles with clear demo badge. |
| **IPO & Primary Market** | **Mock** | `DemoDataBadge(label: 'IPO (Demo)')` displayed. | Simulated IPO issues and bids. |
| **Stock SIP Screen** | **Mock** | `DemoDataBadge(label: 'Stock SIP (Demo)')` displayed. | Simulated recurring investments. |
| **Sector Heatmap Screen** | **Mock** | `DemoDataBadge(label: 'Market Heatmap (Demo)')` displayed. | Visual sector performance with demo badge. |
| **Fundamentals Tab** | **Mock** | `DemoDataBadge(label: 'Fundamentals & Financials (Demo)')` displayed. | Financial ratios with demo badge. |
| **Economic Calendar** | **Mock** | `DemoDataBadge(label: 'Economic Calendar (Demo)')` displayed. | Macro economic events with demo badge. |
| **Corporate Actions View** | **Mock** | `DemoDataBadge(label: 'Corporate Actions (Demo)')` displayed. | Dividends and splits with demo badge. |
| **Support & Help Desk** | **Mock / Web** | `DemoDataBadge(label: 'Help & Support Desk (Demo)')` displayed. | Hardcoded numbers removed; routes to web helpdesk. |
| **Live Support Chat** | **Mock** | `DemoDataBadge(label: 'Live Support Chat (Demo)')` displayed. | Simulated chat assistant with demo badge. |
| **Investor Risk Profile** | **Mock** | `DemoDataBadge(label: 'Risk Profile (Demo)')` displayed. | SEBI questionnaire with demo badge. |
| **FATCA / CRS Declaration** | **Mock** | `DemoDataBadge(label: 'FATCA / CRS Declaration (Demo)')` displayed. | Regulatory declaration with demo badge. |
| **Nominee Management** | **Mock** | `DemoDataBadge(label: 'Nominee Management (Demo)')` displayed. | Starts with blank fields when not in mock mode. |

---

## 5. How to Run

### Real Backend (LAN)
```powershell
flutter run --dart-define=API_BASE_URL=http://<PC_LAN_IP>:5000 --dart-define=USE_MOCK_DATA=false
```

### Real Backend (Android Emulator)
```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000 --dart-define=USE_MOCK_DATA=false
```

### Offline Mock Mode
```powershell
flutter run --dart-define=USE_MOCK_DATA=true
```

---

## 6. Verification Results

- **`flutter analyze`**: **0 issues found** (clean).
- **`test/real_repositories_test.dart`**: **6/6 tests passed**.
- **`test/flow_integration_test.dart`**: **9/9 tests passed**.
- **`flutter test` (Full Test Suite)**: **251/251 tests passed**.
