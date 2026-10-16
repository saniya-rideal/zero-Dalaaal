import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../data/support_repository.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/shared_widgets.dart';
import '../../../shared_widgets/zero_drawer.dart';
import 'create_ticket_sheet.dart';
import 'live_chat_sheet.dart';
import 'ticket_detail_screen.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _faqSearchController = TextEditingController();
  String _selectedFaqCategory = 'All';
  TicketStatus? _selectedTicketFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _faqSearchController.dispose();
    super.dispose();
  }

  void _makePhoneCall(String phoneNumber) {
    _copyToClipboard(phoneNumber, 'Helpline $phoneNumber copied to clipboard.');
  }

  void _sendEmail(String email) {
    _copyToClipboard(email, 'Support email $email copied to clipboard.');
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Color _getStatusColor(TicketStatus s, TradingColors colors) {
    switch (s) {
      case TicketStatus.open:
        return colors.primary;
      case TicketStatus.inProgress:
        return colors.warning;
      case TicketStatus.awaitingClient:
        return Colors.purpleAccent;
      case TicketStatus.resolved:
        return colors.bullish;
      case TicketStatus.closed:
        return colors.neutral;
    }
  }

  Color _getPriorityColor(TicketPriority p, TradingColors colors) {
    switch (p) {
      case TicketPriority.low:
        return colors.neutral;
      case TicketPriority.medium:
        return colors.primary;
      case TicketPriority.high:
        return colors.warning;
      case TicketPriority.critical:
        return colors.bearish;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final repo = ref.watch(supportRepositoryProvider);

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/help'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        leading: const AdaptiveLeadingButton(),
        title: Text(
          'Support & Help Desk',
          style: AppTypography.h1(color: colors.textPrimary, weight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.headset),
            tooltip: 'Live Chat',
            onPressed: () => LiveChatSheet.show(context),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          indicatorWeight: 3,
          labelStyle: AppTypography.caption(weight: FontWeight.w700),
          unselectedLabelStyle: AppTypography.caption(weight: FontWeight.w500),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Help Center & FAQs'),
            Tab(text: 'My Tickets'),
            Tab(text: 'Escalation Matrix'),
            Tab(text: 'Corporate Contacts'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 24×7 Status Banner
          _buildHeroSupportBanner(colors),

          // Quick Action Channels
          _buildQuickActionChannels(colors),

          const Divider(height: 1),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFaqTabView(colors, repo),
                _buildTicketsTabView(colors, repo),
                _buildEscalationTabView(colors, repo),
                _buildCorporateContactTabView(colors, repo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSupportBanner(TradingColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: colors.bullish, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  '24×7 Support Desk Online',
                  style: AppTypography.caption(color: colors.textPrimary, weight: FontWeight.w700),
                ),
                const SizedBox(width: 6),
                Text(
                  '• Wait < 1m',
                  style: AppTypography.caption(color: colors.bullish, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Toll-Free: 1800-ZERO-DESK',
              style: AppTypography.labelSmall(color: colors.primary, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChannels(TradingColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colors.cardBackground,
      child: Row(
        children: [
          Expanded(
            child: _buildChannelButton(
              icon: LucideIcons.messageSquare,
              label: 'Live Chat',
              color: colors.primary,
              onTap: () => LiveChatSheet.show(context),
              colors: colors,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildChannelButton(
              icon: LucideIcons.phoneCall,
              label: 'Call 24/7',
              color: colors.bullish,
              onTap: () => _makePhoneCall('180093763375'),
              colors: colors,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildChannelButton(
              icon: LucideIcons.mail,
              label: 'Email Us',
              color: colors.warning,
              onTap: () => _sendEmail('support@zerodalali.com'),
              colors: colors,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildChannelButton(
              icon: LucideIcons.ticket,
              label: 'New Ticket',
              color: Colors.purpleAccent,
              onTap: () async {
                final ticket = await CreateTicketSheet.show(context);
                if (ticket != null) {
                  setState(() {
                    _tabController.animateTo(1); // Switch to My Tickets
                  });
                }
              },
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required TradingColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              radius: 16,
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall(color: colors.textPrimary, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 1: Help Center & FAQs ────────────────────────────────────────────

  Widget _buildFaqTabView(TradingColors colors, SupportRepository repo) {
    final filteredFaqs = repo.getFaqs(
      query: _faqSearchController.text,
      category: _selectedFaqCategory,
    );

    final categories = [
      'All',
      'Trading & Orders',
      'Funds & Payments',
      'Margin & Leverage',
      'F&O & Derivatives',
      'Account & KYC',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Search Bar
        TextField(
          controller: _faqSearchController,
          onChanged: (_) => setState(() {}),
          style: AppTypography.body(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search FAQs, orders, margin rules, UPI...',
            hintStyle: AppTypography.body(color: colors.textSecondary),
            prefixIcon: Icon(LucideIcons.search, color: colors.textSecondary),
            suffixIcon: _faqSearchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(LucideIcons.x, color: colors.textSecondary),
                    onPressed: () {
                      _faqSearchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.divider)),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),

        const SizedBox(height: 12),

        // Category Filter Chips
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: categories.map((cat) {
              final isSelected = _selectedFaqCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    cat,
                    style: AppTypography.labelSmall(
                      color: isSelected ? Colors.white : colors.textSecondary,
                      weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: colors.primary,
                  backgroundColor: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: isSelected ? colors.primary : colors.divider),
                  ),
                  onSelected: (_) => setState(() => _selectedFaqCategory = cat),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // FAQs List
        if (filteredFaqs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No questions found matching "${_faqSearchController.text}".',
                style: AppTypography.body(color: colors.textSecondary),
              ),
            ),
          )
        else
          ...filteredFaqs.map((faq) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.divider),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                title: Text(
                  faq.question,
                  style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w700),
                ),
                subtitle: Text(
                  faq.category,
                  style: AppTypography.caption(color: colors.primary, weight: FontWeight.w600),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Text(
                          faq.answer,
                          style: AppTypography.body(color: colors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Wrap(
                              spacing: 6,
                              children: faq.tags.map((t) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: colors.divider),
                                  ),
                                  child: Text('#$t', style: AppTypography.labelSmall(color: colors.textSecondary)),
                                );
                              }).toList(),
                            ),
                            InkWell(
                              onTap: () {
                                repo.incrementHelpful(faq.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Thank you for your feedback!'), duration: Duration(seconds: 1)),
                                );
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.thumbsUp, size: 14, color: colors.primary),
                                    const SizedBox(width: 4),
                                    Text('Helpful (${faq.helpfulCount})', style: AppTypography.labelSmall(color: colors.primary, weight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
      ],
    );
  }

  // ─── TAB 2: My Tickets ───────────────────────────────────────────────────

  Widget _buildTicketsTabView(TradingColors colors, SupportRepository repo) {
    var list = repo.tickets;
    if (_selectedTicketFilter != null) {
      list = list.where((t) => t.status == _selectedTicketFilter).toList();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status Filter Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Wrap(
              spacing: 6,
              children: [
                _buildTicketFilterChip('All', _selectedTicketFilter == null, () => setState(() => _selectedTicketFilter = null), colors),
                _buildTicketFilterChip('Open', _selectedTicketFilter == TicketStatus.open, () => setState(() => _selectedTicketFilter = TicketStatus.open), colors),
                _buildTicketFilterChip('In Progress', _selectedTicketFilter == TicketStatus.inProgress, () => setState(() => _selectedTicketFilter = TicketStatus.inProgress), colors),
                _buildTicketFilterChip('Resolved', _selectedTicketFilter == TicketStatus.resolved, () => setState(() => _selectedTicketFilter = TicketStatus.resolved), colors),
              ],
            ),
            IconButton(
              icon: Icon(LucideIcons.plusCircle, color: colors.primary),
              tooltip: 'New Ticket',
              onPressed: () => CreateTicketSheet.show(context),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (list.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(LucideIcons.inbox, size: 48, color: colors.textSecondary),
                  const SizedBox(height: 12),
                  Text('No tickets found', style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Need help? Raise a support ticket directly to our desk.', style: AppTypography.caption(color: colors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('RAISE A TICKET'),
                    style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white),
                    onPressed: () => CreateTicketSheet.show(context),
                  ),
                ],
              ),
            ),
          )
        else
          ...list.map((t) {
            final statusColor = _getStatusColor(t.status, colors);
            final priorityColor = _getPriorityColor(t.priority, colors);

            return InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => TicketDetailScreen(ticketId: t.id)),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#${t.id}',
                          style: AppTypography.caption(color: colors.primary, weight: FontWeight.w700),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                t.priority.label,
                                style: AppTypography.labelSmall(color: priorityColor, weight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                t.status.label.toUpperCase(),
                                style: AppTypography.labelSmall(color: statusColor, weight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.title,
                      style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${t.messages.length} messages • ${t.assignedAgent}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall(color: colors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Text(t.timeAgo, style: AppTypography.caption(color: colors.textSecondary)),
                            const SizedBox(width: 4),
                            Icon(LucideIcons.chevronRight, size: 16, color: colors.textSecondary),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTicketFilterChip(String label, bool isSelected, VoidCallback onTap, TradingColors colors) {
    return ChoiceChip(
      label: Text(
        label,
        style: AppTypography.labelSmall(
          color: isSelected ? Colors.white : colors.textSecondary,
          weight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedColor: colors.primary,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? colors.primary : colors.divider),
      ),
      onSelected: (_) => onTap(),
    );
  }

  // ─── TAB 3: SEBI Escalation Matrix ────────────────────────────────────────

  Widget _buildEscalationTabView(TradingColors colors, SupportRepository repo) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.scale, color: colors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SEBI Grievance Redressal Mechanism', style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('In accordance with SEBI Master Circulars, investors have a right to escalate unresolved grievances sequentially.', style: AppTypography.caption(color: colors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        ...repo.escalationTiers.map((tier) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tier.title,
                      style: AppTypography.body(color: colors.primary, weight: FontWeight.w800),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: colors.divider),
                      ),
                      child: Text(
                        'TAT: ${tier.tat}',
                        style: AppTypography.labelSmall(color: colors.bullish, weight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${tier.officerName} — ${tier.designation}',
                  style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  tier.description,
                  style: AppTypography.caption(color: colors.textSecondary),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _sendEmail(tier.email),
                      child: Row(
                        children: [
                          Icon(LucideIcons.mail, size: 14, color: colors.primary),
                          const SizedBox(width: 4),
                          Text(tier.email, style: AppTypography.caption(color: colors.primary, weight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _makePhoneCall(tier.phone.split(' ')[0]),
                      child: Row(
                        children: [
                          Icon(LucideIcons.phone, size: 14, color: colors.textSecondary),
                          const SizedBox(width: 4),
                          Text(tier.phone, style: AppTypography.caption(color: colors.textSecondary, weight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── TAB 4: Corporate Contacts ────────────────────────────────────────────

  Widget _buildCorporateContactTabView(TradingColors colors, SupportRepository repo) {
    final contact = repo.corporateContact;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact.companyName,
                style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                contact.hours,
                style: AppTypography.caption(color: colors.bullish, weight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _buildContactRow(LucideIcons.mapPin, 'Corporate Office', contact.corporateOffice, colors),
              const SizedBox(height: 12),
              _buildContactRow(LucideIcons.badgeCheck, 'SEBI Reg. Number', contact.sebiRegNumber, colors),
              const SizedBox(height: 12),
              _buildContactRow(LucideIcons.landmark, 'Exchange Memberships', 'NSE: ${contact.nseMemberId} | BSE: ${contact.bseMemberId}', colors),
              const SizedBox(height: 12),
              _buildContactRow(LucideIcons.phoneCall, 'Help Desk', contact.tollFreePhone, colors, isPhone: true),
              const SizedBox(height: 12),
              _buildContactRow(LucideIcons.mail, 'Customer Support', contact.supportEmail, colors, isEmail: true),
              const SizedBox(height: 12),
              _buildContactRow(LucideIcons.shield, 'Compliance Desk', contact.complianceEmail, colors, isEmail: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value, TradingColors colors, {bool isPhone = false, bool isEmail = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.labelSmall(color: colors.textSecondary, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              if (isPhone)
                InkWell(
                  onTap: () => _makePhoneCall('180093763375'),
                  child: Text(value, style: AppTypography.body(color: colors.primary, weight: FontWeight.w700)),
                )
              else if (isEmail)
                InkWell(
                  onTap: () => _sendEmail(value),
                  child: Text(value, style: AppTypography.body(color: colors.primary, weight: FontWeight.w600)),
                )
              else
                Text(value, style: AppTypography.body(color: colors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
