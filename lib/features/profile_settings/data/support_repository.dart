import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../core/network/socket_service.dart';
import '../../../data/models/models.dart';

class SupportRepository extends ChangeNotifier {
  final ApiClient? _apiClient;
  final SocketService? _socketService;

  final List<SupportTicket> _tickets = [];
  final List<TicketMessage> _liveChatMessages = [];

  final StreamController<List<SupportTicket>> _ticketsStreamController =
      StreamController<List<SupportTicket>>.broadcast();
  final StreamController<List<TicketMessage>> _liveChatStreamController =
      StreamController<List<TicketMessage>>.broadcast();

  StreamSubscription? _socketMessageSub;

  SupportRepository({
    ApiClient? apiClient,
    SocketService? socketService,
  })  : _apiClient = apiClient,
        _socketService = socketService {
    if (_socketService != null) {
      _socketMessageSub = _socketService.supportMessageStream.listen((data) {
        if (data.containsKey('message') && data['message'] is Map<String, dynamic>) {
          final msgMap = data['message'] as Map<String, dynamic>;
          final message = TicketMessage.fromJson(msgMap);
          _liveChatMessages.add(message);
          _liveChatStreamController.add(List.unmodifiable(_liveChatMessages));
          notifyListeners();
        }
      });
    }
    if (_apiClient != null) {
      fetchTickets();
    }
  }

  List<SupportTicket> get tickets => List.unmodifiable(_tickets);
  List<TicketMessage> get liveChatMessages => List.unmodifiable(_liveChatMessages);
  Stream<List<SupportTicket>> get ticketsStream => _ticketsStreamController.stream;
  Stream<List<TicketMessage>> get liveChatStream => _liveChatStreamController.stream;

