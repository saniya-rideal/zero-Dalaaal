# PRD — Product Requirements Document (PRD)
## Zero (Kite Clone) — Flutter Frontend

---

### 1. Product Summary
**Zero** is a Flutter-based trading & investing app that replicates **Zerodha Kite** 1:1 in UI, navigation, and interaction — screen-for-screen, gesture-for-gesture, animation-for-animation. Phase 1 scope is **frontend only**: every screen, state, and micro-interaction is built with mock/local data behind a clean repository layer, so a real backend (or the existing Trading Learning Platform backend already noted for [[trading-learning-platform]]) can be wired in later without touching UI code.

Name meaning: **Zero** represents zero brokerage and zero friction.

---

## 2. Goals

1. Pixel-and-behavior clone of Kite's mobile app (Android/iOS via Flutter) — not "inspired by," but **identical**: same tab structure, same iconography intent, same color logic (green/red for price movement), same order flow steps, same empty states, same bottom sheets.
2. Fully working **frontend state machine** — watchlists persist in memory/local storage, orders move from Pending → Executed, positions/holdings recompute P&L live against mock ticking prices.
3. Clean architecture so swapping mock repositories for real API/WebSocket repositories later is a **1-file change per feature**, not a rewrite.
4. Ready for **Antigravity** (agentic IDE) to execute as a task-by-task build — see Doc 6 (Project Structure & Task Breakdown).

## 3. Non-Goals (Phase 1)

- No real broker connectivity, no real order execution, no real KYC/demat.
- No real payment gateway (funds add/withdraw is UI + mock ledger only).
- No live market data feed (simulated/mocked ticker instead of real WebSocket — architecture supports plugging one in later, same as the Finnhub/Socket.IO setup already used in [[trading-learning-platform]]).
- No push notifications backend (local notification stubs only).

## 4. Target Users

- Retail equity/F&O traders and investors in India (same audience as Zerodha).
- Fresher/demo/portfolio use case: this doubles as a flagship showcase project for [[job-search]] (AI/full-stack fresher roles) — so code quality, architecture, and polish matter as much as feature coverage.

## 5. Platforms

- Flutter (Android + iOS from single codebase). Tablet/responsive layout as stretch goal. No web target in Phase 1 (Kite Web is a separate, heavier product — out of scope, mobile app "Kite" is the clone target).

## 6. Full Feature List (must all exist — nothing skipped)

