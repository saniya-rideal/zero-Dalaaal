import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import '../models/models.dart';

class SupportRepository extends ChangeNotifier {
  final Ref? _ref;
  final List<SupportTicket> _tickets = [];
  final List<FaqItem> _faqs = [];
  final List<EscalationTier> _escalationTiers = [];
  late final CorporateContact _corporateContact;

  final List<TicketMessage> _liveChatMessages = [];
  final StreamController<List<SupportTicket>> _ticketsStreamController =
      StreamController<List<SupportTicket>>.broadcast();
  final StreamController<List<TicketMessage>> _liveChatStreamController =
      StreamController<List<TicketMessage>>.broadcast();

  Stream<List<SupportTicket>> get ticketsStream => _ticketsStreamController.stream;
  Stream<List<TicketMessage>> get liveChatStream => _liveChatStreamController.stream;

  SupportRepository([this._ref]) {
    _seedData();
  }

  List<SupportTicket> get tickets => List.unmodifiable(_tickets);
  List<FaqItem> get faqs => List.unmodifiable(_faqs);
  List<EscalationTier> get escalationTiers => List.unmodifiable(_escalationTiers);
  CorporateContact get corporateContact => _corporateContact;
  List<TicketMessage> get liveChatMessages => List.unmodifiable(_liveChatMessages);

