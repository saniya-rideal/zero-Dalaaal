# Comprehensive API Contract & Mobile Integration Specification

**Version:** 2.0.0 (Production Release)  
**Base REST URL:** `http://<HOST>:5000`  
**WebSocket / Socket.IO URL:** `ws://<HOST>:5000` (or `http://<HOST>:5000` with polling/websocket transports)  
**Target Mobile Client:** Flutter (iOS & Android)

---

## IMPORTANT NOTICE: PAYMENTS OUT OF SCOPE
> [!IMPORTANT]
> **External Payment Gateway Integration is Out of Scope.**
> Real money payment gateways (e.g. Razorpay, Stripe, Cashfree) are NOT implemented by design.
> The backend operates a **production-grade paper trading ledger** with realistic simulated deposit/withdrawal workflows:
> 1. Deposits can be initiated via `POST /api/wallet/deposit/create` and verified via `POST /api/wallet/deposit/verify` (simulating instant success or bank confirmation).
> 2. Withdrawals can be requested via `POST /api/wallet/withdraw`, which reserves user cash balance in a dedicated locked state until approved or rejected by an admin via `/api/admin/wallet/withdrawals/:id/review`.
> 3. The financial ledger uses MongoDB multi-document ACID transactions with immutable double-entry `WalletTransaction` tracking and integer/decimal safety.

---

## 1. Global Standards & Protocol Conformance

### 1.1 Response Envelopes

Every JSON response from the server conforms strictly to either the standard Success envelope or the standard Error envelope.

#### Success Envelope
```json
{
  "success": true,
  "message": "Human-readable confirmation message",
  "data": { ... }
}
```

#### Error Envelope
```json
{
  "success": false,
  "errorCode": "VALIDATION_ERROR",
  "message": "Human-readable description of error",
  "errors": [
    { "field": "email", "message": "Valid email address is required" }
  ]
}
```

#### Standard List & Pagination Envelope
Whenever an endpoint returns a paginated list, `data` contains an array of items alongside a standard `pagination` object:
```json
{
  "success": true,
  "message": "Data retrieved successfully",
  "data": {
    "items": [ ... ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 142,
      "pages": 8
    }
  }
}
```

### 1.2 Common Error Codes
- `UNAUTHORIZED`: Missing, expired, or malformed Bearer JWT token.
- `FORBIDDEN`: User does not have privileges for this resource.
- `VALIDATION_ERROR`: Input payload failed schema validation checks.
- `NOT_FOUND`: Target entity does not exist.
- `RATE_LIMITED`: Rate limit exceeded. Check `Retry-After` HTTP header.
- `IDEMPOTENCY_CONFLICT`: Idempotency key already used with different parameters.
- `INSUFFICIENT_FUNDS`: Free cash balance is less than required margin/cost.
- `INSUFFICIENT_MARGIN`: Free leverage margin is less than required order margin.
- `ACCOUNT_NOT_FOUND`: User trading account not found.
- `MAINTENANCE_MODE`: Application is currently undergoing scheduled maintenance.
- `UPDATE_REQUIRED`: Client app version is below `minSupportedVersion`.
- `INTERNAL_SERVER_ERROR`: Unhandled exception on backend.

### 1.3 Rate Limiting Standards
1. **Public Auth Routes** (`/api/auth/login`, `/api/auth/register`, `/api/auth/verify-pin`, `/api/auth/forgot-password`, `/api/auth/verify-otp`, `/api/auth/reset-password`):
   - Strict per-IP limit: **30 attempts per 15 minutes** in production.
   - Exceeding returns HTTP 429 with `errorCode: "RATE_LIMITED"` and `Retry-After` in seconds.
2. **Authenticated API Routes** (`/api/*`):
   - Per-user rate limit: **600 requests per minute**.
3. **Wallet Endpoints** (`/api/wallet/*`):
   - Financial mutation limit: **120 requests per minute**.
4. **WebSocket Connections**:
   - Socket.IO ticks and live events do NOT count against REST rate limits.

### 1.4 Money & Precision Safety
- All balances, margins, trade amounts, and fee calculations are stored in exact numbers and evaluated without floating-point precision loss.
- All financial balance modifications (deposits, withdrawals, order executions, position closures, IPO bids, fees) run inside MongoDB transactions with strict ACID guarantees.

