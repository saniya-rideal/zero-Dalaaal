# Backend Gaps Specification

This document records the screens and features in the ZeroDalali mobile app that require endpoints currently not present in `API_CONTRACT.md` (v2.0.0). In accordance with the production architecture guidelines, **no mock or synthetic data has been invented**. Screens display honest empty or fallback states until these backend endpoints are implemented.

---

### Gap 1: Multi-Group Custom Watchlists CRUD
- **Affected Screens:** `WatchlistScreen` (`/watchlist`), `AddScriptScreen` (`/add-script`)
- **What is Needed:** Full CRUD for creating, renaming, deleting, and populating multiple custom named watchlists (e.g., "Nifty 50", "Tech Stocks", "Commodities") with arbitrary instrument symbols.
- **Current Contract Status:** `API_CONTRACT.md` Section 3.4 only provides:
  - `GET /api/user/pinned-instruments`
  - `PUT /api/user/pinned-instruments`
  (Limited to maximum 4 symbols stored inside `UserSettings`).
- **Suggested API Specification:**
  - `GET /api/watchlists`: Lists user watchlists.
    ```json
    {
      "success": true,
      "data": {
        "watchlists": [
          {
            "id": "wl_64f1a2b3",
            "name": "Nifty 50 Watch",
            "symbols": ["RELIANCE", "TCS", "INFY", "HDFCBANK"],
            "createdAt": "2026-10-13T10:00:00.000Z"
          }
        ]
      }
    }
    ```
  - `POST /api/watchlists`: `{ "name": "Banking" }`
  - `PUT /api/watchlists/:id`: `{ "name": "Private Banks", "symbols": ["HDFCBANK", "ICICIBANK"] }`
  - `DELETE /api/watchlists/:id`: Deletes watchlist.
- **Client Fallback:** The mobile app uses `GET /api/user/pinned-instruments` as the primary live watchlist and displays market instruments from `GET /api/market/instruments`. If `/api/watchlists` is unavailable, an honest empty/unavailable state is presented.

---

### Gap 2: Saved Linked Bank Accounts
- **Affected Screens:** `FundsScreen` (`/funds`), `WithdrawFundsSheet`, `AddFundsSheet`
- **What is Needed:** Endpoints to retrieve and manage pre-verified linked bank accounts for seamless withdrawals and deposits.
- **Current Contract Status:** `API_CONTRACT.md` Section 4.4 (`POST /api/wallet/withdraw`) expects inline payment details:
  ```json
  {
    "amount": 10000,
    "currency": "INR",
    "paymentDetails": {
      "method": "BANK_TRANSFER",
      "accountNumber": "987654321012",
      "ifsc": "HDFC0001234"
    }
  }
  ```
  However, there is no endpoint to list or save pre-linked bank accounts.
- **Suggested API Specification:**
  - `GET /api/user/bank-accounts`:
    ```json
    {
      "success": true,
      "data": {
        "accounts": [
          {
            "id": "bank_01",
            "bankName": "HDFC Bank Ltd",
            "accountNumberMasked": "•••• •••• 1212",
            "accountNumber": "987654321212",
            "ifsc": "HDFC0001234",
            "isPrimary": true,
            "isVerified": true
          }
        ]
      }
    }
    ```
  - `POST /api/user/bank-accounts`: Adds bank account for penny-drop verification.
  - `DELETE /api/user/bank-accounts/:id`: Unlinks bank account.
- **Client Fallback:** Withdrawal UI provides explicit bank details entry fields (Account Number & IFSC) complying with Section 4.4, without relying on hardcoded mock bank accounts.

---

### Gap 3: Broker Terminal Deals & Net Deals Aggregation
- **Affected Screens:** `DealsScreen` (`/deals`), `NetDealsScreen` (`/net-deals`)
- **What is Needed:** Server-side aggregation for gross positions, filled deals, and net intraday exposure per symbol across equity and commodity segments.
- **Current Contract Status:** The contract exposes `/api/orders`, `/api/positions?status=OPEN`, and `/api/reports/tradebook`, but does not provide a dedicated `/api/trading/deals` or `/api/trading/net-deals` aggregation.
- **Suggested API Specification:**
  - `GET /api/trading/deals`: Returns combined list of pending orders and active positions formatted for terminal deals grids.
  - `GET /api/trading/net-deals`: Returns net quantities and consolidated P&L grouped by instrument token.
- **Client Fallback:** The client dynamically maps open positions (`/api/positions`) and today's executed trade fills (`/api/reports/tradebook`) to render Deals and Net Deals, ensuring 100% real ledger fidelity without synthesizing dummy deals.

---

### Gap 4: Brokerage Bulletins / Mail Center
- **Affected Screens:** `MailsScreen` (`/mails`)
- **What is Needed:** Official exchange circulars, regulatory announcements, and contract notes delivered via dedicated mail/circular inbox.
- **Current Contract Status:** Only `/api/notifications` is available for general user alerts.
- **Suggested API Specification:**
  - `GET /api/mails?page=1&limit=20`:
    ```json
    {
      "success": true,
      "data": {
        "items": [
          {
            "id": "mail_01",
            "subject": "NSE Circular: Revision in F&O Expiry Schedule",
            "sender": "Exchange Compliance Desk",
            "body": "Markdown or HTML announcement text...",
            "date": "2026-10-13T09:00:00.000Z",
            "attachments": []
          }
        ]
      }
    }
    ```
- **Client Fallback:** Mails screen displays system notifications from `GET /api/notifications` filtered by category `SYSTEM`, or shows an honest empty state when no mail items exist.

---

