# Project Structure & Antigravity Task Breakdown
## Zero — Execution Plan

This is the doc to paste into Antigravity as the working brief. It's ordered so each task is independently completable and buildable/testable before moving to the next — no task depends on unfinished future work.

---

## 1. `pubspec.yaml` — Dependencies

```yaml
name: zero_dalali
description: Zerodha Kite–clone trading app frontend
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^14.2.0
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.2.2
  dio: ^5.5.0
  web_socket_channel: ^2.4.5
  fl_chart: ^0.68.0
  flutter_svg: ^2.0.10
  google_fonts: ^6.2.1
  intl: ^0.19.0
  flutter_form_builder: ^9.4.1
  form_builder_validators: ^11.0.0
  flutter_animate: ^4.5.0
  local_auth: ^2.2.0
  flutter_local_notifications: ^17.2.2
  uuid: ^4.4.2
  collection: ^1.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.11
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  mocktail: ^1.0.4
  golden_toolkit: ^0.15.0
  flutter_lints: ^4.0.0
```

## 2. Full Folder Tree

```
zero_dalali/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   ├── router.dart
│   │   └── providers_bootstrap.dart
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── trading_colors.dart        # ThemeExtension
│   │   │   └── typography.dart
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   └── charges_config.dart
│   │   ├── utils/
│   │   │   ├── currency_formatter.dart
│   │   │   └── date_formatter.dart
│   │   └── error/
│   │       └── app_exception.dart
│   ├── data/
│   │   ├── models/                        # freezed models (Section 1 of Doc 5)
│   │   └── mock/
│   │       ├── seed_instruments.dart
│   │       ├── candle_generator.dart
│   │       ├── ticker_service.dart
│   │       └── order_simulation_engine.dart
│   ├── shared_widgets/
│   │   ├── price_text.dart
│   │   ├── segmented_tab_bar.dart
│   │   ├── exchange_chip.dart
│   │   ├── instrument_row.dart
│   │   ├── empty_state_view.dart
│   │   ├── skeleton_loader.dart
│   │   ├── section_card.dart
│   │   ├── pin_input_pad.dart
│   │   └── margin_summary_bar.dart
│   └── features/
│       ├── auth/
│       │   ├── data/  (mock_auth_repository.dart)
│       │   ├── domain/ (auth_repository.dart, session.dart)
│       │   └── presentation/
│       │       ├── splash_screen.dart
│       │       ├── login_screen.dart
│       │       ├── totp_screen.dart
│       │       ├── pin_unlock_screen.dart
│       │       └── auth_controller.dart
│       ├── watchlist/
│       │   ├── data/ (mock_watchlist_repository.dart)
│       │   ├── domain/ (watchlist_repository.dart)
│       │   └── presentation/
│       │       ├── watchlist_screen.dart
│       │       ├── watchlist_tab_strip.dart
│       │       ├── watchlist_row_actions.dart
│       │       └── watchlist_controller.dart
│       ├── quote_detail/
│       │   └── presentation/
│       │       ├── quote_detail_screen.dart
│       │       ├── depth_tab.dart
│       │       ├── fundamentals_tab.dart
│       │       └── quote_controller.dart
│       ├── charts/
│       │   ├── domain/ (candle.dart, indicator.dart)
│       │   └── presentation/
│       │       ├── chart_view.dart               # CustomPainter candlestick
│       │       ├── chart_fullscreen_screen.dart
│       │       ├── indicator_picker_sheet.dart
│       │       ├── indicators/  (sma.dart, ema.dart, rsi.dart, macd.dart, bollinger.dart, vwap.dart)
│       │       └── chart_controller.dart
│       ├── order_entry/
│       │   └── presentation/
│       │       ├── order_entry_sheet.dart
│       │       ├── bracket_cover_fields.dart
│       │       ├── gtt_create_sheet.dart
│       │       └── order_entry_controller.dart
│       ├── orders/
│       │   ├── data/ (mock_orders_repository.dart, mock_gtt_repository.dart)
│       │   ├── domain/ (orders_repository.dart, gtt_repository.dart)
│       │   └── presentation/
│       │       ├── orders_screen.dart
│       │       ├── order_detail_screen.dart
│       │       ├── gtt_list_tab.dart
│       │       └── orders_controller.dart
│       ├── positions/
│       │   ├── data/ (mock_positions_repository.dart)
│       │   └── presentation/
│       │       ├── positions_screen.dart
│       │       ├── position_action_sheet.dart
│       │       └── positions_controller.dart
│       ├── portfolio/
│       │   ├── data/ (mock_portfolio_repository.dart)
│       │   └── presentation/
│       │       ├── portfolio_screen.dart
│       │       ├── holding_detail_extra.dart
│       │       └── portfolio_controller.dart
│       ├── funds/
│       │   ├── data/ (mock_funds_repository.dart)
│       │   └── presentation/
│       │       ├── funds_screen.dart
│       │       ├── add_funds_sheet.dart
│       │       ├── withdraw_funds_sheet.dart
│       │       └── funds_controller.dart
│       ├── baskets/
│       │   ├── data/ (mock_basket_repository.dart)
│       │   └── presentation/
│       │       ├── baskets_screen.dart
│       │       ├── basket_create_screen.dart
│       │       └── baskets_controller.dart
│       ├── sip/
│       │   ├── data/ (mock_sip_repository.dart)
│       │   └── presentation/
│       │       ├── sip_screen.dart
│       │       ├── sip_create_sheet.dart
│       │       └── sip_controller.dart
│       ├── ipo/
│       │   ├── data/ (mock_ipo_repository.dart)
│       │   └── presentation/
│       │       ├── ipo_list_screen.dart
│       │       ├── ipo_apply_sheet.dart
│       │       └── ipo_controller.dart
│       ├── alerts/
│       │   ├── data/ (mock_alerts_repository.dart)
│       │   └── presentation/
│       │       ├── alerts_screen.dart
│       │       ├── alert_create_sheet.dart
│       │       └── alerts_controller.dart
│       ├── option_chain/
│       │   ├── data/ (mock_option_chain_repository.dart)
│       │   └── presentation/
│       │       ├── option_chain_screen.dart
│       │       └── option_chain_controller.dart
│       ├── search/
│       │   └── presentation/
│       │       ├── search_screen.dart
│       │       └── search_controller.dart
│       ├── notifications/
│       │   └── presentation/
│       │       ├── notification_center_screen.dart
│       │       └── notifications_controller.dart
│       └── profile_settings/
│           └── presentation/
│               ├── profile_screen.dart
│               ├── settings_screen.dart
│               ├── security_settings_screen.dart
│               ├── reports_screen.dart
│               └── help_support_screen.dart
├── test/
│   ├── data/  (repository + notifier unit tests, mirrors lib/features tree)
│   └── golden/  (per-screen golden tests)
├── .github/workflows/flutter_ci.yaml
├── pubspec.yaml
└── analysis_options.yaml
```