---

## 2. Authentication, Session & Security

### 2.1 Register
- **Method & Path:** `POST /api/auth/register`
- **Auth Required:** No
- **Headers:** `Content-Type: application/json`
- **Request Body:**
```json
{
  "name": "Jane Trader",
  "email": "jane@example.com",
  "mobile": "+919876543210",
  "password": "StrongPassword123!",
  "pin": "123456"
}
```
*(Validation: `name` min 2 chars; `email` valid format; `mobile` valid international phone; `password` min 8 chars; `pin` exactly 6 numeric digits).*
- **Response (`201 Created`):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "_id": "64f1a2b3c4d5e6f7a8b9c0d1",
      "clientId": "ZD104829",
      "name": "Jane Trader",
      "email": "jane@example.com",
      "mobile": "+919876543210",
      "role": "USER",
      "kycStatus": "NOT_STARTED",
      "status": "ACTIVE"
    },
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "7a3f81e..."
  }
}
```

### 2.2 Login (Step 1)
- **Method & Path:** `POST /api/auth/login`
- **Auth Required:** No
- **Request Body:**
```json
{
  "login": "jane@example.com",
  "password": "StrongPassword123!"
}
```
*(Accepts either email, phone, or `clientId` in `login`, `email`, or `identifier` fields).*
- **Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Password verified. Please enter your 6-digit PIN.",
  "data": {
    "tempToken": "eyJhbGciOi...",
    "requiresPin": true
  }
}
```

### 2.3 Verify PIN (Step 2)
- **Method & Path:** `POST /api/auth/verify-pin`
- **Auth Required:** No
- **Request Body:**
```json
{
  "tempToken": "eyJhbGciOi...",
  "pin": "123456"
}
```
- **Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "_id": "64f1a2b3c4d5e6f7a8b9c0d1",
      "clientId": "ZD104829",
      "name": "Jane Trader",
      "email": "jane@example.com",
      "mobile": "+919876543210",
      "role": "USER",
      "kycStatus": "NOT_STARTED"
    },
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "7a3f81e..."
  }
}
```

### 2.4 Setup PIN
- **Method & Path:** `POST /api/auth/setup-pin`
- **Auth Required:** Yes (via `tempToken` in Authorization header: `Bearer <tempToken>`)
- **Request Body:**
```json
{
  "pin": "654321"
}
```

### 2.5 Refresh Token (Rotation)
- **Method & Path:** `POST /api/auth/refresh-token`
- **Auth Required:** No
- **Request Body:**
```json
{
  "refreshToken": "7a3f81e..."
}
```
- **Response (`200 OK`):** Returns new `accessToken` and a freshly rotated `refreshToken`.

### 2.6 Forgot Password, OTP & Reset
- `POST /api/auth/forgot-password`: `{ "email": "jane@example.com" }` -> returns `{ "otpSent": true }`
- `POST /api/auth/verify-otp`: `{ "email": "jane@example.com", "otp": "492815" }` -> returns `{ "resetToken": "..." }`
- `POST /api/auth/reset-password`: `{ "resetToken": "...", "password": "NewPassword123!" }` -> returns success.

---

## 3. User Profile, KYC & Compliance

### 3.1 Get Profile
- **Method & Path:** `GET /api/account/profile`
- **Auth Required:** Yes
- **Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Profile fetched successfully",
  "data": {
    "user": {
      "_id": "64f1a2b3c4d5e6f7a8b9c0d1",
      "clientId": "ZD104829",
      "name": "Jane Trader",
      "email": "jane@example.com",
      "mobile": "+919876543210",
      "role": "USER",
      "kycStatus": "NOT_STARTED",
      "isKycApproved": false
    }
  }
}
```

### 3.2 Update Profile
- **Method & Path:** `PUT /api/account/profile`
- **Auth Required:** Yes
- **Request Body:** `{ "name": "Jane D. Trader" }`

### 3.3 KYC Status & Submission Flow
- **Workflow:** `NOT_STARTED` -> `SUBMITTED` / `UNDER_REVIEW` -> `APPROVED` or `REJECTED`.