  void _seedData() {
    final now = DateTime.now();

    // ─── 1. Seed Support Tickets ──────────────────────────────────────────────
    _tickets.addAll([
      SupportTicket(
        id: 'TK-2026-84920',
        title: 'UPI Deposit Pending: ₹50,000 Ref: UPI/2026/89412',
        description: 'Transferred ₹50,000 via Google Pay UPI at 10:30 AM. Bank account was debited with UTR 4291884192, but equity trading margin is not yet reflected.',
        category: TicketCategory.fundsPayments,
        priority: TicketPriority.high,
        status: TicketStatus.inProgress,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
        updatedAt: now.subtract(const Duration(minutes: 15)),
        assignedAgent: 'Rajesh Kumar (Banking Desk)',
        attachments: [
          TicketAttachment(
            id: 'att_01',
            fileName: 'gpay_upi_receipt.png',
            fileSizeBytes: 245000,
            fileType: 'image',
            uploadedAt: now.subtract(const Duration(hours: 1, minutes: 20)),
          ),
        ],
        messages: [
          TicketMessage(
            id: 'msg_01',
            senderName: 'Client (Anurag)',
            senderRole: MessageSenderRole.client,
            content: 'Attached GPay confirmation slip with UTR 4291884192. Please credit to margin as market is active.',
            timestamp: now.subtract(const Duration(hours: 1, minutes: 20)),
          ),
          TicketMessage(
            id: 'msg_02',
            senderName: 'Zero RMS Bot',
            senderRole: MessageSenderRole.system,
            content: 'Ticket #TK-2026-84920 generated. Assigned to Priority Banking & Reconciliation Desk.',
            timestamp: now.subtract(const Duration(hours: 1, minutes: 19)),
          ),
          TicketMessage(
            id: 'msg_03',
            senderName: 'Rajesh Kumar (Banking Desk)',
            senderRole: MessageSenderRole.supportAgent,
            content: 'Hello Anurag, we have verified UTR 4291884192 with our NPCI clearing gateway. The bank has acknowledged the payment and our automated reconciliation will credit your equity ledger within 15 minutes.',
            timestamp: now.subtract(const Duration(minutes: 15)),
          ),
        ],
      ),
      SupportTicket(
        id: 'TK-2026-78104',
        title: 'Activation of MCX Commodity Trading Segment',
        description: 'Uploaded 6-month bank account statement as financial proof to enable MCX futures and bullion contracts.',
        category: TicketCategory.accountKyc,
        priority: TicketPriority.medium,
        status: TicketStatus.resolved,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
        assignedAgent: 'Priya Sharma (KYC Desk)',
        attachments: [
          TicketAttachment(
            id: 'att_02',
            fileName: 'bank_statement_6m.pdf',
            fileSizeBytes: 1420000,
            fileType: 'pdf',
            uploadedAt: now.subtract(const Duration(days: 2)),
          ),
        ],
        messages: [
          TicketMessage(
            id: 'msg_10',
            senderName: 'Client (Anurag)',
            senderRole: MessageSenderRole.client,
            content: 'Attached 6-month HDFC statement with salary credits. Requesting activation of MCX segment.',
            timestamp: now.subtract(const Duration(days: 2)),
          ),
          TicketMessage(
            id: 'msg_11',
            senderName: 'Priya Sharma (KYC Desk)',
            senderRole: MessageSenderRole.supportAgent,
            content: 'Your financial statement meets SEBI derivative net-worth criteria. MCX Commodity segment has been activated. You can now trade Gold, Silver, Copper, and Crude Oil.',
            timestamp: now.subtract(const Duration(days: 1, hours: 2)),
          ),
          TicketMessage(
            id: 'msg_12',
            senderName: 'Zero Desk',
            senderRole: MessageSenderRole.system,
            content: 'Ticket marked as RESOLVED by compliance team.',
            timestamp: now.subtract(const Duration(days: 1)),
          ),
        ],
      ),
      SupportTicket(
        id: 'TK-2026-61902',
        title: 'Query regarding Intraday MIS Peak Margin Multiplier',
        description: 'Seeking clarity on whether 5x leverage is available for Nifty Options buying or only equities.',
        category: TicketCategory.marginRisk,
        priority: TicketPriority.low,
        status: TicketStatus.closed,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 4)),
        assignedAgent: 'Vikramaditya Sharma',
        messages: [
          TicketMessage(
            id: 'msg_20',
            senderName: 'Client (Anurag)',
            senderRole: MessageSenderRole.client,
            content: 'Is 5x leverage applied when buying Nifty Call Options?',
            timestamp: now.subtract(const Duration(days: 5)),
          ),
          TicketMessage(
            id: 'msg_21',
            senderName: 'Vikramaditya Sharma',
            senderRole: MessageSenderRole.supportAgent,
            content: 'As per SEBI peak margin circulars, Options Buying requires 100% premium upfront with zero leverage. 5x leverage is only applicable on Equity Intraday (MIS) stocks.',
            timestamp: now.subtract(const Duration(days: 4)),
          ),
        ],
      ),
    ]);

    // ─── 2. Seed FAQs ────────────────────────────────────────────────────────
    _faqs.addAll([
      // Trading & Orders
      FaqItem(
        id: 'faq_01',
        category: 'Trading & Orders',
        question: 'What is Zero\'s equity brokerage policy?',
        answer: 'Zero charges ₹0 (absolutely ZERO) brokerage on all Equity Delivery (CNC) investments. For Intraday (MIS) and F&O trades, flat ₹20 or 0.03% (whichever is lower) is charged per executed order.',
        tags: ['brokerage', 'charges', 'delivery', 'intraday', 'equity'],
        helpfulCount: 342,
      ),
      FaqItem(
        id: 'faq_02',
        category: 'Trading & Orders',
        question: 'How does a GTT (Good Till Triggered) order work?',
        answer: 'A GTT order remains active in the exchange system for 1 full year until your specified trigger price is touched. Once triggered, the limit order is automatically dispatched to the exchange order book.',
        tags: ['gtt', 'trigger', 'stoploss', 'orders'],
        helpfulCount: 289,
      ),
      FaqItem(
        id: 'faq_03',
        category: 'Trading & Orders',
        question: 'What are Indian stock market trading hours?',
        answer: 'Normal market session runs from 09:15 AM to 03:30 PM IST on weekdays (Monday through Friday). Pre-market session takes place from 09:00 AM to 09:08 AM. MCX Commodity trades from 09:00 AM to 11:30 PM (or 11:55 PM US DST).',
        tags: ['hours', 'timings', 'premarket', 'mcx', 'sessions'],
        helpfulCount: 412,
      ),
      FaqItem(
        id: 'faq_04',
        category: 'Trading & Orders',
        question: 'What is the difference between CNC and MIS product types?',
        answer: 'CNC (Cash and Carry) is for delivery holding where shares are credited to your Demat account (100% margin required). MIS (Margin Intraday Square-off) provides 5x leverage but must be closed before 03:20 PM IST on the same day.',
        tags: ['cnc', 'mis', 'intraday', 'delivery', 'products'],
        helpfulCount: 378,
      ),
      FaqItem(
        id: 'faq_05',
        category: 'Trading & Orders',
        question: 'What is an After Market Order (AMO)?',
        answer: 'AMO allows you to place orders outside market hours (between 03:45 PM and 08:57 AM next trading day). The system automatically routes AMO orders to the exchange upon market opening at 09:00 AM.',
        tags: ['amo', 'offline', 'night', 'orders'],
        helpfulCount: 195,
      ),

      // Funds & Payments
      FaqItem(
        id: 'faq_06',
        category: 'Funds & Payments',
        question: 'How do I add funds instantly via UPI?',
        answer: 'Go to Funds -> Add Funds, enter your desired amount, select UPI, and approve the payment request on your UPI app (Google Pay, PhonePe, Paytm, or BHIM). Funds reflect instantly in your trading margin with ₹0 transfer charges.',
        tags: ['upi', 'deposit', 'instant', 'payment', 'funds'],
        helpfulCount: 520,
      ),
      FaqItem(
        id: 'faq_07',
        category: 'Funds & Payments',
        question: 'Why is my deposit status showing "Pending"?',
        answer: 'Deposits may show Pending during interbank network reconciliation. UPI transactions usually resolve within 15 minutes. If money was debited from your bank but does not reflect, our system reconciles UTRs automatically within 2 hours or reverses it back to your bank.',
        tags: ['pending', 'failed', 'utr', 'delay', 'reconciliation'],
        helpfulCount: 264,
      ),
      FaqItem(
        id: 'faq_08',
        category: 'Funds & Payments',
        question: 'What is the withdrawal payout schedule?',
        answer: 'Withdrawal requests submitted before 08:00 PM on trading days are processed the same night and credited to your primary verified bank account by 10:00 AM next morning via NEFT/RTGS.',
        tags: ['withdrawal', 'payout', 'bank', 'schedule', 'settlement'],
        helpfulCount: 310,
      ),
      FaqItem(
        id: 'faq_09',
        category: 'Funds & Payments',
        question: 'Can I transfer funds from a friend\'s or relative\'s bank account?',
        answer: 'No. Strictly as per SEBI anti-money laundering (PMLA) regulations, third-party transfers are strictly prohibited. Funds must originate only from your registered and verified linked bank accounts.',
        tags: ['thirdparty', 'sebi', 'pmla', 'bank', 'verification'],
        helpfulCount: 290,
      ),

      // Margin & Leverage
      FaqItem(
        id: 'faq_10',
        category: 'Margin & Leverage',
        question: 'What triggers a Margin Call warning?',
        answer: 'A Margin Call warning is triggered when your margin utilization exceeds 90% or your Margin Level drops below 110%. You will receive a high-priority push notification and banner advisory to deposit funds or reduce position size.',
        tags: ['margincall', 'utilization', 'warning', 'buffer'],
        helpfulCount: 184,
      ),
      FaqItem(
        id: 'faq_11',
        category: 'Margin & Leverage',
        question: 'How does RMS Auto-Liquidation work?',
        answer: 'If your account Margin Level falls below 100% or your available balance enters a deficit, the automated Risk Management System (RMS) steps in and auto-squares off open positions (prioritizing worst unrealized loss positions) to prevent debt.',
        tags: ['liquidation', 'rms', 'deficit', 'autosquareoff'],
        helpfulCount: 225,
      ),

      // F&O & Derivatives
      FaqItem(
        id: 'faq_12',
        category: 'F&O & Derivatives',
        question: 'What is the statutory SEBI risk advisory on Futures & Options?',
        answer: 'SEBI study reveals that 9 out of 10 individual traders in the equity F&O segment incurred net losses, with an average loss of ₹50,000 per trader. Over and above losses, traders incur substantial transaction and clearing costs.',
        tags: ['fno', 'derivatives', 'sebi', 'risk', 'warning'],
        helpfulCount: 450,
      ),
      FaqItem(
        id: 'faq_13',
        category: 'F&O & Derivatives',
        question: 'What is Option Greeks and where can I view them?',
        answer: 'Option Greeks (Delta, Gamma, Theta, Vega) quantify how an option premium changes with price, time decay, and volatility. You can view real-time Greeks for all strikes on the Zero Option Chain screen.',
        tags: ['greeks', 'delta', 'theta', 'optionchain', 'volatility'],
        helpfulCount: 198,
      ),

      // Account & KYC
      FaqItem(
        id: 'faq_14',
        category: 'Account & KYC',
        question: 'How do I add or update Nominees in my Demat account?',
        answer: 'Go to Profile -> Nominee Management. You can register up to 3 nominees with percentage allocations summing exactly to 100%, upload relationship proof, and submit for verification.',
        tags: ['nominee', 'demat', 'allocation', 'inheritance'],
        helpfulCount: 275,
      ),
      FaqItem(
        id: 'faq_15',
        category: 'Account & KYC',
        question: 'Where can I download my Client Master Report (CMR)?',
        answer: 'Your Client Master Report containing 16-digit Demat Account Number, DP ID, and depository registration details can be generated from Profile -> Reports -> Demat Holding Statement / CMR.',
        tags: ['cmr', 'demat', 'dpid', 'statement'],
        helpfulCount: 188,
      ),
    ]);

    // ─── 3. Seed SEBI 4-Tier Escalation Matrix ─────────────────────────────────
    _escalationTiers.addAll([
      const EscalationTier(
        level: 1,
        title: 'Level 1: Customer Support Desk',
        officerName: 'Zero Care Representative',
        designation: 'Frontline Support & Order Helpdesk',
        email: 'support@zerodalali.com',
        phone: '1800-ZERO-DESK (1800-9376-3375)',
        tat: 'Within 2 Hours (24×7)',
        description: 'First point of contact for all trade queries, order cancellations, margin breakdown, UPI deposits, and app troubleshooting.',
      ),
      const EscalationTier(
        level: 2,
        title: 'Level 2: Head of Customer Experience',
        officerName: 'Vikramaditya Sharma',
        designation: 'Head — Client Operations & Grievances',
        email: 'escalations@zerodalali.com',
        phone: '+91 22 6982 4401',
        tat: 'Within 48 Working Hours',
        description: 'If your issue is unresolved at Level 1 within 24 hours, escalate directly to the Head of Support with your Ticket #ID.',
      ),
      const EscalationTier(
        level: 3,
        title: 'Level 3: Chief Compliance Officer',
        officerName: 'Ananya Deshmukh',
        designation: 'Principal Compliance Officer & Key Managerial Personnel',
        email: 'compliance@zerodalali.com',
        phone: '+91 22 6982 4499',
        tat: 'Within 7 Working Days',
        description: 'Statutory compliance authority for regulatory grievances, DP disputes, unauthorized trades, and formal complaints.',
      ),
      const EscalationTier(
        level: 4,
        title: 'Level 4: SEBI SCORES & Smart ODR Portal',
        officerName: 'Securities and Exchange Board of India',
        designation: 'Market Regulator & Online Dispute Resolution',
        email: 'scores@sebi.gov.in',
        phone: '1800 266 7575 / 1800 22 7575',
        tat: 'Within 30 Days as per SEBI guidelines',
        description: 'If unresolved within 30 days, investors can lodge a complaint directly on SEBI SCORES portal (scores.gov.in) or SMART ODR portal (smartodr.in).',
      ),
    ]);

    // ─── 4. Seed Corporate Contact Details ────────────────────────────────────
    _corporateContact = const CorporateContact(
      companyName: 'Zero Dalali Securities Private Limited',
      registeredAddress: 'Level 14, Tower 2, One International Center, Senapati Bapat Marg, Prabhadevi, Mumbai - 400013, Maharashtra, India.',
      corporateOffice: 'Block B, Nesco IT Park, Western Express Highway, Goregaon East, Mumbai - 400063, Maharashtra, India.',
      sebiRegNumber: 'INZ000031633 (Stock Broker - Cash, F&O, Currency, Commodity)',
      cdslDpId: '12081600',
      nsdlDpId: 'IN300126',
      nseMemberId: '14288',
      bseMemberId: '6312',
      mcxMemberId: '56820',
      tollFreePhone: '1800-ZERO-DESK (1800-9376-3375)',
      directPhone: '+91 22 6982 4400',
      supportEmail: 'support@zerodalali.com',
      complianceEmail: 'compliance@zerodalali.com',
      hours: '24×7 Round-the-Clock Support Coverage',
    );

    // ─── 5. Seed Live Chat Conversation ──────────────────────────────────────
    _liveChatMessages.addAll([
      TicketMessage(
        id: 'lc_01',
        senderName: 'Zero Support Desk',
        senderRole: MessageSenderRole.supportAgent,
        content: 'Hi Anurag, welcome to Zero 24/7 Live Support! How can I assist you with your trading or account today?',
        timestamp: now.subtract(const Duration(minutes: 5)),
      ),
    ]);

    _ticketsStreamController.add(List.unmodifiable(_tickets));
    _liveChatStreamController.add(List.unmodifiable(_liveChatMessages));
  }

  // ─── Ticket Management Operations ─────────────────────────────────────────

  Future<SupportTicket> createTicket({
    required String title,
    required String description,
    required TicketCategory category,
    required TicketPriority priority,
    List<TicketAttachment> attachments = const [],
  }) async {
    final now = DateTime.now();
    final ticketId = 'TK-${now.year}-${(10000 + _tickets.length + 1)}';

    final initialMessages = [
      TicketMessage(
        id: 'msg_${now.millisecondsSinceEpoch}_client',
        senderName: 'Client',
        senderRole: MessageSenderRole.client,
        content: description,
        timestamp: now,
        attachments: attachments,
      ),
      TicketMessage(
        id: 'msg_${now.millisecondsSinceEpoch}_bot',
        senderName: 'Zero Care Desk',
        senderRole: MessageSenderRole.system,
        content: 'Thank you for contacting Zero Support. Ticket #$ticketId has been logged under ${category.label}. A support executive will review and reply shortly.',
        timestamp: now.add(const Duration(seconds: 1)),
      ),
    ];

    final newTicket = SupportTicket(
      id: ticketId,
      title: title,
      description: description,
      category: category,
      priority: priority,
      status: TicketStatus.open,
      createdAt: now,
      updatedAt: now,
      messages: initialMessages,
      attachments: attachments,
      assignedAgent: priority == TicketPriority.critical
          ? 'Emergency RMS Team'
          : 'Zero Care Officer',
    );

    _tickets.insert(0, newTicket);
    _ticketsStreamController.add(List.unmodifiable(_tickets));
    notifyListeners();

    // Dispatch notification to user
    try {
      _ref?.read(notificationServiceProvider).notify(NotificationItem(
        id: 'notif_ticket_${now.millisecondsSinceEpoch}',
        type: NotificationType.accountNotice,
        category: NotificationCategory.security,
        title: 'Support Ticket Created: #$ticketId',
        body: 'Your ticket "$title" was submitted. Priority: ${priority.label}.',
        timestamp: now,
        deepLink: '/help/tickets/$ticketId',
        metadata: {'ticketId': ticketId, 'category': category.name},
      ));
    } catch (_) {}

    return newTicket;
  }

  void addReply({
    required String ticketId,
    required String content,
    List<TicketAttachment> attachments = const [],
  }) {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) return;

    final existing = _tickets[index];
    final now = DateTime.now();

    final userMsg = TicketMessage(
      id: 'msg_${now.millisecondsSinceEpoch}',
      senderName: 'Client',
      senderRole: MessageSenderRole.client,
      content: content,
      timestamp: now,
      attachments: attachments,
    );

    final updatedMessages = List<TicketMessage>.from(existing.messages)..add(userMsg);

    _tickets[index] = existing.copyWith(
      messages: updatedMessages,
      updatedAt: now,
      status: TicketStatus.open,
    );

    _ticketsStreamController.add(List.unmodifiable(_tickets));
    notifyListeners();

    // Simulate Agent Auto-Response after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      final curIdx = _tickets.indexWhere((t) => t.id == ticketId);
      if (curIdx != -1) {
        final curTicket = _tickets[curIdx];
        final replyTime = DateTime.now();
        final agentMsg = TicketMessage(
          id: 'msg_${replyTime.millisecondsSinceEpoch}_agent',
          senderName: curTicket.assignedAgent,
          senderRole: MessageSenderRole.supportAgent,
          content: 'Thank you for the update. Our support engineer is reviewing your inquiry regarding "${curTicket.title}" and will provide an update shortly.',
          timestamp: replyTime,
        );

        final msgsWithAgent = List<TicketMessage>.from(curTicket.messages)..add(agentMsg);
        _tickets[curIdx] = curTicket.copyWith(
          messages: msgsWithAgent,
          updatedAt: replyTime,
          status: TicketStatus.inProgress,
        );
        _ticketsStreamController.add(List.unmodifiable(_tickets));
        notifyListeners();
      }
    });
  }

  void updateTicketStatus(String ticketId, TicketStatus status) {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) return;

    final existing = _tickets[index];
    final now = DateTime.now();

    final systemMsg = TicketMessage(
      id: 'msg_${now.millisecondsSinceEpoch}_status',
      senderName: 'Zero Desk',
      senderRole: MessageSenderRole.system,
      content: 'Ticket status changed to ${status.label.toUpperCase()}.',
      timestamp: now,
    );

    _tickets[index] = existing.copyWith(
      status: status,
      updatedAt: now,
      messages: List<TicketMessage>.from(existing.messages)..add(systemMsg),
    );

    _ticketsStreamController.add(List.unmodifiable(_tickets));
    notifyListeners();
  }

  SupportTicket? getTicketById(String id) {
    try {
      return _tickets.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── FAQ Filtering & Search ───────────────────────────────────────────────

  List<FaqItem> getFaqs({String? query, String? category}) {
    return _faqs.where((f) {
      if (category != null && category != 'All' && f.category != category) {
        return false;
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final inQ = f.question.toLowerCase().contains(q);
        final inA = f.answer.toLowerCase().contains(q);
        final inTags = f.tags.any((t) => t.toLowerCase().contains(q));
        if (!inQ && !inA && !inTags) return false;
      }
      return true;
    }).toList();
  }

  void incrementHelpful(String faqId) {
    final index = _faqs.indexWhere((f) => f.id == faqId);
    if (index != -1) {
      _faqs[index].helpfulCount++;
      notifyListeners();
    }
  }

  // ─── Live Chat Interactive Messaging ─────────────────────────────────────

  Future<void> sendChatMessage(String text) async {
    final now = DateTime.now();

    final userMsg = TicketMessage(
      id: 'lc_msg_${now.millisecondsSinceEpoch}',
      senderName: 'You',
      senderRole: MessageSenderRole.client,
      content: text,
      timestamp: now,
    );

    _liveChatMessages.add(userMsg);
    _liveChatStreamController.add(List.unmodifiable(_liveChatMessages));
    notifyListeners();

    // Context-aware simulated assistant response
    final lower = text.toLowerCase();
    String responseText = 'Thank you for your message. An agent is reviewing your query.';

    if (lower.contains('deposit') || lower.contains('upi') || lower.contains('fund')) {
      responseText = 'For deposit delays: UPI transactions usually reflect instantly. If your bank account was debited, check Funds -> History or provide your 12-digit UTR number here for instant tracking.';
    } else if (lower.contains('margin') || lower.contains('leverage') || lower.contains('square off')) {
      responseText = 'Intraday (MIS) trades receive up to 5x leverage. Intraday auto square-off begins at 03:20 PM IST. Please maintain adequate buffer above 90% utilization to prevent RMS liquidation.';
    } else if (lower.contains('order') || lower.contains('reject')) {
      responseText = 'Common order rejection causes include: price outside daily circuit limit, quantity exceeding freeze limit, market closed (AMO required), or insufficient available margin.';
    } else if (lower.contains('kyc') || lower.contains('nominee') || lower.contains('account')) {
      responseText = 'You can manage KYC, Bank Accounts, and Nominees directly from the Profile tab. Demat CMR reports are also available for download.';
    } else if (lower.contains('human') || lower.contains('agent') || lower.contains('call')) {
      responseText = 'Connecting you to Senior Desk Officer Vikramaditya. You can also dial our 24×7 Toll-Free helpline: 1800-ZERO-DESK (1800-9376-3375).';
    }

    await Future.delayed(const Duration(milliseconds: 600));

    final agentMsg = TicketMessage(
      id: 'lc_reply_${DateTime.now().millisecondsSinceEpoch}',
      senderName: 'Zero Support Officer Priya',
      senderRole: MessageSenderRole.supportAgent,
      content: responseText,
      timestamp: DateTime.now(),
    );

    _liveChatMessages.add(agentMsg);
    _liveChatStreamController.add(List.unmodifiable(_liveChatMessages));
    notifyListeners();
  }

  @override
  void dispose() {
    _ticketsStreamController.close();
    _liveChatStreamController.close();
    super.dispose();
  }
}

final supportRepositoryProvider = ChangeNotifierProvider<SupportRepository>((ref) {
  return SupportRepository(ref);
});

final supportTicketsProvider = StreamProvider<List<SupportTicket>>((ref) {
  final repo = ref.watch(supportRepositoryProvider);
  return repo.ticketsStream;
});

final liveChatStreamProvider = StreamProvider<List<TicketMessage>>((ref) {
  final repo = ref.watch(supportRepositoryProvider);
  return repo.liveChatStream;
});
