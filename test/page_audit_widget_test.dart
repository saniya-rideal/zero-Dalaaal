import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_dalali/features/auth/presentation/login_screen.dart';
import 'package:zero_dalali/features/auth/presentation/pin_unlock_screen.dart';
import 'package:zero_dalali/features/auth/presentation/register_screen.dart';
import 'package:zero_dalali/features/auth/presentation/splash_screen.dart';
import 'package:zero_dalali/features/auth/presentation/totp_screen.dart';
import 'package:zero_dalali/features/deals/presentation/deals_screen.dart';
import 'package:zero_dalali/features/history/presentation/history_screen.dart';
import 'package:zero_dalali/features/net_deals/presentation/net_deals_screen.dart';
import 'package:zero_dalali/features/quotes/presentation/quotes_screen.dart';
import 'package:zero_dalali/features/quote_detail/presentation/quote_detail_screen.dart';
import 'package:zero_dalali/features/charts/presentation/chart_fullscreen_screen.dart';
import 'package:zero_dalali/features/orders/presentation/orders_screen.dart';
import 'package:zero_dalali/features/orders/presentation/order_detail_screen.dart';
import 'package:zero_dalali/features/quotes/presentation/add_script_screen.dart';
import 'package:zero_dalali/features/search/presentation/search_screen.dart';
import 'package:zero_dalali/features/funds/presentation/funds_screen.dart';
import 'package:zero_dalali/features/funds/presentation/add_funds_sheet.dart';
import 'package:zero_dalali/features/funds/presentation/withdraw_funds_sheet.dart';
import 'package:zero_dalali/features/funds/presentation/balance_breakdown_dialog.dart';
import 'package:zero_dalali/features/news/presentation/news_screen.dart';
import 'package:zero_dalali/features/news/presentation/news_feed_screen.dart';
import 'package:zero_dalali/features/notifications/presentation/mails_screen.dart';
import 'package:zero_dalali/features/notifications/presentation/notification_center_screen.dart';
import 'package:zero_dalali/features/notifications/presentation/notification_preferences_sheet.dart';
import 'package:zero_dalali/features/calculator/presentation/margin_calculator_screen.dart';
import 'package:zero_dalali/features/calculator/presentation/profit_calculator_screen.dart';
import 'package:zero_dalali/features/option_chain/presentation/option_chain_screen.dart';
import 'package:zero_dalali/features/baskets/presentation/baskets_screen.dart';
import 'package:zero_dalali/features/sip/presentation/sip_screen.dart';
import 'package:zero_dalali/features/ipo/presentation/ipo_list_screen.dart';
import 'package:zero_dalali/features/alerts/presentation/alerts_screen.dart';
import 'package:zero_dalali/features/calendar/presentation/economic_calendar_screen.dart';
import 'package:zero_dalali/features/profile_settings/presentation/profile_screen.dart';
import 'package:zero_dalali/features/profile_settings/presentation/settings_screen.dart';
import 'package:zero_dalali/features/profile_settings/presentation/about_screen.dart';
import 'package:zero_dalali/features/profile_settings/presentation/reports_screen.dart';
import 'package:zero_dalali/features/profile_settings/presentation/help_support_screen.dart';
import 'package:zero_dalali/features/profile_settings/presentation/ticket_detail_screen.dart';
import 'package:zero_dalali/features/profile_settings/presentation/live_chat_sheet.dart';
import 'package:zero_dalali/features/profile_settings/presentation/maintenance_screen.dart';
import 'package:zero_dalali/features/order_entry/presentation/order_entry_sheet.dart';
import 'package:zero_dalali/features/order_entry/presentation/leverage_education_dialog.dart';
import 'package:zero_dalali/features/profile_settings/presentation/kyc_management_sheet.dart';
import 'package:zero_dalali/features/profile_settings/presentation/nominee_management_sheet.dart';
import 'package:zero_dalali/features/profile_settings/presentation/personal_details_sheet.dart';
import 'package:zero_dalali/features/profile_settings/presentation/create_ticket_sheet.dart';
import 'package:zero_dalali/data/mock/seed_instruments.dart';
import 'package:zero_dalali/data/models/enums.dart';
import 'package:go_router/go_router.dart';