#### Get KYC Status
- **Method & Path:** `GET /api/kyc/status`
- **Auth Required:** Yes
- **Response (`200 OK`):**
```json
{
  "success": true,
  "message": "KYC status fetched",
  "data": {
    "status": "SUBMITTED",
    "submittedAt": "2026-10-13T10:00:00.000Z",
    "reviewedAt": null,
    "rejectionReason": null,
    "documents": [
      {
        "documentType": "PAN",
        "documentNumber": "ABCDE1234F",
        "verified": false,
        "fileUrl": "/uploads/1791887484432-pan.jpg"
      }
    ]
  }
}
```

#### Upload KYC Document File
- **Method & Path:** `POST /api/kyc/upload`
- **Auth Required:** Yes
- **Request Body:**
```json
{
  "documentType": "PAN",
  "fileName": "pan_card.jpg",
  "fileData": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQ..."
}
```
*(Accepts standard Base64 string or Data URI. Returns `fileUrl`, `fileName`, and `size`).*

#### Submit KYC Documents for Review
- **Method & Path:** `POST /api/kyc/submit`
- **Auth Required:** Yes
- **Request Body:**
```json
{
  "panNumber": "ABCDE1234F",
  "panDocumentUrl": "/uploads/1791887484432-pan.jpg",
  "aadhaarNumber": "123456789012",
  "aadhaarDocumentUrl": "/uploads/1791887484432-aadhaar.jpg",
  "addressProofType": "AADHAAR",
  "addressProofUrl": "/uploads/1791887484432-aadhaar.jpg"
}
```

### 3.4 Pinned Instruments
- **Method & Path:** `GET /api/user/pinned-instruments`
- **Method & Path:** `PUT /api/user/pinned-instruments`
- **Auth Required:** Yes
- **Request Body (`PUT`):**
```json
{
  "symbols": ["NIFTY", "BANKNIFTY", "RELIANCE", "TCS"]
}
```
*(Max 4 symbols allowed. Stored in UserSettings).*

### 3.5 Risk Profiling
- **Method & Path:** `GET /api/user/risk-profile`
- **Method & Path:** `POST /api/user/risk-profile`
- **Auth Required:** Yes
- **Request Body (`POST`):**
```json
{
  "investmentHorizon": "LONG_TERM",
  "experienceLevel": "EXPERT",
  "lossTolerance": "HIGH",
  "answers": [
    { "questionId": "q1", "answer": "Aggressive capital appreciation" }
  ]
}
```
- **Response:** Returns `riskCategory` (`CONSERVATIVE`, `MODERATE`, `AGGRESSIVE`) and numeric `score` (0-100).

### 3.6 FATCA Declaration
- **Method & Path:** `GET /api/user/fatca`
- **Method & Path:** `POST /api/user/fatca`
- **Auth Required:** Yes
- **Request Body (`POST`):**
```json
{
  "taxResidentIndiaOnly": true,
  "countryOfBirth": "India",
  "citizenship": "Indian",
  "nationality": "Indian",
  "taxIdentificationNumber": "ABCDE1234F",
  "politicallyExposed": false,
  "occupation": "SALARIED",
  "annualIncome": "5_TO_10_LAKH"
}
```

### 3.7 Nominee Management
- **Method & Path:** `GET /api/user/nominees`
- **Method & Path:** `POST /api/user/nominees`
- **Auth Required:** Yes
- **Request Body (`POST`):**
```json
{
  "nominees": [
    {
      "name": "Sarah Trader",
      "relationship": "SPOUSE",
      "dob": "1994-04-12",
      "sharePercentage": 60,
      "idProofNumber": "PANO1234G"
    },
    {
      "name": "Leo Trader",
      "relationship": "CHILD",
      "dob": "2020-08-15",
      "sharePercentage": 40,
      "guardianName": "Sarah Trader",
      "guardianRelation": "MOTHER"
    }
  ]
}
```
*(Validation: 1 to 3 nominees. The sum of `sharePercentage` must equal exactly 100%).*

### 3.8 User Settings & Preferences
- **Method & Path:** `GET /api/user/settings`
- **Method & Path:** `PUT /api/user/settings`
- **Auth Required:** Yes
- **Request Body (`PUT`):**
```json
{
  "theme": "DARK",
  "biometricEnabled": true,
  "orderNotification": true,
  "priceAlertNotification": true,
  "chartType": "CANDLESTICK"
}
```

---

## 4. Wallet, Funds & Financial Ledger