## 3. Antigravity Execution Order (each = one completable task/PR)

**Phase 0 — Foundation**
1. Scaffold project, add all pubspec deps, set up `analysis_options.yaml` (flutter_lints + custom rules), CI workflow.
2. Build `core/theme` (light+dark, `TradingColors` extension), `core/constants`, `core/utils` (currency/date formatters with Indian grouping).
3. Build all `data/models/` freezed classes from Doc 5 Section 1, run `build_runner`.
4. Build `shared_widgets/` — every component from Doc 4 Section 5, each with a Storybook-style demo screen behind a dev-only route for visual QA.

**Phase 1 — Auth & Shell**
5. Auth feature: splash → login → TOTP → PIN unlock, mock `AuthRepository`, session persisted via `flutter_secure_storage`.
6. App shell: `go_router` `ShellRoute` with 5-tab bottom nav, per-tab nested navigators, top app bar variants.

**Phase 2 — Market Data Backbone**
7. `data/mock/seed_instruments.dart` (~150 instruments + indices + generated option chain).
8. `data/mock/candle_generator.dart` (seeded random walk, multi-timeframe aggregation).
9. `data/mock/ticker_service.dart` (StreamProvider, subscribe/unsubscribe lifecycle).

**Phase 3 — Watchlist & Quote (core loop #1)**
10. Watchlist feature end-to-end (multiple lists, groups, starred, search-add, swipe actions, reorder).
11. Quote Detail screen (Overview/Depth/Fundamentals tabs) wired to `TickerService`.
12. Search feature (used by Watchlist "+", standalone tab search icon).

**Phase 4 — Charts**
13. `CandlestickChartView` custom painter (candle/line/bar render modes, pinch/pan/crosshair).
14. Indicator engine: SMA, EMA, RSI, MACD, Bollinger, VWAP + picker sheet with "more indicators — coming soon" placeholders for the rest of the 100+ list.
15. Full-screen chart route + drawing tools (trendline, horizontal line, fib retracement).

**Phase 5 — Orders Core Loop**
16. `order_simulation_engine.dart` (Market instant-fill, Limit/SL/SL-M tick-based fill checking).
17. Order Entry bottom sheet (all product/type/validity combinations, BO/CO fields, margin preview).
18. Orders screen (Pending/Executed/GTT tabs) + Order Detail (timeline + charges breakdown) + GTT create/list.
19. Positions screen (Day/Net, exit/add/convert actions) wired to fills from step 16.
20. Portfolio/Holdings screen + summary card, corporate-action banner (mock).

**Phase 6 — Money & Extras**
21. Funds screen + Add/Withdraw flows + ledger list.
22. Baskets feature (create, add legs, execute-all → feeds Orders).
23. SIP feature (create, list, pause/cancel, execution history).
24. Option Chain screen (expiry tabs, CE/PE table, tap-to-order).
25. IPO feature (list + apply flow + mock allotment resolution).
26. Alerts feature (create incl. multi-instrument, list, triggered → local notification).
27. Notification Center (feed + deep links).

**Phase 7 — Profile, Settings, Polish**
28. Profile/More screen, Settings sub-pages (theme, notifications, security, segments, about).
29. Reports (Tax P&L mock export) + Help & Support (FAQ + ticket form).
30. Empty/loading/error state pass across **every** list screen (FRD cross-cutting rule 5 — audit checklist).
31. Golden tests for every screen (light + dark) + unit tests for every controller/repository (≥70% coverage target on data/domain layers).
32. Final visual QA against Doc 4 Section 8 checklist; performance pass (250-row watchlist @60fps profiling).

---

## 4. Definition of Done (per task)

- Feature builds with `useMockData = true`, no other repository wired.
- Widget/unit tests exist for the controller and (if applicable) golden test for the screen.
- `flutter analyze` clean, no lint warnings.
- Screen manually checked against the relevant FRD entry (Doc 3) and Design System checklist (Doc 4 §8).
