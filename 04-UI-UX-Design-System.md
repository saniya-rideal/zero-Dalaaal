# UI/UX Design System
## Zero — Visual Language (Kite-parity)

---

## 1. Brand Colors

| Token | Hex | Usage |
|---|---|---|
| `primaryBlue` | `#387ED1` | Primary actions, Buy accents in some contexts, links, active tab indicator (Kite's signature blue) |
| `bullishGreen` | `#00A854` (light) / `#26A69A`-style variants acceptable | Gains, Buy button, up-candles |
| `bearishRed` | `#EB5B3C` / `#FF5722`-style | Losses, Sell button, down-candles |
| `neutralGrey` | `#787878` | Zero-change values, secondary text |
| `background.light` | `#FFFFFF` | Light theme base |
| `background.dark` | `#131722` | Dark theme base (chart-friendly near-black navy, matches trading-app convention) |
| `surface.light` | `#F5F6F7` | Cards, list rows on light theme |
| `surface.dark` | `#1E222D` | Cards, list rows on dark theme |
| `divider` | `#E0E0E0` (light) / `#2A2E39` (dark) | Row separators |
| `warningAmber` | `#F5A623` | AMO/pending/warning chips |

## 2. Typography

- Font family: **Inter** (or Roboto as fallback) — clean grotesque sans, matches Kite's system-font approach.
- Scale:
  - Display (LTP big numbers): 28sp, weight 600
  - H1 (screen titles): 20sp, weight 600
  - H2 (section headers): 16sp, weight 600
  - Body: 14sp, weight 400
  - Caption/labels: 12sp, weight 400
  - Numeric tabular figures: use `FontFeature.tabularFigures()` everywhere prices/quantities are listed in columns, so digits align.

## 3. Iconography

- Line-style icons, 1.5–2px stroke, 24x24 default grid (use `flutter_svg` custom icon set or Material Symbols Outlined as base + custom trading glyphs for candlestick/depth/alert-bell-with-dot).
- Directional glyphs (▲/▼) always paired with color for colorblind accessibility (see FRD cross-cutting rule 1).

## 4. Layout & Spacing

- 8pt grid system: spacing tokens 4, 8, 12, 16, 24, 32.
- List row height: 56dp (watchlist/orders/positions), 72dp for rows with two-line content (portfolio holdings).
- Bottom sheets: rounded top corners 16dp radius, drag handle bar, max-height 90% of screen, scrollable content area, sticky footer button.
- Standard screen padding: 16dp horizontal.

## 5. Components (build as shared_widgets/)

| Component | Notes |
|---|---|
| `PriceText` | Renders value + auto color (green/up, red/down, grey/flat) + optional ▲▼ glyph + flash animation (150ms background pulse) on value change |
| `SegmentedTabBar` | Used for Buy/Sell, Day/Net, Pending/Executed/GTT, Light/Dark |
| `ExchangeChip` | Small pill: "NSE" / "BSE" / "NFO" / "MCX", muted background |
| `InstrumentRow` | Watchlist/search row: symbol, exchange chip, LTP block, swipe actions |
| `OrderBottomSheet` | Full order-entry sheet, parametrized by Buy/Sell + prefilled instrument |
| `EmptyStateView` | Illustration (simple line-art SVG) + title + subtitle + optional CTA button |
| `SkeletonLoader` | Shimmer placeholder for list rows and cards |
| `SectionCard` | Rounded 12dp card, `surface` color, used for summaries (Portfolio, Funds) |
| `CandlestickChartView` | Custom-painter chart widget, accepts OHLC list + indicator overlays |
| `DepthLadder` | 5x5 bid/ask table with proportional qty bars |
| `PinInputPad` | 6-digit PIN entry, shake-on-error animation |
| `MarginSummaryBar` | Sticky bar in order sheet showing computed margin |

## 6. Motion

- Tab switch: 200ms crossfade, no slide (matches Kite's snappy feel).
- Bottom sheet: 250ms ease-out slide-up with backdrop fade.
- Price flash: 150ms background color pulse (green/red tint) on any LTP update, then fade back to transparent.
- Pull-to-refresh: standard Material spinner tinted `primaryBlue`.
- Order confirm button: subtle scale-down (0.97) on press for tactile feedback.

## 7. Theming Implementation

- `ThemeExtension<TradingColors>` holding `bullish`, `bearish`, `neutral`, `chartGrid`, `chartBackground` — registered once in both `ThemeData.light()` and `ThemeData.dark()` so widgets pull semantic colors via `Theme.of(context).extension<TradingColors>()!.bullish` rather than hardcoding hex anywhere in feature code.
- Respect system theme by default; manual override persisted in Settings (Hive).

## 8. Screen-Reference Checklist (for visual QA against real Kite)

- [ ] Watchlist row spacing/typography matches (symbol bold, exchange muted small-caps chip, LTP right-aligned tabular figures)
- [ ] Buy = blue-tinted CTA in some Kite surfaces, green in others — standardize: **Buy = green, Sell = red** everywhere in this clone (simpler, consistent, still instantly recognizable)
- [ ] Order sheet drag-handle + rounded top corners present on every bottom sheet
- [ ] Charts default to candlestick + 1D timeframe on open, matching Kite default
- [ ] Empty/loading/error states styled consistently across all 18 list-based screens
- [ ] Dark theme contrast checked (WCAG AA minimum) on all price/P&L text over `surface.dark`