### 4.1 Funds Summary
- **Method & Path:** `GET /api/funds/summary`
- **Auth Required:** Yes
- **Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Funds summary fetched",
  "data": {
    "cash": 100000.00,
    "bonus": 500.00,
    "tradingBalance": 100500.00,
    "marginUsed": 15200.00,
    "freeMargin": 85300.00,
    "withdrawable": 100000.00,
    "currency": "INR"
  }
}
```

### 4.2 Deposit Creation (Simulated / Non-Gateway)
- **Method & Path:** `POST /api/wallet/deposit/create`
- **Auth Required:** Yes
- **Headers:** `Idempotency-Key: <unique-uuid>`
- **Request Body:**
```json
{
  "amount": 25000,
  "currency": "INR"
}
```
- **Response (`201 Created`):**
```json
{
  "success": true,
  "message": "Deposit initiated",
  "data": {
    "deposit": {
      "_id": "64f1a2b3c4d5e6f7a8b9c0d9",
      "amount": 25000,
      "currency": "INR",
      "status": "PENDING",
      "paymentProvider": "SIMULATED"
    }
  }
}
```

### 4.3 Verify Deposit
- **Method & Path:** `POST /api/wallet/deposit/verify`
- **Auth Required:** Yes
- **Request Body:** `{ "depositId": "64f1a2b3c4d5e6f7a8b9c0d9" }`
- **Response (`200 OK`):** Automatically credits paper trading balance and applies eligible active bonus campaigns.

### 4.4 Request Withdrawal
- **Method & Path:** `POST /api/wallet/withdraw`
- **Auth Required:** Yes
- **Headers:** `Idempotency-Key: <unique-uuid>`
- **Request Body:**
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
*(Locks withdrawal amount from `withdrawable` cash balance into `PENDING` state until admin approves).*

### 4.5 Financial Ledger & Transaction Receipt
- `GET /api/wallet/ledger?page=1&limit=20`: Returns chronological immutable ledger entries (`DEPOSIT`, `WITHDRAWAL`, `BONUS`, `TRADE_PROFIT`, `TRADE_LOSS`, `TRADING_FEE`).
- `GET /api/wallet/transactions/:id/receipt`: Returns structured digital receipt with timestamp, reference, and account balance proof.

---

## 5. Market Data, Intelligence & Analysis

### 5.1 Market Status & Holidays
- **Method & Path:** `GET /api/market/status`
- **Auth Required:** No
- **Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Market status retrieved",
  "data": {
    "isOpen": true,
    "session": "REGULAR",
    "market": "INDIAN",
    "exchange": "NSE",
    "serverTimeIST": "11:30:00",
    "tradingDay": true
  }
}
```
- **Method & Path:** `GET /api/market/holidays?year=2026`
- **Response:** Returns official trading holidays list with closed exchanges and celebration names.

### 5.2 Instrument Search & Quotes
- `GET /api/market/search?q=tcs`: Fast prefix & token search across NSE/BSE equities and indices.
- `GET /api/market/instruments?market=INDIAN`: Lists all tradeable instruments.
- `GET /api/market/quotes?symbols=RELIANCE,TCS,INFY`: Returns current simulated or live market quotes.
- `GET /api/market/candles?symbol=RELIANCE&resolution=1D&from=...&to=...`: Returns OHLCV candle arrays.

