import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/alerts/presentation/alerts_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/pin_unlock_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/totp_screen.dart';
import '../features/baskets/presentation/baskets_screen.dart';
import '../features/calendar/presentation/economic_calendar_screen.dart';
import '../features/calculator/presentation/margin_calculator_screen.dart';
import '../features/calculator/presentation/profit_calculator_screen.dart';
import '../features/charts/presentation/chart_fullscreen_screen.dart';
import '../features/deals/presentation/deals_screen.dart';
import '../features/funds/presentation/funds_screen.dart';
import '../features/heatmap/presentation/sector_heatmap_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/ipo/presentation/ipo_list_screen.dart';
import '../features/net_deals/presentation/net_deals_screen.dart';
import '../features/news/presentation/news_screen.dart';
import '../features/news/presentation/news_feed_screen.dart';
import '../features/notifications/presentation/mails_screen.dart';
import '../features/notifications/presentation/notification_center_screen.dart';
import '../features/notifications/presentation/notification_preferences_sheet.dart';
import '../features/option_chain/presentation/option_chain_screen.dart';
import '../features/orders/presentation/order_detail_screen.dart';
import '../features/orders/presentation/orders_screen.dart';
import '../features/portfolio/presentation/portfolio_screen.dart';
import '../features/profile_settings/presentation/about_screen.dart';
import '../features/profile_settings/presentation/help_support_screen.dart';
import '../features/profile_settings/presentation/live_chat_sheet.dart';
import '../features/profile_settings/presentation/maintenance_screen.dart';
import '../features/profile_settings/presentation/profile_screen.dart';
import '../features/profile_settings/presentation/reports_screen.dart';
import '../features/profile_settings/presentation/settings_screen.dart';
import '../features/profile_settings/presentation/ticket_detail_screen.dart';
import '../features/quote_detail/presentation/quote_detail_screen.dart';
import '../features/quotes/presentation/add_script_screen.dart';
import '../features/quotes/presentation/quotes_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/sip/presentation/sip_screen.dart';
import '../features/watchlist/presentation/watchlist_screen.dart';
import '../shared_widgets/zero_shell_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      // Auth Routes
      GoRoute(
          path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/totp', builder: (context, state) => const TotpScreen()),
      GoRoute(
          path: '/pin-unlock',
          builder: (context, state) => const PinUnlockScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),

      // Zero 4-Tab Navigation Shell + Center FAB + Persistent Margin Dock
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ZeroShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Quotes
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quotes',
                builder: (context, state) => const QuotesScreen(),
              ),
            ],
          ),
          // Branch 1: Deals
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/deals',
                builder: (context, state) => const DealsScreen(),
              ),
            ],
          ),
          // Branch 2: Net Deals
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/net-deals',
                builder: (context, state) => const NetDealsScreen(),
              ),
            ],
          ),
          // Branch 3: History
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
        ],
      ),

      // Detail & Sub-feature Modal Routes
      GoRoute(
        path: '/quote/:token',
        builder: (context, state) {
          final token = state.pathParameters['token']!;
          return QuoteDetailScreen(token: token);
        },
      ),
      GoRoute(
        path: '/quote-detail/:token',
        builder: (context, state) {
          final token = state.pathParameters['token']!;
          return QuoteDetailScreen(token: token);
        },
      ),
      GoRoute(
        path: '/chart-fullscreen/:token',
        builder: (context, state) {
          final token = state.pathParameters['token']!;
          return ChartFullscreenScreen(token: token);
        },
      ),
      GoRoute(
        path: '/order-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderDetailScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
          path: '/add-script',
          builder: (context, state) => const AddScriptScreen()),
      GoRoute(
          path: '/search', builder: (context, state) => const SearchScreen()),
      GoRoute(path: '/funds', builder: (context, state) => const FundsScreen()),
      GoRoute(
          path: '/portfolio',
          builder: (context, state) => const PortfolioScreen()),
      GoRoute(
          path: '/watchlist',
          builder: (context, state) => const WatchlistScreen()),
      GoRoute(
          path: '/baskets', builder: (context, state) => const BasketsScreen()),
      GoRoute(path: '/sip', builder: (context, state) => const SipScreen()),
      GoRoute(path: '/ipo', builder: (context, state) => const IpoListScreen()),
      GoRoute(
          path: '/alerts', builder: (context, state) => const AlertsScreen()),
      GoRoute(
          path: '/economic-calendar',
          builder: (context, state) => const EconomicCalendarScreen()),
      GoRoute(
          path: '/heatmap',
          builder: (context, state) => const SectorHeatmapScreen()),
      GoRoute(path: '/news', builder: (context, state) => const NewsScreen()),
      GoRoute(
          path: '/learning',
          builder: (context, state) => const NewsScreen()),
      GoRoute(
          path: '/news-feed',
          builder: (context, state) => const NewsFeedScreen()),
      GoRoute(path: '/mails', builder: (context, state) => const MailsScreen()),
      GoRoute(
          path: '/profit-calculator',
          builder: (context, state) => const ProfitCalculatorScreen()),
      GoRoute(
          path: '/margin-calculator',
          builder: (context, state) => const MarginCalculatorScreen()),
      GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationCenterScreen()),
      GoRoute(
          path: '/notification-preferences',
          builder: (context, state) => const NotificationPreferencesScreen()),
      GoRoute(
        path: '/option-chain',
        builder: (context, state) {
          final symbol = state.uri.queryParameters['symbol'] ?? 'NIFTY 50';
          return OptionChainScreen(underlying: symbol);
        },
      ),
      GoRoute(
          path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(
          path: '/reports', builder: (context, state) => const ReportsScreen()),
      GoRoute(
          path: '/help',
          builder: (context, state) => const HelpSupportScreen()),
      GoRoute(
        path: '/help/tickets/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TicketDetailScreen(ticketId: id);
        },
      ),
      GoRoute(
        path: '/live-chat',
        builder: (context, state) => const Scaffold(
          body: SafeArea(child: LiveChatSheet()),
        ),
      ),
      GoRoute(
          path: '/maintenance',
          builder: (context, state) => const MaintenanceScreen()),
    ],
  );
});
