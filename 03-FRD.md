# FRD — Functional Requirements Document
## Zero — Screen-by-Screen Behavior Spec

Each entry: **Screen → Trigger → Behavior → Edge cases → Exit points.** This is the spec Antigravity should implement each screen against.

---

### S01. Splash
- Trigger: cold app launch.
- Behavior: logo animates in (600ms fade+scale), checks Hive for saved session + biometric flag, then routes to S02 (Login) or S04 (PIN unlock) or S05 (Home).
- Edge cases: first-ever launch → always Login.

### S02. Login
- Fields: User ID, Password. "Login" button disabled until both non-empty.
- Behavior: mock-validates against a seeded demo account (`ZD1234`, any password ≥6 chars) → proceeds to S03.
- Edge cases: wrong ID format → inline error; 3 failed attempts → mock "temporarily locked" banner (UI only).
- Exit: → S03 (2FA/PIN setup or verify).

### S03. 2FA / TOTP-PIN
- 6-box PIN input (Kite's TOTP screen pattern), auto-advances per digit, auto-submits on 6th digit.
- Behavior: mock-accepts any 6 digits on first-time login; sets this as the App PIN for future biometric fallback.
- Exit: → S05 (Home dashboard).

### S04. PIN Unlock (returning session)
- 6-digit pad + biometric prompt (if enabled) shown automatically.
- Behavior: correct PIN or biometric success → S05. Wrong PIN → shake animation + attempts counter.
- Exit: "Login with different account" link → S02.

### S05. Home Shell (Bottom Nav)
- Tabs, left→right: **Watchlist, Orders, Positions, Portfolio, More**. Persistent state per tab.
- Top app bar (contextual per tab): search icon (→ S17), alerts bell with unread dot (→ S18), avatar (→ More menu).

### S06. Watchlist (Marketwatch)
- Tab strip of watchlists at top (horizontal scroll, "+" at end → create new, max 25).
- Row: symbol, exchange chip, LTP, ₹ change, % change (color-coded), mini sparkline (optional).
- Swipe row right → green Buy quick-sheet prefilled; swipe left → red Sell quick-sheet prefilled.
- Long-press → action sheet: View Chart, Set Alert, Add to Basket, Edit Groups, Remove from list.
- FAB or "+" in app bar → S17 Search to add instrument.
- Empty state: "Your watchlist is empty" + Add Instruments CTA.
- Tap row (not swipe) → S07 Quote Detail.

### S07. Quote / Instrument Detail
- Header block: symbol/name, exchange, LTP big, day change, OHLC + 52w H/L strip.
- Tabs: **Overview | Chart | Depth | Fundamentals** (F&O instruments add **Option Chain** shortcut chip).
- Overview: key stats grid, "Add to basket," "Set Alert" buttons.
- Depth: 5x5 bid/offer ladder table with live-updating qty bars.
- Sticky footer: BUY (green) / SELL (red) buttons → opens S09 Order Entry.

### S08. Chart (embedded tab + full-screen mode)
- Type toggle: Candle / Line / Bar (segmented control, top-left of chart).
- Timeframe strip: 1m 5m 15m 30m 1H 1D 1W 1M.
- Indicator button → bottom sheet searchable list (S08a) → toggles overlay/sub-panel.
- Gestures: pinch zoom, horizontal pan, long-press-drag shows crosshair + floating OHLC/indicator readout card.
- Rotate/fullscreen icon → landscape full-screen chart route.
- Drawing tool icon → toolbar (trendline, horizontal ray, fib retracement); tap-tap to place, tap-hold to delete.

#### S08a. Indicator Picker
- Search field + categorized list (Trend, Momentum, Volatility, Volume). Checkbox to enable, gear icon to configure params (period, source).

### S09. Order Entry (Bottom Sheet)
- Header: symbol + LTP live.
- Buy/Sell segmented tab (color-coded).
- Product chips: CNC / MIS / NRML (context-filtered: NRML only for F&O/commodity instruments).
- Order type chips: Market / Limit / SL / SL-M.
- Qty stepper (min 1, step = lot size for F&O).
- Price field (enabled for Limit/SL), Trigger price field (enabled for SL/SL-M).
- "More" expander: Validity (Day/IOC), Disclosed Qty, AMO auto-flag if market closed.
- BO/CO toggle (only for eligible product/order-type combos) reveals Target/SL/Trailing-SL fields.
- Footer: required margin estimate (mock calc), Swipe-to-confirm or tap-to-confirm button (color matches Buy/Sell).
- On confirm: loading state (~800ms) → success toast + auto-navigates/refreshes S10 Orders (Pending) or shows fill toast if instantly matched.
- Edge cases: qty=0 disables confirm; limit price required validation; insufficient mock margin → inline rejection banner with reason text.

### S10. Orders
- Segmented control: **Pending | Executed | GTT**.
- Pending row: symbol, qty, product/type chips, status chip (OPEN/TRIGGER PENDING/PARTIAL), tap → S11 detail; swipe → Cancel; edit icon → Modify (reopens S09 prefilled).
- Executed: grouped by date, tap → S11 detail (read-only, shows fills/timestamps/charges).
- GTT: list with trigger condition summary, Edit/Delete swipe actions; "+" → S09b GTT Create flow.
- Empty states per segment with contextual CTA (e.g., "No pending orders" + "Explore Market").

### S11. Order Detail
- Vertical timeline: Placed → Validated → Open → (Partially Filled) → Filled/Cancelled/Rejected, each with timestamp.
- Charges breakdown card: Brokerage (₹0), STT, Exchange txn charge, GST, SEBI charges, Stamp duty, Total.
- Exchange Order ID, Order ID (mock-generated), Product/Type/Validity summary.

### S12. Positions
- Toggle: **Day | Net**.
- Header summary: total realized + unrealized P&L (color-coded, live).
- Row: symbol, product tag, qty (buy/sell), avg price, LTP, P&L.
- Tap row → action sheet: Exit Position, Add More, Convert (MIS↔CNC/NRML).
- Exit → mini confirm sheet (market order prefilled) → moves qty to 0 / removes row, updates Orders/Executed.

### S13. Portfolio (Holdings)
- Summary card: Investment, Current Value, Total P&L (₹/%), Today's P&L.
- Row: symbol, qty, avg cost, LTP, current value, P&L (color-coded), day change badge.
- Tap → S07 Quote Detail (Sell button pre-highlighted) + holding-specific stats (days held, XIRR mock).
- Corporate action banner strip above list (e.g., "INFY: Dividend ₹18/share, ex-date 12 Sep" — mock data).

### S14. Funds
- Segment tabs: Equity / Commodity.
- Summary card: Available Margin, Used Margin, Opening Balance.
- Buttons: Add Funds → S14a, Withdraw → S14b.
- Statement list below: date, narration, credit/debit, running balance.

#### S14a. Add Funds
- Amount keypad, quick-amount chips (₹5k/10k/25k/50k), payment method radio (UPI/Net Banking/Card — mock), Proceed → success sheet, updates Funds balance.

#### S14b. Withdraw Funds
- Amount field (capped at available margin), bank account selector (mock linked accounts), Confirm → success sheet, deducts balance.

### S15. Baskets
- List of saved baskets (name, leg count, created date).
- "+" → Create Basket: add legs (search instrument → set qty/product/order type per leg), shows aggregate margin estimate.
- "Execute All" → per-leg confirmation list → places all as individual orders (feeds into S10 Pending/Executed).

### S16. SIP
- Active SIPs list: instrument, amount, frequency, next date, status (Active/Paused).
- "+" Create SIP: instrument search, amount, frequency (Daily/Weekly/Monthly), start date, duration/no. of installments.
- Row actions: Pause/Resume, Cancel, View execution history (mock past installments list).

### S17. Search
- Search bar with segment filter chips: NSE / BSE / NFO / MCX / CDS / All.
- Recent searches (chips) + Trending chips when query empty.
- Result row: symbol, name, exchange, LTP preview; tap → S07; long-press/checkbox → multi-add to a chosen watchlist.

### S18. Alerts
- List: instrument, condition (Above/Below/±%), status (Active/Triggered/Expired).
- "+" → Create Alert: instrument search (or prefilled from Quote/Watchlist context), condition type, target value, optional "apply to multiple instruments" multi-select (addresses the real user-requested "group alert" feature).
- Triggered alerts push a local notification (S19) and move to a "Triggered" filter tab.

### S19. Notification Center
- Chronological feed: order fills, alert triggers, corporate actions, market nudges (e.g., "Market opens in 15 min").
- Tap → deep-links to relevant screen (order detail, quote, etc.).

### S20. Option Chain
- Expiry date tabs (horizontal scroll).
- Table columns: Call OI | Call Chg OI | Call IV | Call LTP | **Strike** | Put LTP | Put IV | Put Chg OI | Put OI.
- ATM row highlighted, auto-scrolled into view on open.
- Tap any LTP cell → S09 Order Entry prefilled with that option contract.
- Filter icon → show only N strikes around ATM, or full chain.

### S21. IPO
- Tabs: Current / Upcoming / Closed.
- Card: company name/logo, price band, lot size, open/close dates, mock GMP (grey market premium) field, "Apply" button (disabled if not Current).
- Apply flow: UPI ID input, lot quantity stepper, cutoff-price checkbox, Submit → mock application status card (Applied → Allotted/Not Allotted, randomly resolved after a mock delay for demo purposes).

### S22. Profile / More
- Header: name, client ID, masked PAN, KYC status badge.
- List items: Funds, Baskets, SIPs, Alerts, IPO, Reports (Tax P&L export), Apps (informational cards), Settings, Help & Support, Logout.

### S23. Settings
- Sub-pages: Theme (Light/Dark/System), Notifications (toggles per category), Security (Change PIN, Biometric toggle, Active Sessions list, Logout all devices), Segments enabled (Equity/F&O/Currency/Commodity toggles — informational), About/Version.

### S24. Reports (Tax P&L)
- Financial year selector, segment filter (Equity/F&O), summary card (realized gain/loss, turnover), "Export PDF/CSV" mock action producing a locally generated dummy file.

### S25. Help & Support
- FAQ accordion list (searchable), "Raise a ticket" form (subject, category dropdown, description) → mock submitted confirmation with ticket ID.

---

## Cross-cutting Functional Rules

1. **Color law:** any figure representing gain/positive uses `bullishGreen`; loss/negative uses `bearishRed`; neutral/zero uses `neutralGrey`. Applies uniformly to LTP change, P&L, day change — everywhere, no exceptions.
2. **Currency formatting:** Indian digit grouping (₹1,23,456.78), never Western grouping.
3. **Live-tick propagation:** any screen currently mounted and showing an instrument subscribes to `TickerService`; unmounted screens unsubscribe (memory-safe).
4. **Persistence:** Watchlists, Alerts, Baskets, SIPs, Settings, PIN survive app restart (Hive). Orders/Positions/Holdings/Funds ledger reset per mock "trading day" (configurable dev toggle to persist across restarts for demo purposes).
5. **Universal empty/loading/error states:** every list-based screen must implement all three (skeleton loader, empty illustration+CTA, retry-on-error banner) — no screen ships with only the "happy path" state.
