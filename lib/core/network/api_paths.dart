/// Centralized backend API endpoint paths adhering strictly to API_CONTRACT.md (v2.0.0)
class ApiPaths {
  ApiPaths._();

  // 1. System & Health
  static const String health = '/health';
  static const String ready = '/ready';
  static const String appConfig = '/api/system/app-config';
  static String legal(String slug) => '/api/legal/$slug';

  // 2. Authentication & Session
  static const String authRegister = '/api/auth/register';
  static const String authLogin = '/api/auth/login';
  static const String authGoogle = '/api/auth/google';
  static const String authVerifyPin = '/api/auth/verify-pin';
  static const String authSetupPin = '/api/auth/setup-pin';
  static const String authSetPin = '/api/auth/setup-pin';
  static const String authRefreshToken = '/api/auth/refresh-token';
  static const String authSendOtp = '/api/auth/send-otp';
  static const String authForgotPassword = '/api/auth/forgot-password';
  static const String authVerifyOtp = '/api/auth/verify-otp';
  static const String authResetPassword = '/api/auth/reset-password';
  static const String authLogout = '/api/auth/logout';

  // 3. User Profile, KYC & Compliance
  static const String profile = '/api/account/profile';
  static const String kycStatus = '/api/kyc/status';
  static const String kycUpload = '/api/kyc/upload';
  static const String kycSubmit = '/api/kyc/submit';
  static const String pinnedInstruments = '/api/user/pinned-instruments';
  static const String riskProfile = '/api/user/risk-profile';
  static const String fatca = '/api/user/fatca';
  static const String nominees = '/api/user/nominees';
  static const String userSettings = '/api/user/settings';

  // 4. Wallet, Funds & Financial Ledger
  static const String fundsSummary = '/api/funds/summary';
  static const String walletDepositCreate = '/api/wallet/deposit/create';
  static const String walletDepositVerify = '/api/wallet/deposit/verify';
  static const String walletWithdraw = '/api/wallet/withdraw';
  static const String walletWithdrawals = '/api/wallet/withdrawals';
  static const String walletDeposits = '/api/wallet/deposits';
  static const String walletLedger = '/api/wallet/ledger';
  static String walletTransactionReceipt(String id) => '/api/wallet/transactions/$id/receipt';

  // 4.1 Real UPI Payment Orders
  static const String paymentOrders = '/api/payments/orders';
  static String paymentOrderDetail(String id) => '/api/payments/orders/$id';
  static String paymentOrderCancel(String id) => '/api/payments/orders/$id/cancel';

  // 5. Market Data, Intelligence & Analysis
  static const String marketStatus = '/api/market/status';
  static const String marketHolidays = '/api/market/holidays';
  static const String marketSearch = '/api/market/search';
  static const String marketInstruments = '/api/market/instruments';
  static const String marketQuotes = '/api/market/quotes';
  static const String marketCandles = '/api/market/candles';
  static String marketOptionChain(String symbol) => '/api/market/option-chain/$symbol';
  static String marketOptionChainExpiries(String symbol) => '/api/market/option-chain/expiries/$symbol';
  static const String marketHeatmap = '/api/market/heatmap';
  static String marketFundamentals(String symbol) => '/api/market/fundamentals/$symbol';
  static const String marketCorporateActions = '/api/market/corporate-actions';
  static const String marketCalendar = '/api/market/calendar';

  // 6. Trading: Orders, Positions & Portfolio Holdings
  static const String orders = '/api/orders';
  static const String ordersPreview = '/api/orders/preview';
  static String orderDetail(String id) => '/api/orders/$id';
  static String orderCancel(String id) => '/api/orders/$id/cancel';
  static const String positions = '/api/positions';
  static String closePosition(String id) => '/api/positions/$id/close';
  static String convertPosition(String id) => '/api/positions/$id/convert';
  static const String portfolioHoldings = '/api/portfolio/holdings';
  static const String portfolioSummary = '/api/portfolio/summary';

  // 7. Reports, Statements & Tax Breakdown
  static const String reportsLedger = '/api/reports/ledger';
  static const String reportsTradebook = '/api/reports/tradebook';
  static const String reportsPnl = '/api/reports/pnl';

  // 8. Automation: GTT, Baskets, SIP & Price Alerts
  static const String gtt = '/api/gtt';
  static String gttDetail(String id) => '/api/gtt/$id';
  static const String baskets = '/api/baskets';
  static String basketDetail(String id) => '/api/baskets/$id';
  static String basketExecute(String id) => '/api/baskets/$id/execute';
  static const String sip = '/api/sip';
  static String sipDetail(String id) => '/api/sip/$id';
  static String sipPause(String id) => '/api/sip/$id/pause';
  static String sipResume(String id) => '/api/sip/$id/resume';
  static const String alerts = '/api/alerts';
  static String alertDetail(String id) => '/api/alerts/$id';
  static String alertToggle(String id) => '/api/alerts/$id/toggle';

  // 9. In-App Notifications & FCM
  static const String notifications = '/api/notifications';
  static const String notificationsUnreadCount = '/api/notifications/unread-count';
  static String notificationRead(String id) => '/api/notifications/$id/read';
  static const String notificationsReadAll = '/api/notifications/read-all';
  static String notificationDelete(String id) => '/api/notifications/$id';
  static String notificationById(String id) => '/api/notifications/$id';
  static const String notificationPreferences = '/api/notifications/preferences';
  static const String notificationRegisterToken = '/api/notifications/register-token';

  // 10. News, IPOs, Legal, Charges & Education
  static const String news = '/api/news';
  static String newsDetail(String id) => '/api/news/$id';
  static String newsById(String id) => '/api/news/$id';
  static const String ipo = '/api/ipo';
  static String ipoDetail(String id) => '/api/ipo/$id';
  static String ipoById(String id) => '/api/ipo/$id';
  static String ipoApply(String id) => '/api/ipo/$id/apply';
  static const String ipoApplications = '/api/ipo/applications';
  static String ipoApplicationCancel(String id) => '/api/ipo/applications/$id';
  static String ipoApplicationById(String id) => '/api/ipo/applications/$id';
  static const String configCharges = '/api/config/charges';
  static const String chargesConfig = configCharges;
  static const String configChargesCalculate = '/api/config/charges/calculate';
  static const String chargesCalculate = configChargesCalculate;

  // Aliases for detail endpoints
  static String alertById(String id) => alertDetail(id);
  static String basketById(String id) => basketDetail(id);
  static String sipById(String id) => sipDetail(id);
  static String gttById(String id) => gttDetail(id);
  static const String learningModules = '/api/learning/modules';
  static String learningModuleDetail(String id) => '/api/learning/modules/$id';
  static String learningQuizSubmit(String lessonId) => '/api/learning/quiz/$lessonId/submit';

  // 11. Customer Support Tickets & Live Chat
  static const String supportTickets = '/api/support/tickets';
  static String supportTicketDetail(String id) => '/api/support/tickets/$id';
  static String supportTicketReply(String id) => '/api/support/tickets/$id/reply';

  // Watchlists (Extension / Fallback for custom multi-watchlist groups)
  static const String watchlists = '/api/watchlists';
  static String watchlistDetail(String id) => '/api/watchlists/$id';
}