### Gap 5: What-If / Margin Simulation Calculator Endpoint
- **Affected Screens:** `MarginCalculatorScreen` (`/margin-calculator`), `ProfitCalculatorScreen` (`/profit-calculator`)
- **What is Needed:** Server-side pre-trade margin requirement simulation for basket or multi-leg strategy combos before order placement.
- **Current Contract Status:** Section 10.3 provides `/api/config/charges/calculate` for statutory brokerage and tax calculations, but no dedicated simulated margin engine (`/api/margin/calculate`).
- **Suggested API Specification:**
  - `POST /api/margin/calculate`:
    ```json
    {
      "orders": [
        { "symbol": "NIFTY26OCT24200CE", "side": "BUY", "quantity": 50, "product": "MIS" },
        { "symbol": "NIFTY26OCT24500CE", "side": "SELL", "quantity": 50, "product": "MIS" }
      ]
    }
    ```
    Returns: `{ "initialMargin": 12500.00, "exposureMargin": 3500.00, "spanMargin": 8000.00, "totalMargin": 24000.00, "marginBenefit": 15000.00 }`.
- **Client Fallback:** The client uses `POST /api/config/charges/calculate` for real statutory fees and computes margin requirements using the instrument's official leverage parameters from `GET /api/market/instruments`.

---

### Gap 6: Real-time Live Support Chat Socket Protocol
- **Affected Screens:** `LiveChatSheet` (`/live-chat`), `TicketDetailScreen` (`/support/ticket/:id`)
- **What is Needed:** Dedicated WebSocket rooms and events for two-way live customer support communication with support desk executives.
- **Current Contract Status:** `API_CONTRACT.md` Section 11 specifies WebSocket connections primarily for market ticker quotes (`quote:{symbol}`), depth updates (`depth:{symbol}`), and user notifications (`user:{userId}`). It does not specify live support message packet framing or agent presence events (`support:typing`, `support:message`, `support:join`).
- **Suggested Protocol Specification:**
  - WebSocket Room: `support:ticket:{ticketId}`
  - Client sends:
    ```json
    { "event": "support:message:send", "data": { "ticketId": "TK-2026-84920", "message": "My deposit is delayed." } }
    ```
  - Server emits:
    ```json
    { "event": "support:message:received", "data": { "ticketId": "TK-2026-84920", "messageId": "msg_901", "sender": "Agent Vikram (ID: 412)", "text": "I am reviewing your UTR now.", "timestamp": "2026-10-14T09:30:00Z" } }
    ```
- **Client Fallback:** The app utilizes HTTP polling on `GET /api/support/tickets/:id` and posts message replies via `POST /api/support/tickets/:id/reply`, while gracefully binding to live WebSocket updates whenever the server broadcasts on the ticket room.

---

### Gap 7: Server-Side GTT (Good-Till-Triggered) Trigger Engine & Event Webhooks
- **Affected Screens:** `OrdersScreen` (GTT tab), `OrderDetailScreen`
- **What is Needed:** Active exchange-side/broker-side trigger engine that executes market or limit orders when the underlying instrument crosses trigger price conditions, emitting push notifications and order status transitions.
- **Current Contract Status:** Section 6 specifies `/api/gtt` endpoints for CRUD operations on GTT orders (`POST /api/gtt`, `GET /api/gtt`, `DELETE /api/gtt/:id`), but trigger execution lifecycle states (`TRIGGERED`, `PLACED`, `REJECTED`) and margin reservation rules upon trigger are managed asynchronously by the exchange order routing system.
- **Client Fallback:** The client renders honest server-provided GTT states (`ACTIVE`, `TRIGGERED`, `CANCELLED`, `EXPIRED`) from `GET /api/gtt` without simulating trigger conditions locally on the device.

---

### Gap 8: Client Support Ticket Status Transition (Close / Reopen)
- **Affected Screens:** `TicketDetailScreen` (`/support/ticket/:id`), `HelpSupportScreen` (`/support`)
- **What is Needed:** An authenticated endpoint allowing the client to explicitly update ticket status (e.g., mark as `RESOLVED` or `CLOSED` directly from the mobile app).
- **Current Contract Status:** `API_CONTRACT.md` Section 11 only specifies `GET /api/support/tickets`, `POST /api/support/tickets`, `GET /api/support/tickets/:id`, and `POST /api/support/tickets/:id/reply`. Status mutations (`PUT /api/admin/support/tickets/:id/status`) are restricted to administrators. Automatic transition from `CLOSED` to `IN_PROGRESS` occurs when a user replies via `POST /api/support/tickets/:id/reply`.
- **Client Fallback:** Removed the unsupported `PUT /api/support/tickets/:id` client call in `SupportRepository`. The mobile client interacts with support tickets exclusively via message replies and reads the server's authoritative status.

---

### Gap 9: Option Chain Contract Token Identifiers & Analytics Aggregation
- **Affected Screens:** `OptionChainScreen` (`/option-chain`), `OrderEntrySheet`
- **What is Needed:** Dedicated exchange trading token identifiers (e.g. `token: "opt_nifty_24500_ce"` or tradable symbol `"NIFTY26OCT24500CE"`) on each strike's call and put objects in `/api/market/option-chain/:symbol`, along with summary metrics (Total Call OI, Total Put OI, Put-Call Ratio PCR, and Max Pain strike).
- **Current Contract Status:** `GET /api/market/option-chain/:symbol` returns `underlyingPrice`, `expiryDate`, and `strikes[]` with `call` and `put` pricing objects (`ltp`, `oi`, `oiChange`, `iv`, `volume`, `bid`, `ask`), but omits specific order routing tokens and aggregate PCR/Max Pain metrics.
- **Client Fallback:** The client synthesizes statutory option contract trading symbols from the parent symbol, strike, and option type (e.g. `NIFTY 24500 CE`), and computes ATM strike highlighting dynamically using minimal distance to `underlyingPrice`.