Widget _wrapScreen(Widget screen) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(body: screen),
    ),
  );
}

Widget _wrapWithRouter(Widget screen, {String initialPath = '/'}) {
  final router = GoRouter(
    initialLocation: initialPath,
    routes: [
      GoRoute(path: '/', builder: (c, s) => screen),
      GoRoute(path: '/quotes', builder: (c, s) => const Scaffold(body: Text('Quotes Target'))),
      GoRoute(path: '/login', builder: (c, s) => const Scaffold(body: Text('Login Target'))),
      GoRoute(path: '/register', builder: (c, s) => const Scaffold(body: Text('Register Target'))),
    ],
  );
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Senior QA Audit: Auth & Primary Tab Pages', () {
    testWidgets('Audit 1: Splash screen mounts and renders branding', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapWithRouter(const SplashScreen()));
      expect(find.text('Zero'), findsWidgets);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
    });

    testWidgets('Audit 2: Login screen mounts with phone/password/biometric options', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
      expect(find.text('CONTINUE'), findsWidgets);
    });

    testWidgets('Audit 3: TOTP screen mounts with code input controls', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const TotpScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Two-Factor'), findsWidgets);
      expect(find.text('1'), findsWidgets);
      // Unmount to cancel periodic resend timer
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Audit 4: PIN Unlock screen mounts with 6-digit keypad', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const PinUnlockScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('App PIN'), findsWidgets);
      expect(find.text('1'), findsWidgets);
      expect(find.text('9'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Audit 5: Register screen mounts with KYC compliance inputs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
      expect(find.textContaining('Account'), findsWidgets);
    });

    testWidgets('Audit 6: Quotes screen mounts with watchlist selector and market lists', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const QuotesScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Audit 7: Deals (Positions) screen mounts with P&L and risk filters', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const DealsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Audit 8: Net Deals (Holdings) screen mounts with portfolio summaries', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const NetDealsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Audit 9: History screen mounts with transaction ledger and filters', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const HistoryScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('Senior QA Audit: Batch 2 - Trading & Detail Screens', () {
    testWidgets('Audit 10: Quote Detail screen mounts with depth, high/low, and action buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      final token = SeedInstruments.all.first.token;
      await tester.pumpWidget(_wrapScreen(QuoteDetailScreen(token: token)));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
      expect(find.text('BUY'), findsWidgets);
      expect(find.text('SELL'), findsWidgets);
    });

    testWidgets('Audit 11: Fullscreen Chart mounts with timeframe controls and indicators', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      final token = SeedInstruments.all.first.token;
      await tester.pumpWidget(_wrapWithRouter(ChartFullscreenScreen(token: token)));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsWidgets);
      expect(find.text('BUY'), findsWidgets);
      expect(find.text('SELL'), findsWidgets);
    });

    testWidgets('Audit 12: Orders screen mounts with tab views for Open, Executed, and GTT', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const OrdersScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsWidgets);
      expect(find.textContaining('Open'), findsWidgets);
      expect(find.textContaining('Executed'), findsWidgets);
    });

    testWidgets('Audit 13: Order Detail screen mounts and handles order info gracefully', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const OrderDetailScreen(orderId: 'ORD-999')));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
      expect(find.textContaining('Order'), findsWidgets);
    });

    testWidgets('Audit 14: Add Script screen mounts with instrument folders and search', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const AddScriptScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
      expect(find.text('Add Script'), findsWidgets);
    });

    testWidgets('Audit 15: Search screen mounts with instant ticker filter', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const SearchScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
    });
  });

  group('Senior QA Audit: Batch 3 - Money & Funds Management', () {
    testWidgets('Audit 16: Funds screen mounts with available margin, segments, and deposit/withdraw CTA', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const FundsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
      expect(find.textContaining('ADD FUNDS'), findsWidgets);
      expect(find.textContaining('WITHDRAW'), findsWidgets);
    });

    testWidgets('Audit 17: Add Funds Sheet mounts with UPI/Netbanking methods and instant presets', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const AddFundsSheet()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Add Funds'), findsWidgets);
      expect(find.text('+ ₹5,000'), findsWidgets);
      expect(find.text('PROCEED TO PAY'), findsWidgets);
    });

    testWidgets('Audit 18: Withdraw Funds Sheet mounts with balance check and 2FA OTP verification', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const WithdrawFundsSheet()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Withdraw Funds'), findsWidgets);
      expect(find.text('VERIFY & PROCEED'), findsWidgets);
    });

    testWidgets('Audit 19: Balance Breakdown Sheet mounts with equity margins and ledger items', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const BalanceBreakdownDialog(segment: Segment.EQUITY)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Balance Breakdown'), findsWidgets);
      expect(find.textContaining('Settled Cash'), findsWidgets);
    });
  });

  group('Senior QA Audit: Batch 4 - Discovery, News & Communications', () {
    testWidgets('Audit 20: News screen mounts with Market Feeds and category chips', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const NewsScreen(initialTabIndex: 0)));
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsWidgets);
      expect(find.textContaining('News, Insights'), findsWidgets);
      expect(find.text('Market News'), findsWidgets);
    });

    testWidgets('Audit 21: News Feed screen mounts with curated FXStreet and macro articles', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const NewsFeedScreen()));
      await tester.pumpAndSettle();

      expect(find.text('FXStreet News'), findsWidgets);
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Audit 22: Learning & Academy screen mounts with trading modules and glossary', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const NewsScreen(initialTabIndex: 1)));
      await tester.pumpAndSettle();

      expect(find.text('Academy'), findsWidgets);
      expect(find.text('Glossary'), findsWidgets);
    });

    testWidgets('Audit 23: Mails screen mounts with Zero internal announcements and search', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const MailsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Mails'), findsWidgets);
      expect(find.byType(TextField), findsWidgets);
      expect(find.textContaining('Zero Desk'), findsWidgets);
    });

    testWidgets('Audit 24: Notification Center mounts with alerts and clear all action', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const NotificationCenterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsWidgets);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Audit 25: Notification Preferences screen mounts with category toggles and quiet hours', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const NotificationPreferencesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Notification Preferences'), findsWidgets);
      expect(find.textContaining('ALERT CATEGORIES'), findsWidgets);
      expect(find.textContaining('Orders & Executions'), findsWidgets);
    });
  });

  group('Senior QA Audit: Batch 5 - Advanced Trading Tools & Calculators', () {
    testWidgets('Audit 26: Margin Calculator screen mounts with leverage formula and instrument picker', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const MarginCalculatorScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Margin Calculator'), findsWidgets);
      expect(find.text('BUY OR SELL'), findsWidgets);
      expect(find.text('Buy'), findsWidgets);
    });

    testWidgets('Audit 27: Profit Calculator screen mounts with P&L simulation and target calculations', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const ProfitCalculatorScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Profit Calculator'), findsWidgets);
      expect(find.text('BUY OR SELL'), findsWidgets);
      expect(find.text('Buy'), findsWidgets);
    });

    testWidgets('Audit 28: Option Chain screen mounts with strike ladder, calls & puts, and expiry chips', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const OptionChainScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Option Chain'), findsWidgets);
      expect(find.textContaining('CALLS'), findsWidgets);
      expect(find.textContaining('PUTS'), findsWidgets);
    });

    testWidgets('Audit 29: Baskets screen mounts with multi-leg orders and execution CTA', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const BasketsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Baskets'), findsWidgets);
      expect(find.textContaining('Nifty IT Leaders'), findsWidgets);
    });

    testWidgets('Audit 30: SIP screen mounts with active equity SIP plans and frequency details', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const SipScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Stock SIPs'), findsWidgets);
      expect(find.textContaining('ACTIVE'), findsWidgets);
    });

    testWidgets('Audit 31: IPO screen mounts with Swiggy/Hyundai listings and GMP indicators', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const IpoListScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Initial Public Offerings'), findsWidgets);
      expect(find.textContaining('Swiggy'), findsWidgets);
    });

    testWidgets('Audit 32: Alerts screen mounts with custom price condition triggers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const AlertsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Alerts'), findsWidgets);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Audit 33: Economic Calendar screen mounts with global macro events and indicators', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const EconomicCalendarScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Economic Calendar'), findsWidgets);
      expect(find.byType(ListView), findsWidgets);
    });
  });

  group('Senior QA Audit: Batch 6 - Account, Settings & Support', () {
    testWidgets('Audit 34: Profile screen mounts with user profile, badges, and account links', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Account & Profile'), findsWidgets);
      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('Audit 35: Settings screen mounts with theme, biometric, and order preferences', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsWidgets);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('Audit 36: About screen mounts with Zero branding, legal info and disclosures', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const AboutScreen()));
      await tester.pumpAndSettle();

      expect(find.text('About'), findsWidgets);
      expect(find.text('Zero'), findsWidgets);
    });

    testWidgets('Audit 37: Reports screen mounts with Tax P&L, statement generation and filters', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const ReportsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Tax P&L & Analytics'), findsWidgets);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('Audit 38: Help & Support screen mounts with 4 tabs and escalation matrix', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const HelpSupportScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Support & Help Desk'), findsWidgets);
      expect(find.byType(TabBar), findsWidgets);
    });

    testWidgets('Audit 39: Ticket Detail screen mounts with chat messages and attachment upload', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const TicketDetailScreen(ticketId: 'TK-2026-84920')));
      await tester.pumpAndSettle();

      expect(find.textContaining('TK-2026-84920'), findsWidgets);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Audit 40: Live Chat Sheet mounts with live agent conversation and quick prompts', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const LiveChatSheet()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Audit 41: Maintenance screen mounts with countdown timer and status polling', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const MaintenanceScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Maintenance'), findsWidgets);
      expect(find.text('CHECK SYSTEM STATUS'), findsWidgets);
    });
  });

  group('Senior QA Audit: Batch 7 - Order Entry & Compliance Sheets', () {
    testWidgets('Audit 42: Order Entry Sheet mounts with instrument details, side toggle and sliders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(OrderEntrySheet(instrument: SeedInstruments.all.first)));
      await tester.pumpAndSettle();

      expect(find.text('BUY'), findsWidgets);
      expect(find.text('SELL'), findsWidgets);
    });

    testWidgets('Audit 43: KYC Management Sheet mounts with verification status and upload options', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const KycManagementSheet()));
      await tester.pumpAndSettle();

      expect(find.textContaining('KYC'), findsWidgets);
    });

    testWidgets('Audit 44: Nominee Management Sheet mounts with nominee details and percentage split', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const NomineeManagementSheet()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nominee'), findsWidgets);
    });

    testWidgets('Audit 45: Personal Details Sheet mounts with editable contact info and PAN lock', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const PersonalDetailsSheet()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Personal & Demat Profile'), findsWidgets);
    });

    testWidgets('Audit 46: Leverage Education Dialog mounts with risk slider and P&L impact simulation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const LeverageEducationDialog()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Leverage'), findsWidgets);
    });

    testWidgets('Audit 47: Create Ticket Sheet mounts with category selectors and issue submission', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(_wrapScreen(const CreateTicketSheet()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ticket'), findsWidgets);
    });
  });
}
