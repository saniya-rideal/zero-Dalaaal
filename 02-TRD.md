# TRD — Technical Requirements Document
## Zero — Flutter Frontend Architecture

---

## 1. Architecture Style

**Clean Architecture + MVVM**, feature-first folder structure, reactive state via **Riverpod** (StateNotifier/AsyncNotifier). Chosen over BLoC/Provider because it scales cleanly across ~18 feature modules without boilerplate explosion, and swaps mock↔real data sources with zero UI changes.

```
Presentation (Widgets/Screens)
        ↓ watches
ViewModel / Controller (Riverpod Notifier)
        ↓ calls
Repository (interface)
        ↓ implemented by
DataSource (Mock now → Remote/WebSocket later)
```

## 2. Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Framework | Flutter 3.x (stable), Dart 3.x (null-safety, sound) | Cross-platform, single codebase |
| State Mgmt | flutter_riverpod + riverpod_generator | Compile-safe DI, easy mock/real swap, testable |
| Routing | go_router | Declarative, deep-link ready, nested nav (bottom tabs + stacks) |
| Charts | fl_chart (base) + custom `CustomPainter` candlestick renderer | fl_chart lacks native candlesticks at needed fidelity; custom painter gives Kite-accurate OHLC rendering + indicator overlays |
| Local persistence | Hive (watchlists, alerts, settings, basket, SIP, PIN hash) | Fast, no native build step, good for structured mock "DB" |
| Local secure storage | flutter_secure_storage | PIN/biometric flags, mock session token |
| Networking (future-ready) | dio + web_socket_channel (wired but pointed at mock/local sources for now) | Drop-in swap to real REST/WebSocket later |
| DI | riverpod (Provider overrides) — no separate GetIt needed | Riverpod already is the DI graph |
| Forms | flutter_form_builder + form_builder_validators | Order forms, KYC-style forms, SIP forms |
| Animations | flutter_animate, Rive (optional, for splash) | Micro-interactions: price flash, tab transitions |
| Fonts/Icons | Google Fonts (`Inter`/`Roboto`) + custom icon font or `flutter_svg` for glyphs | Match Kite's clean sans-serif system |
| Number/Date | intl | ₹ formatting (lakh/crore grouping), date formatting |
| Testing | flutter_test, mocktail, golden_toolkit | Unit (repos/notifiers), widget, golden screenshot tests per screen |
| Local notifications | flutter_local_notifications | Alert-triggered mock notifications |
| Biometrics | local_auth | Face ID / fingerprint unlock |

## 3. Project Layering (feature-first)

```
lib/
  core/                     # theme, constants, utils, extensions, error types
  app/                      # app.dart, router.dart, providers bootstrap
  data/
    mock/                   # JSON fixtures + generators (ticks, OHLC, orders)
    models/                 # freezed data models (Instrument, Order, Position, Holding, ...)
  features/
    auth/
    watchlist/
    quote_detail/
    charts/
    order_entry/
    orders/
    positions/
    portfolio/
    funds/
    baskets/
    sip/
    ipo/
    alerts/
    option_chain/
    profile_settings/
    search/
    notifications/
  shared_widgets/           # reusable UI atoms (PriceText, LtpChip, SegmentedTabs...)
```
Each feature folder internally follows: `data/` (repo impl + mock datasource) → `domain/` (repo interface + entities/usecases) → `presentation/` (screens, widgets, controllers/notifiers).

> Full tree with every file path is in **Doc 6 — Project Structure & Task Breakdown**.

## 4. Data Layer Strategy (frontend-only phase)

- Every repository is an **interface** (e.g. `WatchlistRepository`), with a `MockWatchlistRepository` implementation reading/writing Hive + in-memory seed JSON.
- A single `AppConfig.useMockData = true` flag (Riverpod override point) is the only switch needed later to route to `RemoteWatchlistRepository` (Dio) — **no screen/controller code changes required**.
- Live price simulation: a `TickerService` (Riverpod `StreamProvider`) emits randomized-walk price ticks every 1–2s for all instruments currently subscribed (i.e., visible watchlist/quote screen) — mirrors how a real WebSocket subscription model works (subscribe on screen mount, unsubscribe on dispose), so swapping in Socket.IO/WebSocket later (same shape used in [[trading-learning-platform]] backend) is mechanical.
- Order lifecycle simulated via a `OrderSimulationEngine`: Market orders fill instantly (after ~800ms fake latency), Limit orders fill when simulated LTP crosses limit price (checked each tick), SL/SL-M trigger similarly.

## 5. State Management Pattern (per feature)

```dart
// domain/repository
abstract class OrdersRepository {
  Future<List<Order>> getPending();
  Future<List<Order>> getExecuted();
  Future<Order> placeOrder(OrderRequest req);
  Future<void> cancelOrder(String id);
  Future<void> modifyOrder(String id, OrderModification m);
}

// presentation/controller
@riverpod
class OrdersController extends _$OrdersController {
  @override
  Future<OrdersState> build() => ref.watch(ordersRepositoryProvider).fetchAll();

  Future<void> place(OrderRequest req) async { ... }
}
```
Widgets only ever call `ref.watch(ordersControllerProvider)` / `ref.read(...).place(...)` — never touch the repository or mock datasource directly.

## 6. Navigation Map (go_router)

- `ShellRoute` for the 5-tab bottom nav (Watchlist / Orders / Positions / Portfolio / More), each tab keeps its own `Navigator` stack (state preserved on tab switch, matching Kite's behavior).
- Modal routes (bottom sheets) for: Order Entry, GTT Create, Alert Create, Basket Execute, Add Funds, Withdraw Funds.
- Full-screen routes for: Quote Detail, Chart Full-Screen, Option Chain, Search, IPO List/Detail, SIP Create, Settings sub-pages.

## 7. Non-Functional Requirements

- **Performance:** Watchlist scroll must sustain 60fps with 250 rows ticking; use `ListView.builder` + `const` widgets + `Selector`-style granular Riverpod watches (watch only the specific instrument's price provider per row, not the whole list).
- **Offline-first for static data:** watchlists/settings/baskets persist locally (Hive) and survive app restart without any backend.
- **Theming:** Full light/dark theme parity (Kite ships both) via `ThemeExtension` for custom semantic colors (bullish/bearish/neutral).
- **Accessibility:** minimum tap target 44x44, color-blind-safe secondary indicator (▲/▼ glyph, not color alone) next to every P&L figure.
- **Testability:** every controller unit-testable with mocked repository (mocktail); target ≥70% coverage on domain/data layers.
- **Localization-ready:** strings externalized via `intl`/ARB files even though only English/Hinglish UI ships in Phase 1.

## 8. Error & Edge-Case Handling

- Network-off simulation toggle in dev settings (to test error/retry states even with mock data).
- Empty states for every list screen (empty watchlist, no orders, no holdings, no alerts) — Kite-style illustration + CTA.
- Order rejection simulation (insufficient mock margin, market closed for non-AMO orders) with real Kite-style rejection reason text.

## 9. Build & Environments

- Flavors: `dev` (mock data, debug banner, dev tools drawer), `demo` (mock data, clean UI — for portfolio/interview demos), `prod`-ready stub (real endpoints disabled, feature-flagged off) for future backend cutover.
- CI-ready: `flutter analyze` + `flutter test` + golden tests as required checks (GitHub Actions workflow stub included in Doc 6).