### 6.1 Onboarding & Auth
- Splash screen (logo animation)
- Login screen: Client ID (User ID) + Password
- 2FA / TOTP or PIN screen (6-digit PIN pad UI, like Kite's TOTP/PIN step)
- "Forgot User ID / Password" links (UI only, dead-end screens with instructions)
- Biometric unlock toggle (Face ID / Fingerprint) for subsequent app opens
- Set/Change app PIN flow

### 6.2 Home / Dashboard
- Bottom navigation: **Watchlist | Orders | Positions | Portfolio | More** (Kite's exact 5-tab structure — mobile app uses Watchlist, Orders, Positions, Portfolio/Holdings-Bets tab naming, and a "More"/hamburger area for Profile, Funds, Apps, Settings)
- Top bar: search icon, notifications/alerts bell, profile avatar

### 6.3 Watchlist (Marketwatch)
- Multiple watchlists (up to 25, tab strip at top, swipe/scroll between them, "+" to add new)
- Up to 250 instruments per watchlist (configurable constant)
- Custom groups within a watchlist (sector/strategy/theme grouping, collapsible groups)
- "Starred" pinned group across all watchlists
- Ready-made watchlists (Nifty 50, Bank Nifty, Sensex, sector indices — pre-seeded)
- Add instrument via search (NSE/BSE toggle, exchange badge on each row)
- Swipe left/right on a row → Buy / Sell quick actions
- Long-press row → context menu: Edit, Chart, Add to marketwatch group, Set Alert, Remove
- Live-style price, day change (₹ and %), color-coded green/red, LTP flash animation on tick
- Reorder instruments (drag handle in edit mode)
- Tap row → Instrument Detail / Quote screen

### 6.4 Instrument Detail / Quote Screen
- Header: symbol, exchange, LTP, day change, OHLC, 52-week high/low
- Depth (Level 2/3): 5 bids + 5 offers table, total buy/sell qty
- Chart tab (see 6.5)
- Fundamentals tab: market cap, P/E, P/B, key stats (for equities)
- F&O chain shortcut (for indices/stocks with derivatives)
- Buy / Sell buttons (fixed footer)
- Add/Remove from watchlist, Set Alert, Add to Basket

### 6.5 Charts
- Candlestick / Line / Bar chart types toggle
- Timeframes: 1m, 5m, 15m, 30m, 1H, 1D, 1W, 1M (button strip)
- Historical range: intraday up to multi-year (mock generator produces N years of OHLC)
- 100+ indicator picker (searchable list; render a working subset — SMA, EMA, RSI, MACD, Bollinger Bands, VWAP — with UI slots for the rest as "coming soon" to preserve the full picker UI)
- Drawing tools: trendline, horizontal line, Fibonacci retracement (toolbar)
- Pinch-to-zoom, pan, crosshair with OHLC readout
- Full-screen chart mode (landscape)
- Compare overlay (add second instrument)

### 6.6 Order Placement
- Order window (bottom sheet, Kite-style): Buy (blue) / Sell (red) tab
- Product type: **CNC** (Cash & Carry / delivery), **MIS** (intraday margin), **NRML** (F&O carry-forward)
- Order type: **Market, Limit, SL (Stop-Loss), SL-M (Stop-Loss Market)**
- Quantity stepper, Price field (disabled for Market), Trigger price field (for SL/SL-M)
- Validity: **Day, IOC (Immediate or Cancel)**
- Advanced toggle: Disclosed Quantity
- **Bracket Order (BO)** and **Cover Order (CO)** modes with target/stop-loss/trailing SL fields
- Margin required preview (mock calculation) before confirm
- Order confirmation bottom sheet + success/failure toast
- **AMO (After Market Order)** flag when placed outside market hours (mock market-hours clock)
- **GTT (Good Till Triggered)** order creation — separate flow: trigger type (single/OCO), trigger price(s), quantity

### 6.7 Orders Screen
- Three segments: **Pending, Executed (Completed), GTT**
- Pending: shows order with Modify / Cancel actions, live status chips (OPEN, TRIGGER PENDING, PARTIALLY FILLED)
- Executed: filled orders grouped by day, tap → order detail with fill trades, timestamps, order ID
- GTT: active/triggered/expired/cancelled GTT list, delete/edit
- Order detail screen: full lifecycle log (placed → validated → open → filled), exchange order ID, charges breakdown (mock brokerage=0, STT, GST, stamp duty, SEBI charges, exchange txn charges — show the real Zerodha-style charge ledger even though brokerage is ₹0/zero for equity delivery)

### 6.8 Positions
- Day's positions: MIS/NRML/CO/BO tagged, LTP, P&L (₹ and %) live-colored, Buy/Sell qty & avg price
- Net vs Day toggle
- Tap position → Exit / Add / Convert (MIS↔CNC/NRML) bottom sheet
- Overall day P&L summary header (aggregate realized + unrealized)

### 6.9 Portfolio (Holdings)
- Holdings list: qty, avg cost, LTP, current value, P&L (₹/%), day change
- Portfolio summary card: total investment, current value, total P&L, today's P&L
- Family/consolidated portfolio toggle (stretch)
- Tap holding → Quote screen with "Sell" prefilled + holding-specific stats (XIRR mock, days held)
- Corporate actions banner (mock: dividend/bonus/split notices)

### 6.10 Funds
- Equity / Commodity segment tabs
- Available margin, used margin, opening balance, payin/payout summary card
- Add Funds (UPI/Net-banking/Card mock flow) with amount pad
- Withdraw Funds flow with bank account selector
- Fund statement / ledger list (date, description, credit/debit, balance)

### 6.11 Baskets
- Create named basket, add multiple instruments with qty/order type each
- Basket margin preview, "Execute All" flow with per-leg confirmation

### 6.12 SIP (Systematic Investment)
- Create SIP: instrument, amount, frequency (daily/weekly/monthly), start date, duration
- Active SIPs list, pause/cancel, execution history

### 6.13 IPO
- Current/upcoming/closed IPO list cards (name, price band, dates, GMP mock field)
- Apply flow: UPI ID, quantity/lot, cutoff price checkbox, application status tracker

### 6.14 Alerts
- Create price alert (above/below/% change) per instrument, from watchlist or quote screen
- Alerts list, active/triggered history, edit/delete
- Alert-group ("apply to multiple instruments at once") per user feedback pattern seen in real Kite requests

### 6.15 Option Chain
- Strike-wise CE/PE table: LTP, OI, change in OI, IV, volume
- ATM highlight row, expiry selector tabs
- Tap a strike → prefilled order window
- Straddle/strategy quick-add (stretch)

### 6.16 Profile / More / Settings
- Profile: name, client ID, PAN (masked), linked bank, segments enabled (Equity/F&O/Commodity/Currency)
- Apps section (Kite's "Apps" tab equivalent — links to Console, Coin, Kite Connect equivalents as informational cards)
- Theme: Light / Dark / System toggle
- Notification preferences
- Security: change PIN, biometric toggle, active sessions (mock list), logout / logout-all-devices
- Tax P&L report generator (mock CSV/PDF export screen)
- Help & Support (FAQ list, ticket form UI)
- About / version info

### 6.17 Search
- Global instrument search (NSE/BSE/NFO/MCX/CDS segment filter chips)
- Recent searches, trending/most-searched chips

### 6.18 Notifications / Nudges
- In-app notification center: order alerts, corporate actions, market nudges, alert-triggered events (Kite calls these "Alert Triggered Orders"/nudges)

## 7. Success Criteria

- Every screen above exists, is navigable, and matches Kite's information hierarchy and color/typography language (see Doc 4 — UI/UX Design System).
- State transitions work end-to-end on mock data: place order → appears in Pending → simulated fill → appears in Executed → reflected in Positions/Holdings.
- Codebase passes clean-architecture review: UI never talks to mock data directly, always through repository interfaces (see Doc 2 — TRD).

## 8. Open Questions / Assumptions

- Brokerage is ₹0 (matches Zerodha equity delivery + the "Zero" brand promise); F&O/intraday charges still shown per real fee structure for authenticity.
- Real-time data is simulated with a deterministic random-walk ticker (configurable tick interval) until a live feed is integrated.