### 5.3 Option Chain
- **Method & Path:** `GET /api/market/option-chain/:symbol?expiry=2026-10-29`
- **Auth Required:** No
- **Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Option chain retrieved",
  "data": {
    "optionChain": {
      "symbol": "NIFTY",
      "underlyingPrice": 24200.00,
      "expiryDate": "2026-10-29T00:00:00.000Z",
      "strikes": [
        {
          "strikePrice": 24200,
          "call": {
            "symbol": "NIFTY26OCT24200CE",
            "ltp": 145.20,
            "bid": 145.00,
            "ask": 145.40,
            "openInterest": 128500,
            "iv": 14.2
          },
          "put": {
            "symbol": "NIFTY26OCT24200PE",
            "ltp": 138.50,
            "bid": 138.20,
            "ask": 138.80,
            "openInterest": 142100,
            "iv": 15.1
          }
        }
      ]
    }
  }
}
```
- `GET /api/market/option-chain/expiries/:symbol`: Returns available expiry date strings for the underlying asset.

### 5.4 Sector Heatmap
- **Method & Path:** `GET /api/market/heatmap`
- **Response:** Returns list of sectors (e.g. IT, Banking, Auto, Energy) with advance/decline ratio and percentage change.

### 5.5 Stock Fundamentals, Corporate Actions & Calendar
- `GET /api/market/fundamentals/:symbol`: Market cap, P/E, P/B, EPS, ROE, 52-week High/Low, quarterly financials, and shareholding patterns (Promoter, FII, DII, Retail).
- `GET /api/market/corporate-actions?symbol=TCS`: Dividends, stock splits, bonuses, and rights issues with record and ex-dates.
- `GET /api/market/calendar`: Economic events, RBI interest decisions, GDP releases with impact levels (`HIGH`, `MEDIUM`, `LOW`).

---

## 6. Trading: Orders, Positions & Portfolio Holdings

### 6.1 Place Order
- **Method & Path:** `POST /api/orders`
- **Auth Required:** Yes
- **Headers:** `Idempotency-Key: <unique-uuid>`
- **Request Body:**
```json
{
  "symbol": "RELIANCE",
  "market": "INDIAN",
  "side": "BUY",
  "type": "MARKET",
  "quantity": 10,
  "leverage": 5,
  "stopLoss": 2900.00,
  "takeProfit": 3100.00
}
```
*(For `LIMIT` orders, provide `price`. Client execution price is ignored for `MARKET` orders; server executes strictly at current market bid/ask).*
- **Response (`201 Created`):** Returns order object and newly created/updated position.

### 6.2 Cancel Order
- **Method & Path:** `DELETE /api/orders/:id`
- **Auth Required:** Yes

### 6.3 Positions & Position Product Conversion
- `GET /api/positions?status=OPEN`: Lists user open leveraged trading positions.
- `POST /api/positions/:id/close`: Closes position at market price and realizes P&L.
- `PUT /api/positions/:id/convert`:
  - **Request Body:** `{ "targetProduct": "CNC" }`
  - Converts intraday leveraged margin position (`MIS`) to delivery equity holding (`CNC`) or vice-versa, debiting/crediting margin accordingly.

### 6.4 Portfolio Delivery Holdings
- **Method & Path:** `GET /api/portfolio/holdings`
- **Auth Required:** Yes
- **Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Holdings fetched successfully",
  "data": {
    "holdings": [
      {
        "symbol": "TCS",
        "exchange": "NSE",
        "quantity": 10,
        "averagePrice": 4000.00,
        "investedValue": 40000.00,
        "currentPrice": 4200.00,
        "currentValue": 42000.00,
        "pnl": 2000.00,
        "pnlPercent": 5.00
      }
    ],
    "totalInvested": 40000.00,
    "totalCurrent": 42000.00,
    "totalPnl": 2000.00,
    "totalPnlPercent": 5.00
  }
}
```
- `GET /api/portfolio/summary`: Consolidated overview of cash, holdings value, position margin, and overall net worth.

---

## 7. Reports, Statements & Tax Breakdown

### 7.1 Ledger Statement
- **Method & Path:** `GET /api/reports/ledger?startDate=2026-01-01&endDate=2026-12-31&page=1&limit=50`
- **Response:** Chronological ledger transactions with opening and closing balances.

### 7.2 Tradebook & P&L Statement
- `GET /api/reports/tradebook`: Detailed list of every order execution fill with timestamp, exchange order ID, brokerage, and statutory charges.
- `GET /api/reports/pnl`: Realized and unrealized P&L broken down by equity intraday vs delivery.

---

## 8. Advanced Automation: GTT, Baskets, SIP & Price Alerts

### 8.1 Good-Till-Triggered (GTT) Orders
- Evaluated on every server price quote tick. Safe against server restarts.
- **Create GTT:** `POST /api/gtt`
```json
{
  "symbol": "RELIANCE",
  "market": "INDIAN",
  "condition": "LTE",
  "triggerPrice": 2950.00,
  "orderSide": "BUY",
  "orderType": "LIMIT",
  "price": 2950.00,
  "quantity": 10,
  "leverage": 5
}
```
- Endpoints: `GET /api/gtt`, `GET /api/gtt/:id`, `PUT /api/gtt/:id`, `DELETE /api/gtt/:id`.