  Future<List<SupportTicket>> fetchTickets({String? status, int page = 1, int limit = 20}) async {
    if (_apiClient == null) {
      return List.unmodifiable(_tickets);
    }
    try {
      final Map<String, dynamic> params = {'page': page, 'limit': limit};
      if (status != null) params['status'] = status;

      final data = await _apiClient.get(
        ApiPaths.supportTickets,
        queryParameters: params,
      );

      final items = ResponseReader.list(data, 'tickets');
      final rawList = items.isNotEmpty ? items : ResponseReader.list(data, 'items');
      final list = rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => SupportTicket.fromJson(item))
          .toList();

      _tickets.clear();
      _tickets.addAll(list);
      _ticketsStreamController.add(List.unmodifiable(_tickets));
      notifyListeners();
      return list;
    } catch (_) {
      return List.unmodifiable(_tickets);
    }
  }

  Future<SupportTicket> createTicket({
    required String title,
    required String description,
    required TicketCategory category,
    required TicketPriority priority,
    List<TicketAttachment> attachments = const [],
  }) async {
    SupportTicket ticket;
    if (_apiClient != null) {
      try {
        final data = await _apiClient.post(
          ApiPaths.supportTickets,
          data: {
            'subject': title,
            'category': category.name,
            'priority': priority.name,
            'message': description,
            if (attachments.isNotEmpty)
              'attachments': attachments.map((a) => a.toJson()).toList(),
          },
        );

        final obj = ResponseReader.object(data, 'ticket');
        ticket = obj.isNotEmpty
            ? SupportTicket.fromJson(obj)
            : SupportTicket(
                id: 'TK-2026-${DateTime.now().millisecondsSinceEpoch}',
                title: title,
                description: description,
                category: category,
                priority: priority,
                status: TicketStatus.open,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                attachments: attachments,
                messages: [
                  TicketMessage(
                    id: 'msg_1',
                    senderName: 'Client',
                    senderRole: MessageSenderRole.client,
                    content: description,
                    timestamp: DateTime.now(),
                  ),
                  TicketMessage(
                    id: 'msg_2',
                    senderName: 'System',
                    senderRole: MessageSenderRole.system,
                    content: 'Ticket created successfully. Our team will respond shortly.',
                    timestamp: DateTime.now(),
                  ),
                ],
              );
      } catch (_) {
        ticket = SupportTicket(
          id: 'TK-2026-${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          description: description,
          category: category,
          priority: priority,
          status: TicketStatus.open,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          attachments: attachments,
          messages: [
            TicketMessage(
              id: 'msg_1',
              senderName: 'Client',
              senderRole: MessageSenderRole.client,
              content: description,
              timestamp: DateTime.now(),
            ),
            TicketMessage(
              id: 'msg_2',
              senderName: 'System',
              senderRole: MessageSenderRole.system,
              content: 'Ticket created successfully. Our team will respond shortly.',
              timestamp: DateTime.now(),
            ),
          ],
        );
      }
    } else {
      ticket = SupportTicket(
        id: 'TK-2026-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
        category: category,
        priority: priority,
        status: TicketStatus.open,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attachments: attachments,
        messages: [
          TicketMessage(
            id: 'msg_1',
            senderName: 'Client',
            senderRole: MessageSenderRole.client,
            content: description,
            timestamp: DateTime.now(),
          ),
          TicketMessage(
            id: 'msg_2',
            senderName: 'System',
            senderRole: MessageSenderRole.system,
            content: 'Ticket created successfully. Our team will respond shortly.',
            timestamp: DateTime.now(),
          ),
        ],
      );
    }
    _tickets.insert(0, ticket);
    _ticketsStreamController.add(List.unmodifiable(_tickets));
    notifyListeners();
    return ticket;
  }

  Future<SupportTicket> getTicketDetail(String id) async {
    if (_apiClient != null) {
      final data = await _apiClient.get(ApiPaths.supportTicketDetail(id));
      final obj = ResponseReader.object(data, 'ticket');
      return SupportTicket.fromJson(obj.isNotEmpty ? obj : ResponseReader.object(data));
    }
    return getTicketById(id) ??
        SupportTicket(
          id: id,
          title: 'Ticket #$id',
          description: '',
          category: TicketCategory.tradingOrders,
          priority: TicketPriority.medium,
          status: TicketStatus.open,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
  }

  Future<TicketAttachment> uploadAttachment({
    required String fileName,
    required List<int> bytes,
    String? mimeType,
  }) async {
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    final detectedMime = mimeType ?? (isPdf ? 'application/pdf' : 'image/png');
    final base64String = base64Encode(bytes);
    final dataUri = 'data:$detectedMime;base64,$base64String';

    if (_apiClient != null) {
      try {
        final res = await _apiClient.post(
          ApiPaths.kycUpload,
          data: {
            'documentType': 'SUPPORT_ATTACHMENT',
            'fileName': fileName,
            'fileData': dataUri,
            'data': dataUri,
            'mimeType': detectedMime,
          },
        );
        final obj = ResponseReader.object(res, 'document');
        final url = (obj['url'] ?? obj['fileUrl'] ?? '/uploads/$fileName').toString();
        final size = (obj['size'] ?? bytes.length) as int;
        return TicketAttachment(
          id: url,
          fileName: fileName,
          fileSizeBytes: size,
          fileType: isPdf ? 'pdf' : 'image',
          uploadedAt: DateTime.now(),
        );
      } catch (_) {
        // Fallback to locally structured attachment if backend offline
      }
    }

    return TicketAttachment(
      id: 'att_${DateTime.now().millisecondsSinceEpoch}',
      fileName: fileName,
      fileSizeBytes: bytes.length,
      fileType: isPdf ? 'pdf' : 'image',
      uploadedAt: DateTime.now(),
    );
  }

  Future<void> replyTicket(
    String id,
    String message, {
    List<TicketAttachment> attachments = const [],
  }) async {
    if (_apiClient != null) {
      await _apiClient.post(
        ApiPaths.supportTicketReply(id),
        data: {
          'message': message,
          if (attachments.isNotEmpty)
            'attachments': attachments.map((a) => a.toJson()).toList(),
        },
      );
    }
  }

  void joinTicketRoom(String ticketId) {
    _socketService?.joinTicket(ticketId);
  }

  void leaveTicketRoom(String ticketId) {
    _socketService?.leaveTicket(ticketId);
  }

  void sendLiveChatMessage(String text) {
    final msg = TicketMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderName: 'You',
      senderRole: MessageSenderRole.client,
      content: text,
      timestamp: DateTime.now(),
    );
    _liveChatMessages.add(msg);
    _liveChatStreamController.add(List.unmodifiable(_liveChatMessages));
    notifyListeners();
  }

  Future<void> sendChatMessage(String text) async {
    final userMsg = TicketMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderName: 'You',
      senderRole: MessageSenderRole.client,
      content: text,
      timestamp: DateTime.now(),
    );
    _liveChatMessages.add(userMsg);
    if (_socketService == null) {
      final replyContent = text.contains('UPI deposit')
          ? 'Your UPI deposit is being verified by the banking gateway. Funds are usually credited within 10-15 minutes.'
          : 'Thank you for your message. A customer care representative will connect with you shortly.';
      final botMsg = TicketMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch + 1}',
        senderName: 'Zero Care Representative',
        senderRole: MessageSenderRole.supportAgent,
        content: replyContent,
        timestamp: DateTime.now().add(const Duration(milliseconds: 100)),
      );
      _liveChatMessages.add(botMsg);
    }
    _liveChatStreamController.add(List.unmodifiable(_liveChatMessages));
    notifyListeners();
  }

  Future<void> addReply({
    required String ticketId,
    required String content,
    List<TicketAttachment> attachments = const [],
  }) async {
    if (_apiClient != null) {
      await replyTicket(ticketId, content).catchError((_) {});
    }
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      final oldTicket = _tickets[index];
      final newMessages = List<TicketMessage>.from(oldTicket.messages)
        ..add(TicketMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          senderName: 'Client',
          senderRole: MessageSenderRole.client,
          content: content,
          timestamp: DateTime.now(),
          attachments: attachments,
        ));
      _tickets[index] = oldTicket.copyWith(
        messages: newMessages,
        updatedAt: DateTime.now(),
      );
      _ticketsStreamController.add(List.unmodifiable(_tickets));
      notifyListeners();
    }
  }

  SupportTicket? getTicketById(String id) {
    return _tickets.where((t) => t.id == id).firstOrNull;
  }

  Future<void> updateTicketStatus(String id, dynamic status) async {
    // Note: Backend contract defines status updates as an admin action (/api/admin/support/tickets/:id/status).
    // Client tickets automatically transition state upon user replies (/api/support/tickets/:id/reply).
    // Documented in BACKEND_GAPS.md.
    final index = _tickets.indexWhere((t) => t.id == id);
    if (index != -1) {
      final oldTicket = _tickets[index];
      final parsedStatus = status is TicketStatus
          ? status
          : TicketStatus.values.firstWhere(
              (s) => s.name.toLowerCase() == status.toString().toLowerCase(),
              orElse: () => TicketStatus.open,
            );
      final newMessages = List<TicketMessage>.from(oldTicket.messages)
        ..add(TicketMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          senderName: 'System',
          senderRole: MessageSenderRole.system,
          content: 'Ticket status changed to ${parsedStatus.label}',
          timestamp: DateTime.now(),
        ));
      _tickets[index] = oldTicket.copyWith(
        status: parsedStatus,
        messages: newMessages,
        updatedAt: DateTime.now(),
      );
      _ticketsStreamController.add(List.unmodifiable(_tickets));
      notifyListeners();
    }
  }

  final List<FaqItem> _faqs = [
    FaqItem(
      id: 'faq_1',
      category: 'Trading & Orders',
      question: 'How do I place an Intraday (MIS) vs Delivery (CNC) order?',
      answer: 'Select MIS for intraday trading with leverage, which auto squares-off before market close. Select CNC for cash-and-carry delivery trades held overnight.',
      tags: ['MIS', 'CNC', 'Orders', 'Leverage'],
    ),
    FaqItem(
      id: 'faq_2',
      category: 'Trading & Orders',
      question: 'What order types are supported on ZeroDalali?',
      answer: 'ZeroDalali supports MARKET, LIMIT, SL (Stop Loss Limit), and SL-M (Stop Loss Market) orders across NSE and BSE equity & F&O segments.',
      tags: ['Market', 'Limit', 'Stop Loss', 'Orders'],
    ),
    FaqItem(
      id: 'faq_3',
      category: 'Funds & Payments',
      question: 'How do Instant UPI deposits work?',
      answer: 'Instant UPI deposits are processed in real-time through authorized banking rails. Your trading limit is credited immediately upon backend webhook verification.',
      tags: ['UPI', 'Deposit', 'Funds', 'Wallet'],
    ),
    FaqItem(
      id: 'faq_4',
      category: 'Funds & Payments',
      question: 'What is the payout / withdrawal turnaround time?',
      answer: 'Withdrawal requests placed before 8:00 PM on trading days are processed the same night and credited to your primary verified bank account by the next morning.',
      tags: ['Withdrawal', 'Payout', 'Bank'],
    ),
    FaqItem(
      id: 'faq_5',
      category: 'Margin & Leverage',
      question: 'How is Peak Margin calculated?',
      answer: 'Peak margin requirements follow SEBI guidelines based on Value at Risk (VaR) + Extreme Loss Margin (ELM). Ensure sufficient margin to avoid peak margin penalties.',
      tags: ['Margin', 'SEBI', 'RMS', 'VaR'],
    ),
    FaqItem(
      id: 'faq_6',
      category: 'F&O & Derivatives',
      question: 'How can I trade Options and Futures contracts?',
      answer: 'Activate the F&O segment in your KYC profile by providing required income proof (6 months bank statement or ITR acknowledgment).',
      tags: ['FNO', 'Options', 'Futures', 'Derivatives'],
    ),
    FaqItem(
      id: 'faq_7',
      category: 'Account & KYC',
      question: 'How do I update my primary bank account or nominee?',
      answer: 'Navigate to Profile > KYC & Documents or Nominee Management. Upload a cancelled cheque or bank statement bearing your name and account number.',
      tags: ['KYC', 'Bank Account', 'Nominee', 'Profile'],
    ),
    FaqItem(
      id: 'faq_8',
      category: 'IPO & Corporate Actions',
      question: 'How do I apply for Mainboard and SME IPOs?',
      answer: 'Navigate to Orders > IPO. Select the desired issue, enter lot size, and submit your UPI ID. Approve the mandate in your UPI app before 5:00 PM on the closing date.',
      tags: ['IPO', 'Mandate', 'UPI', 'Corporate Actions'],
    ),
    FaqItem(
      id: 'faq_9',
      category: 'Security & Biometrics',
      question: 'How do I enable Biometric App Lock & 2FA TOTP?',
      answer: 'Go to Profile > Security & Privacy. Toggle Biometric Unlock and scan the QR code using Google Authenticator or Microsoft Authenticator for SEBI mandated 2FA.',
      tags: ['2FA', 'TOTP', 'Biometric', 'Security'],
    ),
    FaqItem(
      id: 'faq_10',
      category: 'Charges & Taxes',
      question: 'What are the brokerage charges and STT rates?',
      answer: 'Zero brokerage on Equity Delivery (CNC). Flat ₹20 or 0.03% (whichever is lower) for Intraday (MIS) and F&O. STT and exchange turnover charges apply per regulatory schedule.',
      tags: ['Brokerage', 'STT', 'Charges', 'Taxes'],
    ),
  ];

  List<FaqItem> get faqs => _faqs;

  List<FaqItem> getFaqs({String? query, String? category}) {
    return _faqs.where((f) {
      final matchesCategory = category == null || category == 'All' || f.category.toLowerCase() == category.toLowerCase();
      final matchesQuery = query == null ||
          query.trim().isEmpty ||
          f.question.toLowerCase().contains(query.toLowerCase()) ||
          f.answer.toLowerCase().contains(query.toLowerCase()) ||
          f.tags.any((t) => t.toLowerCase().contains(query.toLowerCase()));
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void incrementHelpful(String faqId) {
    final faq = _faqs.where((f) => f.id == faqId).firstOrNull;
    if (faq != null) {
      faq.helpfulCount++;
      notifyListeners();
    }
  }

  List<EscalationTier> get escalationTiers => const [
    EscalationTier(
      level: 1,
      title: 'Tier 1 - Front Desk',
      officerName: 'Zero Care Representative',
      designation: 'Senior Customer Support Associate',
      email: 'support@zerodalali.com',
      phone: '1800-ZERO-DESK',
      tat: 'Within 2 Hours (24×7)',
      description: 'First level for all trade queries, platform support, and payment verification.',
    ),
    EscalationTier(
      level: 2,
      title: 'Tier 2 - Head of Customer Service',
      officerName: 'Vikramaditya Sharma',
      designation: 'Head of Customer Experience',
      email: 'head.service@zerodalali.com',
      phone: '+91 80 4718 1888',
      tat: 'Within 48 Working Hours',
      description: 'Escalation for unresolved level 1 tickets and RMS operational issues.',
    ),
    EscalationTier(
      level: 3,
      title: 'Tier 3 - Principal Compliance Officer',
      officerName: 'Ananya Deshmukh',
      designation: 'Principal Compliance Officer',
      email: 'compliance@zerodalali.com',
      phone: '+91 80 4718 1890',
      tat: 'Within 7 Working Days',
      description: 'Regulatory matters, exchange grievance disputes, and DP reconciliation.',
    ),
    EscalationTier(
      level: 4,
      title: 'Tier 4 - SEBI SCORES / SmartODR Portal',
      officerName: 'Securities and Exchange Board of India',
      designation: 'Regulatory & Online Dispute Resolution',
      email: 'scores@sebi.gov.in',
      phone: '1800 266 7575',
      tat: 'Within 30 Days (Statutory)',
      description: 'External SEBI grievance redressal mechanism and conciliation portal.',
    ),
  ];

  CorporateContact get corporateContact => const CorporateContact(
    companyName: 'Zero Dalali Financial Technologies Pvt Ltd',
    registeredAddress: 'Outer Ring Road, Bellandur, Bangalore, Karnataka - 560103',
    corporateOffice: 'Tower B, Outer Ring Road, Bangalore - 560103',
    sebiRegNumber: 'INZ000293339',
    cdslDpId: '12088700',
    nsdlDpId: 'IN300126',
    nseMemberId: '90214',
    bseMemberId: '6743',
    mcxMemberId: '56820',
    tollFreePhone: '1800-ZERO-DESK',
    directPhone: '+91 80 4718 1888',
    supportEmail: 'support@zerodalali.com',
    complianceEmail: 'compliance@zerodalali.com',
    hours: '9:00 AM - 11:30 PM IST (Mon - Fri)',
  );

  @override
  void dispose() {
    _socketMessageSub?.cancel();
    if (!_ticketsStreamController.isClosed) _ticketsStreamController.close();
    if (!_liveChatStreamController.isClosed) _liveChatStreamController.close();
    super.dispose();
  }
}

final supportRepositoryProvider = ChangeNotifierProvider<SupportRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final socketService = ref.watch(socketServiceProvider);
  return SupportRepository(apiClient: apiClient, socketService: socketService);
});

final supportTicketsProvider = FutureProvider<List<SupportTicket>>((ref) async {
  final repo = ref.watch(supportRepositoryProvider);
  return repo.fetchTickets();
});
