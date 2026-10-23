import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../data/notifications_repository.dart';

class MailItem {
  final String id;
  final String sender;
  final String subject;
  final String date;
  final String body;
  bool isRead;

  MailItem({
    required this.id,
    required this.sender,
    required this.subject,
    required this.date,
    required this.body,
    this.isRead = false,
  });
}

final userMailsProvider = FutureProvider.autoDispose<List<MailItem>>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  try {
    final notifs = await repo.getNotifications(limit: 50);
    if (notifs.isNotEmpty) {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return notifs.map((n) {
        String sender = 'Zero Life';
        if (n.category == NotificationCategory.orders) {
          sender = 'Exchange Execution';
        } else if (n.category == NotificationCategory.riskMargin) {
          sender = 'Risk Management';
        } else if (n.category == NotificationCategory.security) {
          sender = 'Security Desk';
        } else if (n.category == NotificationCategory.funds) {
          sender = 'Account Operations';
        }

        final dt = n.timestamp;
        final now = DateTime.now();
        String dateStr;
        if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
          final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
          final m = dt.minute.toString().padLeft(2, '0');
          final ampm = dt.hour >= 12 ? 'PM' : 'AM';
          dateStr = 'Today, $h:$m $ampm';
        } else {
          dateStr = '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
        }

        return MailItem(
          id: n.id,
          sender: sender,
          subject: n.title,
          date: dateStr,
          body: n.body,
          isRead: n.isRead,
        );
      }).toList();
    }
  } catch (_) {}

  return [
    MailItem(
      id: 'welcome_1',
      sender: 'Zero Desk',
      subject: 'Welcome to Zero Life! Your trading account is active',
      date: 'Today, 10:15 AM',
      body:
          'Welcome to Zero Life Trading Platform!\n\nYour account has been fully verified and activated with MCX and Equity trading segments enabled. Zero brokerage is applied across all equity delivery and currency transactions.\n\nHappy Trading,\nZero Support Team',
      isRead: false,
    ),
    MailItem(
      id: 'welcome_2',
      sender: 'Deposit Department',
      subject: 'Special Offer: 50% Deposit Bonus on your first funding',
      date: 'Yesterday, 04:30 PM',
      body:
          'Exclusive Trader Promotion!\n\nFund your account with ₹10,000 or more via instant UPI / Netbanking and receive a 50% extra margin credit instantly to boost your trading capacity.\n\nTerms & conditions apply.',
      isRead: true,
    ),
  ];
});

class MailsScreen extends ConsumerStatefulWidget {
  const MailsScreen({super.key});

  @override
  ConsumerState<MailsScreen> createState() => _MailsScreenState();
}

class _MailsScreenState extends ConsumerState<MailsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMailDetail(MailItem mail, TradingColors colors) {
    if (!mail.isRead) {
      setState(() => mail.isRead = true);
      ref.read(notificationsRepositoryProvider).markRead(mail.id).catchError((_) {});
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      mail.sender,
                      style: GoogleFonts.inter(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ),
                  Text(
                    mail.date,
                    style: GoogleFonts.inter(
                        color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                mail.subject,
                style: GoogleFonts.inter(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: colors.divider),
              const SizedBox(height: 14),
              Text(
                mail.body,
                style: GoogleFonts.inter(
                    color: colors.textPrimary,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final mailsAsync = ref.watch(userMailsProvider);
    final allMails = mailsAsync.valueOrNull ?? const <MailItem>[];
    final query = _searchController.text.trim().toLowerCase();

    var filteredMails = allMails;
    if (query.isNotEmpty) {
      filteredMails = allMails
          .where((m) =>
              m.sender.toLowerCase().contains(query) ||
              m.subject.toLowerCase().contains(query) ||
              m.body.toLowerCase().contains(query))
          .toList();
    }

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/mails'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AdaptiveLeadingButton(),
        centerTitle: true,
        title: Text('Mails',
            style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.checkCheck, color: colors.textSecondary, size: 20),
            tooltip: 'Mark all as read',
            onPressed: () async {
              try {
                await ref.read(notificationsRepositoryProvider).markAllRead();
                ref.invalidate(userMailsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('All mails marked as read'),
                      backgroundColor: colors.cardBackground,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (_) {}
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Combined Market Header Strip
          const ZeroMarketHeaderStrip(),

          // Search Bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: colors.divider.withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                style: AppTypography.body(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by Sender or Subject',
                  hintStyle: AppTypography.body(color: colors.textSecondary),
                  prefixIcon:
                      Icon(LucideIcons.search, color: colors.textSecondary, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(LucideIcons.x,
                              color: colors.textSecondary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          // Mails List
          Expanded(
            child: mailsAsync.isLoading && allMails.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colors.primary,
                    ),
                  )
                : RefreshIndicator(
                    color: colors.primary,
                    backgroundColor: colors.cardBackground,
                    onRefresh: () async {
                      ref.invalidate(userMailsProvider);
                      await ref.read(userMailsProvider.future);
                    },
                    child: filteredMails.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.45,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(LucideIcons.mailCheck,
                                          size: 42,
                                          color: colors.textSecondary.withValues(alpha: 0.5)),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No Mails Found',
                                        style: GoogleFonts.inter(
                                            color: colors.textSecondary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: filteredMails.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: colors.divider),
                            itemBuilder: (context, index) {
                              final item = filteredMails[index];

                              return Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  onTap: () => _showMailDetail(item, colors),
                                  leading: CircleAvatar(
                                    backgroundColor: item.isRead
                                        ? colors.divider.withValues(alpha: 0.5)
                                        : colors.primary.withValues(alpha: 0.15),
                                    child: Icon(
                                      item.isRead
                                          ? LucideIcons.mailOpen
                                          : LucideIcons.mail,
                                      color: item.isRead
                                          ? colors.textSecondary
                                          : colors.primary,
                                      size: 18,
                                    ),
                                  ),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.sender,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontWeight: item.isRead
                                                ? FontWeight.w600
                                                : FontWeight.w800,
                                            color: colors.textPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(item.date,
                                          style: GoogleFonts.inter(
                                              color: colors.textSecondary,
                                              fontSize: 11.5)),
                                    ],
                                  ),
                                  subtitle: Text(
                                    item.subject,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                        color: item.isRead
                                            ? colors.textSecondary
                                            : colors.textPrimary,
                                        fontWeight: item.isRead
                                            ? FontWeight.w400
                                            : FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                  trailing: Icon(LucideIcons.chevronRight,
                                      color: colors.textSecondary, size: 18),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