### 8.2 Order Baskets
- Allows creating and grouping multiple orders to be executed simultaneously.
- **Create Basket:** `POST /api/baskets`
```json
{
  "name": "Nifty Heavyweights",
  "orders": [
    { "symbol": "RELIANCE", "side": "BUY", "quantity": 10, "type": "MARKET" },
    { "symbol": "TCS", "side": "BUY", "quantity": 5, "type": "MARKET" }
  ]
}
```
- **Execute Basket:** `POST /api/baskets/:id/execute` (Requires `Idempotency-Key` header).
- Endpoints: `GET /api/baskets`, `GET /api/baskets/:id`, `PUT /api/baskets/:id`, `DELETE /api/baskets/:id`.

### 8.3 Systematic Investment Plans (SIP)
- Automatic recurring order scheduler (DAILY, WEEKLY, MONTHLY).
- **Create SIP:** `POST /api/sip`
```json
{
  "symbol": "RELIANCE",
  "market": "INDIAN",
  "frequency": "MONTHLY",
  "amount": 5000,
  "quantity": 2,
  "dayOfMonth": 5
}
```
- Endpoints: `GET /api/sip`, `GET /api/sip/:id`, `PUT /api/sip/:id`, `DELETE /api/sip/:id`, `POST /api/sip/:id/pause`, `POST /api/sip/:id/resume`.

### 8.4 Price Alerts
- Triggers when market quote reaches or crosses target threshold. Emits Socket.IO event and registers in-app notification.
- **Create Alert:** `POST /api/alerts`
```json
{
  "symbol": "RELIANCE",
  "targetPrice": 3050.00,
  "condition": "GTE",
  "note": "Book profit on long position"
}
```
- Endpoints: `GET /api/alerts`, `GET /api/alerts/:id`, `PUT /api/alerts/:id`, `DELETE /api/alerts/:id`, `POST /api/alerts/:id/toggle`.

---

## 9. In-App Notifications & Firebase Cloud Messaging (FCM)

- `GET /api/notifications?page=1&limit=20`: Stored user alerts and notifications.
- `GET /api/notifications/unread-count`: Returns integer badge count.
- `POST /api/notifications/:id/read`: Marks notification as read.
- `POST /api/notifications/read-all`: Marks all notifications as read.
- `DELETE /api/notifications/:id`: Deletes notification.
- `GET /api/notifications/preferences`: Get push & in-app toggle settings.
- `PUT /api/notifications/preferences`: Update push & in-app toggle settings.
- `POST /api/notifications/register-token`: Registers mobile device FCM push token:
```json
{
  "fcmToken": "cXYZ123...",
  "deviceType": "ANDROID"
}
```

---

## 10. News, IPOs, Legal, Charges & Education

### 10.1 Market News
- `GET /api/news?category=EQUITY&symbol=RELIANCE&page=1&limit=20`
- `GET /api/news/:id`

### 10.2 Initial Public Offerings (IPO)
- `GET /api/ipo?status=OPEN`: Lists current and upcoming IPO issues.
- `GET /api/ipo/:id`: Full prospectus details, issue dates, and price band.
- `POST /api/ipo/:id/apply`:
  - **Request Body:** `{ "lots": 1, "bidPrice": 390.00, "upiId": "trader@okhdfcbank" }`
  - Reserves paper trading funds from user account.
- `GET /api/ipo/applications`: Lists user IPO bids with status (`APPLIED`, `ALLOTTED`, `NOT_ALLOTTED`, `CANCELLED`).
- `DELETE /api/ipo/applications/:id`: Cancels bid and immediately refunds paper trading funds.

### 10.3 Dynamic Charges & Brokerage Calculator
- The mobile app must NOT hardcode brokerage rates. All rates are fetched from this endpoint:
- `GET /api/config/charges`: Returns active fee schedules (flat brokerage, STT %, exchange transaction %, GST %).
- `POST /api/config/charges/calculate`:
```json
{
  "tradeValue": 100000.00,
  "market": "INDIAN",
  "side": "BUY",
  "product": "MIS"
}
```
- **Response:**
```json
{
  "success": true,
  "data": {
    "brokerage": 20.00,
    "stt": 25.00,
    "exchangeTxnFee": 3.25,
    "gst": 4.18,
    "sebiCharges": 0.10,
    "stampDuty": 15.00,
    "totalCharges": 67.53
  }
}
```

### 10.4 Legal Documents & App Version Config
- `GET /api/legal/:slug`: Fetches markdown content for `terms-and-conditions`, `privacy-policy`, `risk-disclosure`, `tariff-sheet`.
- `GET /api/system/app-config`: Returns `isUnderMaintenance`, `maintenanceMessage`, `minSupportedVersion`, `latestVersion`, `forceUpdateUrl`.

### 10.5 Trading Academy & Education
- `GET /api/learning/modules`: Educational courses with lessons and interactive quiz challenges.
- `GET /api/learning/modules/:id`: Detailed module lessons.
- `POST /api/learning/quiz/:lessonId/submit`: Submits quiz responses and awards paper trading achievement score.

---

## 11. Customer Support Tickets & Live Chat

### 11.1 Support Tickets
- `GET /api/support/tickets?status=OPEN&page=1&limit=20`: Lists user tickets.
- `POST /api/support/tickets`:
```json
{
  "subject": "Execution query on NIFTY order",
  "category": "TRADING",
  "priority": "HIGH",
  "message": "Order 1024 took 1 second to execute at limit price."
}
```
- `GET /api/support/tickets/:id`: Retrieves full ticket thread with conversation messages.
- `POST /api/support/tickets/:id/reply`:
```json
{
  "message": "Thank you for the explanation."
}
```
*(All messages are delivered in real time to open ticket rooms via Socket.IO).*

---

## 12. Real-Time Socket.IO Protocol

### 12.1 Authentication & Room Joining
- **Connection URL:** `ws://<HOST>:5000`
- **Auth Handshake:**
```javascript
const socket = io('http://localhost:5000', {
  auth: {
    token: 'Bearer <USER_ACCESS_TOKEN>'
  }
});
```
- Upon authenticated connection:
  - The server automatically joins the socket to room `user:<userId>`.
  - If user is ADMIN, socket automatically joins `admin:room`.

### 12.2 Client-Emitted Events

| Event Name | Direction | Payload Example | Description |
| :--- | :--- | :--- | :--- |
| `subscribe:symbol` | Client -> Server | `{ "symbol": "RELIANCE" }` | Subscribe to live quote ticks for a symbol |
| `unsubscribe:symbol` | Client -> Server | `{ "symbol": "RELIANCE" }` | Unsubscribe from symbol quote ticks |
| `subscribe:market` | Client -> Server | `{ "market": "INDIAN" }` | Subscribe to all quotes for a market |
| `ticket:join` | Client -> Server | `{ "ticketId": "TIC-ABC123" }` | Join live chat room for a support ticket |
| `ticket:leave` | Client -> Server | `{ "ticketId": "TIC-ABC123" }` | Leave live chat room for a support ticket |

### 12.3 Server-Emitted Events

| Event Name | Direction | Payload Structure | Description |
| :--- | :--- | :--- | :--- |
| `quote:update` | Server -> Client | `MarketQuote` object | Emitted on price change to subscribed symbol rooms |
| `order:update` | Server -> Client | `Order` object | Emitted to `user:<userId>` on order state transition |
| `position:update` | Server -> Client | `Position` object | Emitted to `user:<userId>` on margin or P&L update |
| `gtt:triggered` | Server -> Client | `{ "gttId", "symbol", "triggerPrice", "orderId" }` | Emitted to `user:<userId>` when GTT condition met |
| `alert:triggered` | Server -> Client | `{ "alertId", "symbol", "targetPrice", "currentPrice" }` | Emitted to `user:<userId>` when price alert triggers |
| `sip:executed` | Server -> Client | `{ "sipId", "symbol", "amount", "orderId" }` | Emitted to `user:<userId>` when recurring SIP triggers |
| `notification:new` | Server -> Client | `Notification` object | Emitted to `user:<userId>` on new in-app alert |
| `support:message` | Server -> Client | `{ "ticketId", "message": MessageObject }` | Emitted to `ticket:<id>` on user or admin reply |

---

## 13. System Health & Probes
- `GET /health`: Liveness probe. Returns HTTP 200 `{ "status": "UP", "uptime": 1234 }`.
- `GET /ready`: Readiness probe. Returns HTTP 200 `{ "status": "READY", "database": "CONNECTED" }` when MongoDB is fully operational.
