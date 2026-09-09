import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/charges_config.dart';
import '../../core/services/financial_calculation_service.dart';
import '../../core/services/market_status_service.dart';
import '../models/models.dart';
import 'seed_instruments.dart';
import 'ticker_service.dart';
import '../../core/services/notification_service.dart';

class OrderSimulationEngine {
  final Ref _ref;
  final List<Order> _orders = [];
  final List<Position> _positions = [];
  final List<Holding> _holdings = [];
  final List<LedgerEntry> _ledger = [];
  final List<GttOrder> _gtts = [];
  final List<LinkedBankAccount> _linkedBankAccounts = [
    const LinkedBankAccount(
      id: 'bank_hdfc_01',
      bankName: 'HDFC Bank Ltd',
      accountNumberMasked: '•••• •••• 4912',
      ifsc: 'HDFC0000123',
      isPrimary: true,
      isVerified: true,
    ),
    const LinkedBankAccount(
      id: 'bank_icici_02',
      bankName: 'ICICI Bank Ltd',
      accountNumberMasked: '•••• •••• 8841',
      ifsc: 'ICIC0000456',
      isPrimary: false,
      isVerified: true,
    ),
  ];
  final List<WalletTransaction> _walletTransactions = [];
  final List<TransactionRecord> _unifiedTransactions = [];
  
  double _availableEquityMargin = 250000.0;
  double _usedEquityMargin = 0.0;
  final double _openingEquityBalance = 250000.0;

  final StreamController<List<Order>> _ordersStreamController = StreamController.broadcast();
  final StreamController<List<Position>> _positionsStreamController = StreamController.broadcast();
  final StreamController<List<Holding>> _holdingsStreamController = StreamController.broadcast();
  final StreamController<List<GttOrder>> _gttStreamController = StreamController.broadcast();
  final StreamController<List<WalletTransaction>> _walletTransactionsStreamController = StreamController.broadcast();
  final StreamController<List<TransactionRecord>> _unifiedTransactionsStreamController = StreamController.broadcast();

  final _uuid = const Uuid();
  final _rng = Random();
  bool simulateNetworkTimeout = false;
  bool enforceMarketHours = false;
  final Map<String, DateTime> _paymentKeys = {};

  void _dispatchNotification({
    required NotificationType type,
    required NotificationCategory category,
    required String title,
    required String body,
    required String deepLink,
    Map<String, dynamic> metadata = const {},
    bool isCritical = false,
  }) {
    try {
      final notifService = _ref.read(notificationServiceProvider);
      notifService.notify(NotificationItem(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(9999)}',
        type: type,
        category: category,
        title: title,
        body: body,
        timestamp: DateTime.now(),
        deepLink: deepLink,
        metadata: metadata,
        isCritical: isCritical,
      ));
    } catch (_) {}
  }


  OrderSimulationEngine(this._ref) {
    _seedInitialData();
  }

  void _seedInitialData() {
    // Seed initial holdings (Kite demo style)
    final rel = SeedInstruments.findByToken('eq_reliance')!;
    final tcs = SeedInstruments.findByToken('eq_tcs')!;
    final hdfc = SeedInstruments.findByToken('eq_hdfcbank')!;
    final infy = SeedInstruments.findByToken('eq_infy')!;
    final itc = SeedInstruments.findByToken('eq_itc')!;
    final tata = SeedInstruments.findByToken('eq_tatamotors')!;

    _holdings.addAll([
      Holding(
        instrument: rel,
        quantity: 25,
        t1Quantity: 0,
        averagePrice: 2840.00,
        ltp: 2985.50,
        closePrice: 2950.00,
        firstBuyDate: DateTime.now().subtract(const Duration(days: 120)),
      ),
      Holding(
        instrument: tcs,
        quantity: 15,
        t1Quantity: 5,
        averagePrice: 3950.00,
        ltp: 4215.00,
        closePrice: 4180.00,
        firstBuyDate: DateTime.now().subtract(const Duration(days: 240)),
      ),
      Holding(
        instrument: hdfc,
        quantity: 50,
        t1Quantity: 0,
        averagePrice: 1580.00,
        ltp: 1648.20,
        closePrice: 1635.00,
        firstBuyDate: DateTime.now().subtract(const Duration(days: 90)),
      ),
      Holding(
        instrument: infy,
        quantity: 40,
        t1Quantity: 0,
        averagePrice: 1720.00,
        ltp: 1885.30,
        closePrice: 1860.00,
        firstBuyDate: DateTime.now().subtract(const Duration(days: 45)),
      ),
      Holding(
        instrument: itc,
        quantity: 100,
        t1Quantity: 0,
        averagePrice: 440.00,
        ltp: 502.40,
        closePrice: 498.00,
        firstBuyDate: DateTime.now().subtract(const Duration(days: 300)),
      ),
      Holding(
        instrument: tata,
        quantity: 30,
        t1Quantity: 0,
        averagePrice: 940.00,
        ltp: 1085.00,
        closePrice: 1070.00,
        firstBuyDate: DateTime.now().subtract(const Duration(days: 60)),
      ),
    ]);

    // Initial Ledger Entry
    _ledger.add(LedgerEntry(
      id: _uuid.v4(),
      date: DateTime.now().subtract(const Duration(days: 3)),
      narration: 'Funds added via UPI (Ref: ZD-PAY-984120)',
      credit: 250000.0,
      debit: 0.0,
      runningBalance: 250000.0,
    ));

    // Seed Wallet Transactions History
    _walletTransactions.addAll([
      WalletTransaction(
        id: 'wt_dep_seed_1',
        referenceId: 'ZD-PAY-984120',
        type: WalletTransactionType.DEPOSIT,
        amount: 250000.0,
        status: WalletTransactionStatus.SUCCESS,
        method: PaymentMethod.UPI,
        upiId: 'anurag@okhdfcbank',
        bankAccount: 'HDFC Bank Ltd (•••• 4912)',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      WalletTransaction(
        id: 'wt_wth_seed_1',
        referenceId: 'ZD-WTH-881942',
        type: WalletTransactionType.WITHDRAWAL,
        amount: 25000.0,
        status: WalletTransactionStatus.COMPLETED,
        method: PaymentMethod.NET_BANKING,
        bankAccount: 'HDFC Bank Ltd (•••• 4912)',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
    ]);

    // Seed Unified Transactions Feed (Trades, Deposits, Payouts, Fees, Dividends)
    final now = DateTime.now();
    _unifiedTransactions.addAll([
      TransactionRecord(
        id: 'TXN-904121',
        orderId: 'ZD-1710920001',
        category: TransactionCategory.TRADE,
        title: 'BUY SBIN',
        narration: 'Purchased 50 shares of State Bank of India @ ₹810.00 (MIS Intraday)',
        instrumentSymbol: 'SBIN',
        quantity: 50,
        price: 810.00,
        amount: 40500.00,
        isCredit: false,
        runningBalance: 250000.0,
        timestamp: now.subtract(const Duration(hours: 1)),
        status: 'COMPLETE',
        account: 'Equity (NSE)',
        feeBreakdown: const {
          'Brokerage': 20.00,
          'STT': 10.13,
          'Exchange Charges': 1.32,
          'GST': 3.84,
          'SEBI Charges': 0.04,
          'Stamp Duty': 1.22,
        },
      ),
      TransactionRecord(
        id: 'ZD-PAY-984120',
        orderId: null,
        category: TransactionCategory.DEPOSIT,
        title: 'Deposit via UPI',
        narration: 'Instant UPI funds deposit from anurag@okhdfcbank (Ref: ZD-PAY-984120)',
        amount: 250000.00,
        isCredit: true,
        runningBalance: 250000.0,
        timestamp: now.subtract(const Duration(days: 3)),
        status: 'SUCCESS',
        account: 'Bank (HDFC •••• 4912)',
      ),
      TransactionRecord(
        id: 'TXN-DIV-TCS-01',
        orderId: null,
        category: TransactionCategory.DIVIDEND,
        title: 'Dividend - TCS Ltd',
        narration: 'Interim Dividend payout for 15 shares @ ₹10.00 per share',
        instrumentSymbol: 'TCS',
        quantity: 15,
        price: 10.00,
        amount: 150.00,
        isCredit: true,
        runningBalance: 250150.0,
        timestamp: now.subtract(const Duration(days: 5)),
        status: 'COMPLETE',
        account: 'Demat / Bank',
      ),
      TransactionRecord(
        id: 'ZD-WTH-881942',
        orderId: null,
        category: TransactionCategory.WITHDRAWAL,
        title: 'Payout to HDFC Bank',
        narration: 'Processed withdrawal transfer to primary linked bank account (•••• 4912)',
        amount: 25000.00,
        isCredit: false,
        runningBalance: 225150.0,
        timestamp: now.subtract(const Duration(days: 7)),
        status: 'COMPLETED',
        account: 'Bank (HDFC •••• 4912)',
      ),
      TransactionRecord(
        id: 'TXN-AMC-2026',
        orderId: null,
        category: TransactionCategory.FEE_CHARGE,
        title: 'Quarterly Maintenance (AMC)',
        narration: 'Regulatory Demat AMC charge for Q2 FY25-26 including 18% GST',
        amount: 354.00,
        isCredit: false,
        runningBalance: 224796.0,
        timestamp: now.subtract(const Duration(days: 10)),
        status: 'COMPLETE',
        account: 'Equity Ledger',
        feeBreakdown: const {
          'Base AMC': 300.00,
          'GST (18%)': 54.00,
        },
      ),
      TransactionRecord(
        id: 'TXN-902318',
        orderId: 'ZD-1710712002',
        category: TransactionCategory.TRADE,
        title: 'BUY RELIANCE',
        narration: 'Delivery acquisition of 25 shares of Reliance Industries Ltd @ ₹2,840.00',
        instrumentSymbol: 'RELIANCE',
        quantity: 25,
        price: 2840.00,
        amount: 71000.00,
        isCredit: false,
        runningBalance: 295796.0,
        timestamp: now.subtract(const Duration(days: 12)),
        status: 'COMPLETE',
        account: 'Equity (NSE)',
        feeBreakdown: const {
          'Brokerage': 0.00,
          'STT': 71.00,
          'Exchange Charges': 2.31,
          'GST': 0.42,
          'Stamp Duty': 10.65,
        },
      ),
      TransactionRecord(
        id: 'TXN-901944',
        orderId: 'ZD-1710609003',
        category: TransactionCategory.TRADE,
        title: 'BUY TCS',
        narration: 'Delivery purchase of 15 shares of Tata Consultancy Services @ ₹3,950.00',
        instrumentSymbol: 'TCS',
        quantity: 15,
        price: 3950.00,
        amount: 59250.00,
        isCredit: false,
        runningBalance: 366796.0,
        timestamp: now.subtract(const Duration(days: 14)),
        status: 'COMPLETE',
        account: 'Equity (NSE)',
        feeBreakdown: const {
          'Brokerage': 0.00,
          'STT': 59.25,
          'Exchange Charges': 1.93,
          'GST': 0.35,
          'Stamp Duty': 8.89,
        },
      ),
      TransactionRecord(
        id: 'TXN-DP-4912',
        orderId: null,
        category: TransactionCategory.FEE_CHARGE,
        title: 'DP Charges (CDSL)',
        narration: 'Depository participant debit charges on delivery sale execution',
        amount: 15.93,
        isCredit: false,
        runningBalance: 426046.0,
        timestamp: now.subtract(const Duration(days: 15)),
        status: 'COMPLETE',
        account: 'CDSL Demat',
        feeBreakdown: const {
          'CDSL Fee': 5.50,
          'Broker DP Fee': 8.00,
          'GST': 2.43,
        },
      ),
      TransactionRecord(
        id: 'TXN-DIV-ITC-02',
        orderId: null,
        category: TransactionCategory.DIVIDEND,
        title: 'Dividend - ITC Ltd',
        narration: 'Final Dividend distribution for 100 shares @ ₹6.50 per share',
        instrumentSymbol: 'ITC',
        quantity: 100,
        price: 6.50,
        amount: 650.00,
        isCredit: true,
        runningBalance: 426061.93,
        timestamp: now.subtract(const Duration(days: 18)),
        status: 'COMPLETE',
        account: 'Demat / Bank',
      ),
      TransactionRecord(
        id: 'ZD-PAY-771249',
        orderId: null,
        category: TransactionCategory.DEPOSIT,
        title: 'Deposit via Net Banking',
        narration: 'Net banking deposit via HDFC Bank NetBanking portal (Ref: ZD-PAY-771249)',
        amount: 100000.00,
        isCredit: true,
        runningBalance: 425411.93,
        timestamp: now.subtract(const Duration(days: 20)),
        status: 'SUCCESS',
        account: 'Bank (HDFC •••• 4912)',
      ),
      TransactionRecord(
        id: 'TXN-898210',
        orderId: 'ZD-1710311004',
        category: TransactionCategory.TRADE,
        title: 'BUY HDFCBANK',
        narration: 'Delivery acquisition of 50 shares of HDFC Bank Ltd @ ₹1,580.00',
        instrumentSymbol: 'HDFCBANK',
        quantity: 50,
        price: 1580.00,
        amount: 79000.00,
        isCredit: false,
        runningBalance: 325411.93,
        timestamp: now.subtract(const Duration(days: 22)),
        status: 'COMPLETE',
        account: 'Equity (NSE)',
        feeBreakdown: const {
          'Brokerage': 0.00,
          'STT': 79.00,
          'Exchange Charges': 2.57,
          'GST': 0.46,
          'Stamp Duty': 11.85,
        },
      ),
      TransactionRecord(
        id: 'TXN-897109',
        orderId: 'ZD-1710201005',
        category: TransactionCategory.TRADE,
        title: 'BUY INFY',
        narration: 'Delivery acquisition of 40 shares of Infosys Ltd @ ₹1,720.00',
        instrumentSymbol: 'INFY',
        quantity: 40,
        price: 1720.00,
        amount: 68800.00,
        isCredit: false,
        runningBalance: 404411.93,
        timestamp: now.subtract(const Duration(days: 24)),
        status: 'COMPLETE',
        account: 'Equity (NSE)',
        feeBreakdown: const {
          'Brokerage': 0.00,
          'STT': 68.80,
          'Exchange Charges': 2.24,
          'GST': 0.40,
          'Stamp Duty': 10.32,
        },
      ),
      TransactionRecord(
        id: 'TXN-896500',
        orderId: 'ZD-1710111006',
        category: TransactionCategory.TRADE,
        title: 'BUY ITC',
        narration: 'Delivery acquisition of 100 shares of ITC Ltd @ ₹440.00',
        instrumentSymbol: 'ITC',
        quantity: 100,
        price: 440.00,
        amount: 44000.00,
        isCredit: false,
        runningBalance: 473211.93,
        timestamp: now.subtract(const Duration(days: 26)),
        status: 'COMPLETE',
        account: 'Equity (NSE)',
        feeBreakdown: const {
          'Brokerage': 0.00,
          'STT': 44.00,
          'Exchange Charges': 1.43,
          'GST': 0.26,
          'Stamp Duty': 6.60,
        },
      ),
      TransactionRecord(
        id: 'TXN-895123',
        orderId: 'ZD-1710001007',
        category: TransactionCategory.TRADE,
        title: 'BUY TATAMOTORS',
        narration: 'Delivery acquisition of 30 shares of Tata Motors Ltd @ ₹940.00',
        instrumentSymbol: 'TATAMOTORS',
        quantity: 30,
        price: 940.00,
        amount: 28200.00,
        isCredit: false,
        runningBalance: 517211.93,
        timestamp: now.subtract(const Duration(days: 28)),
        status: 'COMPLETE',
        account: 'Equity (NSE)',
        feeBreakdown: const {
          'Brokerage': 0.00,
          'STT': 28.20,
          'Exchange Charges': 0.92,
          'GST': 0.17,
          'Stamp Duty': 4.23,
        },
      ),
      TransactionRecord(
        id: 'TXN-894100',
        orderId: 'ZD-1709901008',
        category: TransactionCategory.TRADE,
        title: 'SELL TATASTEEL',
        narration: 'Profit booking sale of 50 shares of Tata Steel Ltd @ ₹158.00',
        instrumentSymbol: 'TATASTEEL',
        quantity: 50,
        price: 158.00,
        amount: 7900.00,
        isCredit: true,
        runningBalance: 545411.93,
        timestamp: now.subtract(const Duration(days: 29)),
        status: 'COMPLETE',
        account: 'Equity (NSE)',
        feeBreakdown: const {
          'Brokerage': 0.00,
          'STT': 7.90,
          'Exchange Charges': 0.26,
          'GST': 0.05,
          'Stamp Duty': 0.00,
        },
      ),
      TransactionRecord(
        id: 'TXN-893000',
        orderId: 'ZD-1709801009',
        category: TransactionCategory.TRADE,
        title: 'BUY TATASTEEL',
        narration: 'Delivery purchase of 100 shares of Tata Steel Ltd @ ₹152.40',
        instrumentSymbol: 'TATASTEEL',
        quantity: 100,
        price: 152.40,
        amount: 15240.00,
        isCredit: false,
        runningBalance: 537511.93,
        timestamp: now.subtract(const Duration(days: 30)),
        status: 'COMPLETE',
        account: 'Equity (NSE)',
      ),
    ]);

    // Seed an initial executed order and a day position
    final sbin = SeedInstruments.findByToken('eq_sbin')!;
    final sbinCharges = ChargesConfig.calculateCharges(
      price: 810.0,
      quantity: 50,
      side: TransactionType.BUY,
      product: ProductType.MIS,
      instrumentType: InstrumentType.EQ,
    );

    final seedOrder = Order(
      orderId: 'ZD-${DateTime.now().millisecondsSinceEpoch}',
      exchangeOrderId: 'NSE-${1000000000 + _orders.length}',
      instrument: sbin,
      request: const OrderRequest(
        instrumentToken: 'eq_sbin',
        side: TransactionType.BUY,
        product: ProductType.MIS,
        kind: OrderKind.MARKET,
        quantity: 50,
      ),
      status: OrderStatus.COMPLETE,
      filledQty: 50,
      averagePrice: 810.00,
      placedAt: DateTime.now().subtract(const Duration(hours: 1)),
      timeline: [
        OrderEvent(status: OrderStatus.OPEN, description: 'Order submitted to exchange', at: DateTime.now().subtract(const Duration(hours: 1, seconds: 1))),
        OrderEvent(status: OrderStatus.COMPLETE, description: 'Traded at 810.00', at: DateTime.now().subtract(const Duration(hours: 1))),
      ],
      charges: sbinCharges,
    );
    _orders.add(seedOrder);

    _positions.add(Position(
      id: 'pos_eq_sbin',
      instrument: sbin,
      product: ProductType.MIS,
      buyQty: 50,
      sellQty: 0,
      netQty: 50,
      buyAvg: 810.00,
      sellAvg: 0.0,
      ltp: 815.20,
      realizedPnl: 0.0,
      unrealizedPnl: 260.00, // (815.20 - 810.00) * 50
      stopLoss: 800.00,
      takeProfit: 830.00,
      leverage: 5.0,
      usedMargin: 8100.0, // (50 * 810) / 5
      openTime: DateTime.now().subtract(const Duration(hours: 1)),
    ));
  }

  // Getters
  List<Order> get orders => List.unmodifiable(_orders);
  List<Order> get pendingOrders => _orders.where((o) =>
    o.status == OrderStatus.DRAFT ||
    o.status == OrderStatus.SUBMITTED ||
    o.status == OrderStatus.OPEN ||
    o.status == OrderStatus.TRIGGER_PENDING
  ).toList();
  List<Order> get executedOrders => _orders.where((o) =>
    o.status == OrderStatus.COMPLETE ||
    o.status == OrderStatus.PARTIALLY_FILLED ||
    o.status == OrderStatus.CANCELLED ||
    o.status == OrderStatus.REJECTED ||
    o.status == OrderStatus.EXPIRED ||
    o.status == OrderStatus.FAILED
  ).toList();
  List<Position> get positions => List.unmodifiable(_positions);
  List<Holding> get holdings => List.unmodifiable(_holdings);
  List<GttOrder> get gtts => List.unmodifiable(_gtts);
  List<LedgerEntry> get ledger => List.unmodifiable(_ledger);
  List<LinkedBankAccount> get linkedBankAccounts => List.unmodifiable(_linkedBankAccounts);
  List<LinkedBankAccount> getLinkedBankAccounts() => linkedBankAccounts;
  List<WalletTransaction> get walletTransactions => List.unmodifiable(_walletTransactions);
  List<TransactionRecord> get unifiedTransactions => List.unmodifiable(_unifiedTransactions);

  Stream<List<TransactionRecord>> get unifiedTransactionsStream =>
      _unifiedTransactionsStreamController.stream;

  List<TransactionRecord> getUnifiedTransactions({
    String? query,
    String? searchQuery,
    TransactionCategory? category,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? fromDate,
    DateTime? toDate,
    String sortBy = 'DATE_DESC',
  }) {
    var list = List<TransactionRecord>.from(_unifiedTransactions);

    final term = (searchQuery ?? query)?.trim().toLowerCase();
    if (term != null && term.isNotEmpty) {
      list = list.where((t) {
        return t.title.toLowerCase().contains(term) ||
            t.narration.toLowerCase().contains(term) ||
            t.id.toLowerCase().contains(term) ||
            (t.orderId != null && t.orderId!.toLowerCase().contains(term)) ||
            (t.instrumentSymbol != null && t.instrumentSymbol!.toLowerCase().contains(term));
      }).toList();
    }

    if (category != null) {
      list = list.where((t) => t.category == category).toList();
    }

    if (status != null && status.toUpperCase() != 'ALL') {
      final st = status.toUpperCase();
      list = list.where((t) => t.status.toUpperCase() == st).toList();
    }

    final start = startDate ?? fromDate;
    if (start != null) {
      final s = DateTime(start.year, start.month, start.day);
      list = list.where((t) => t.timestamp.isAfter(s) || t.timestamp.isAtSameMomentAs(s)).toList();
    }

    final end = endDate ?? toDate;
    if (end != null) {
      final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
      list = list.where((t) => t.timestamp.isBefore(e) || t.timestamp.isAtSameMomentAs(e)).toList();
    }

    switch (sortBy) {
      case 'DATE_ASC':
        list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case 'AMOUNT_DESC':
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'AMOUNT_ASC':
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'ALPHA_ASC':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'ALPHA_DESC':
        list.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'DATE_DESC':
      default:
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
    }

    return list;
  }

  PaginatedResult<TransactionRecord> getPaginatedTransactions({
    int page = 1,
    int pageSize = 15,
    String? query,
    String? searchQuery,
    TransactionCategory? category,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? fromDate,
    DateTime? toDate,
    String sortBy = 'DATE_DESC',
  }) {
    final allFiltered = getUnifiedTransactions(
      query: query,
      searchQuery: searchQuery,
      category: category,
      status: status,
      startDate: startDate,
      endDate: endDate,
      fromDate: fromDate,
      toDate: toDate,
      sortBy: sortBy,
    );

    final totalCount = allFiltered.length;
    final validPage = page < 1 ? 1 : page;
    final startIndex = (validPage - 1) * pageSize;
    if (startIndex >= totalCount) {
      return PaginatedResult(
        items: [],
        totalCount: totalCount,
        page: validPage,
        pageSize: pageSize,
        hasMore: false,
      );
    }

    final endIndex = min(startIndex + pageSize, totalCount);
    final pageItems = allFiltered.sublist(startIndex, endIndex);
    final hasMore = endIndex < totalCount;

    return PaginatedResult(
      items: pageItems,
      totalCount: totalCount,
      page: validPage,
      pageSize: pageSize,
      hasMore: hasMore,
    );
  }

  StatementSummary generateStatementSummary({
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final from = fromDate ?? startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final to = toDate ?? endDate ?? DateTime.now();

    final txns = getUnifiedTransactions(
      startDate: from,
      endDate: to,
      sortBy: 'DATE_ASC',
    );

    double totalCredits = 0.0;
    double totalDebits = 0.0;
    double totalCharges = 0.0;

    for (final t in txns) {
      if (t.isCredit) {
        totalCredits += t.amount;
      } else {
        totalDebits += t.amount;
      }
      totalCharges += t.totalFees;
    }

    final openingBal = _openingEquityBalance;
    final netCashFlow = totalCredits - totalDebits;
    final closingBal = openingBal + netCashFlow;

    return StatementSummary(
      fromDate: from,
      toDate: to,
      openingBalance: openingBal,
      closingBalance: closingBal,
      totalCredits: totalCredits,
      totalDebits: totalDebits,
      totalCharges: totalCharges,
      netCashFlow: netCashFlow,
      totalTransactions: txns.length,
    );
  }

  String generateStatementCsv({
    StatementSummary? summary,
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
  }) {
    final s = summary ??
        generateStatementSummary(
          fromDate: fromDate ?? startDate,
          toDate: toDate ?? endDate,
        );

    final txns = getUnifiedTransactions(
      startDate: s.fromDate,
      endDate: s.toDate,
      category: category,
      sortBy: 'DATE_ASC',
    );

    final buffer = StringBuffer();
    buffer.writeln('ZeroDalali Trading Technologies Pvt Ltd');
    buffer.writeln('ACCOUNT STATEMENT & TRANSACTION LEDGER');
    buffer.writeln('Client ID: 1208160058291244 | Name: Anurag | Demat: CDSL');
    buffer.writeln('Period: ${s.fromDate.day}/${s.fromDate.month}/${s.fromDate.year} to ${s.toDate.day}/${s.toDate.month}/${s.toDate.year}');
    buffer.writeln('Generated On: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    buffer.writeln('SUMMARY OVERVIEW');
    buffer.writeln('Opening Balance,${s.openingBalance.toStringAsFixed(2)}');
    buffer.writeln('Closing Balance,${s.closingBalance.toStringAsFixed(2)}');
    buffer.writeln('Total Credits,${s.totalCredits.toStringAsFixed(2)}');
    buffer.writeln('Total Debits,${s.totalDebits.toStringAsFixed(2)}');
    buffer.writeln('Total Charges & Taxes,${s.totalCharges.toStringAsFixed(2)}');
    buffer.writeln('Net Cash Flow,${s.netCashFlow.toStringAsFixed(2)}');
    buffer.writeln('Total Transactions,${s.totalTransactions}');
    buffer.writeln('');
    buffer.writeln('TRANSACTION DETAILS');
    buffer.writeln('Date,Transaction ID,Order ID,Category,Narration,Instrument,Qty,Price,Fees,Debit,Credit,Balance,Status');

    for (final t in txns) {
      buffer.writeln(t.toCsvRow());
    }

    buffer.writeln('');
    buffer.writeln('AUDIT FOOTER & DECLARATIONS');
    buffer.writeln('This is a computer-generated statement and does not require a physical signature.');
    buffer.writeln('ZeroDalali Broking Ltd • SEBI Reg: INZ000031633 • CDSL DP ID: 12081600');

    return buffer.toString();
  }

  BalanceBreakdown getBalanceBreakdown(Segment segment) {
    return BalanceBreakdown(
      openingBalance: _openingEquityBalance,
      settledCash: _availableEquityMargin,
      unsettledDeliveryCredits: 0.0,
      collateralMargin: 0.0,
      blockedForOrders: _usedEquityMargin,
      withdrawableBalance: max(0.0, _availableEquityMargin),
    );
  }
  
  FundsSummary getFundsSummary(Segment segment) {
    final unrealizedPnl = _positions.fold(0.0, (sum, p) => sum + p.unrealizedPnl);
    return FundsSummary(
      segment: segment,
      availableMargin: _availableEquityMargin,
      usedMargin: _usedEquityMargin,
      openingBalance: _openingEquityBalance,
      unrealizedPnl: unrealizedPnl,
    );
  }

  double get availableEquityMargin => _availableEquityMargin;

  // Streams
  Stream<List<Order>> get ordersStream => _ordersStreamController.stream;
  Stream<List<Position>> get positionsStream => _positionsStreamController.stream;
  Stream<List<Holding>> get holdingsStream => _holdingsStreamController.stream;
  Stream<List<GttOrder>> get gttStream => _gttStreamController.stream;
  Stream<List<WalletTransaction>> get walletTransactionsStream => _walletTransactionsStreamController.stream;

  // ─── Duplicate Submission Protection & Idempotency Index ──────────────────
  // Key: "token|side|qty" → last submission timestamp
  final Map<String, DateTime> _submissionKeys = {};
  final Map<String, String> _idempotentOrderIndex = {}; // idempotencyKey -> orderId

  String _dedupeKey(OrderRequest r) => '${r.instrumentToken}|${r.side.name}|${r.quantity}';

  static bool canTransition(OrderStatus from, OrderStatus to) {
    if (from == to) return true;
    switch (from) {
      case OrderStatus.DRAFT:
        return to == OrderStatus.SUBMITTED || to == OrderStatus.REJECTED || to == OrderStatus.FAILED;
      case OrderStatus.SUBMITTED:
        return to == OrderStatus.OPEN || to == OrderStatus.TRIGGER_PENDING || to == OrderStatus.REJECTED || to == OrderStatus.FAILED;
      case OrderStatus.OPEN:
      case OrderStatus.TRIGGER_PENDING:
        return to == OrderStatus.PARTIALLY_FILLED || to == OrderStatus.COMPLETE || to == OrderStatus.CANCELLED || to == OrderStatus.EXPIRED || to == OrderStatus.FAILED;
      case OrderStatus.PARTIALLY_FILLED:
        return to == OrderStatus.COMPLETE || to == OrderStatus.CANCELLED || to == OrderStatus.EXPIRED;
      case OrderStatus.REJECTED:
        return to == OrderStatus.CANCELLED;
      case OrderStatus.COMPLETE:
      case OrderStatus.CANCELLED:
      case OrderStatus.EXPIRED:
      case OrderStatus.FAILED:
        return false;
    }
  }

  // ─── Margin Calculation & Leverage Schedule ──────────────────────────────────
  double calculateRequiredMargin(OrderRequest request) {
    final instrument = SeedInstruments.findByToken(request.instrumentToken);
    final quote = _ref.read(tickerServiceProvider).getQuote(request.instrumentToken);
    final price = (request.price != null && request.price! > 0)
        ? request.price!
        : quote.ltp;
    final totalExposure = price * request.quantity;

    if (request.product == ProductType.CNC) {
      // 100% margin for cash delivery
      return totalExposure;
    } else if (request.product == ProductType.MIS) {
      // 20% margin (5x leverage) for equity intraday
      final leverage = instrument?.leverageMultiplier ?? 5.0;
      return totalExposure / (leverage > 0 ? leverage : 1.0);
    } else {
      // NRML / Commodity / F&O
      final isCommodity = instrument?.exchange == Exchange.MCX ||
          request.instrumentToken.contains('mcx_');
      if (isCommodity) {
        return totalExposure * 0.05; // 20x for MCX
      }
      final leverage = instrument?.leverageMultiplier ?? 5.0;
      return totalExposure / (leverage > 0 ? leverage : 1.0);
    }
  }

  Order _handleOrderRejection(Order rejOrder) {
    _orders.insert(0, rejOrder);
    _ordersStreamController.add(List.unmodifiable(_orders));
    _dispatchNotification(
      type: NotificationType.orderRejected,
      category: NotificationCategory.orders,
      title: 'Order Rejected: ${rejOrder.request.side.name} ${rejOrder.instrument.symbol}',
      body: rejOrder.rejectionReason ?? 'Order failed pre-flight risk checks',
      deepLink: '/funds',
      metadata: {'orderId': rejOrder.orderId, 'symbol': rejOrder.instrument.symbol, 'reason': rejOrder.rejectionReason},
      isCritical: false,
    );
    return rejOrder;
  }

  // ─── Order Placement ────────────────────────────────────────────────────────
  // Full lifecycle: DRAFT → SUBMITTED → OPEN / TRIGGER_PENDING → COMPLETE/CANCELLED/EXPIRED/FAILED
  Future<Order> placeOrder(OrderRequest request) async {
    // ── 0. Idempotency Key check (safe retry without duplicate order) ───────
    if (request.idempotencyKey != null && _idempotentOrderIndex.containsKey(request.idempotencyKey!)) {
      final existingOrderId = _idempotentOrderIndex[request.idempotencyKey!]!;
      final existingOrder = _orders.firstWhere((o) => o.orderId == existingOrderId);
      return existingOrder;
    }

    // ── 1. Duplicate submission check (same instrument+side+qty within 2s) ──
    final dedupeKey = _dedupeKey(request);
    final lastSub = _submissionKeys[dedupeKey];
    if (lastSub != null && DateTime.now().difference(lastSub).inMilliseconds < 2000) {
      throw Exception('Duplicate order detected. Please wait before submitting the same order again.');
    }
    _submissionKeys[dedupeKey] = DateTime.now();

    final tickerService = _ref.read(tickerServiceProvider);
    final instrument = SeedInstruments.findByToken(request.instrumentToken) ??
        const Instrument(token: 'unknown', symbol: 'UNKNOWN', name: 'Unknown', exchange: Exchange.NSE, type: InstrumentType.EQ);
    
    final currentQuote = tickerService.getQuote(request.instrumentToken);

    final bool isMarket = request.kind == OrderKind.MARKET;
    final bool isStop = request.kind == OrderKind.SL_M;
    final bool isStopLimit = request.kind == OrderKind.SL;
    final bool isLimit = request.kind == OrderKind.LIMIT;
    final bool isIoc = request.validity == Validity.IOC;

    final execPrice = isMarket || isStop
        ? currentQuote.ltp
        : (request.price ?? currentQuote.ltp);

    final charges = ChargesConfig.calculateCharges(
      price: execPrice,
      quantity: request.quantity,
      side: request.side,
      product: request.product,
      instrumentType: instrument.type,
    );

    final orderId = 'ZD-${DateTime.now().millisecondsSinceEpoch}';
    final serverOrderId = 'ZD-SRV-${DateTime.now().millisecondsSinceEpoch}-${_orders.length + 1}';
    final exchangeOrderId = 'NSE-${2000000000 + _orders.length}';
    if (request.idempotencyKey != null) {
      _idempotentOrderIndex[request.idempotencyKey!] = orderId;
    }
    final now = DateTime.now();

    // ── Pre-Flight Risk Control Validations ───────────────────────────────────

    // 1. Suspension Validation
    if (instrument.isSuspended) {
      final rejOrder = Order(
        orderId: orderId,
        exchangeOrderId: exchangeOrderId,
        instrument: instrument,
        request: request,
        status: OrderStatus.REJECTED,
        filledQty: 0,
        averagePrice: 0.0,
        placedAt: now,
        rejectionReason: 'Trading suspended: ${instrument.suspensionReason ?? "Regulatory action"}',
        timeline: [
          OrderEvent(
            status: OrderStatus.REJECTED,
            description: 'Rejected: Trading suspended — ${instrument.suspensionReason ?? "Regulatory action"}',
            at: now,
          ),
        ],
        charges: charges,
      );
      return _handleOrderRejection(rejOrder);
    }

    // 2. Maximum Order Quantity / Exchange Freeze Limit Validation
    if (request.quantity > instrument.freezeQty) {
      final rejOrder = Order(
        orderId: orderId,
        exchangeOrderId: exchangeOrderId,
        instrument: instrument,
        request: request,
        status: OrderStatus.REJECTED,
        filledQty: 0,
        averagePrice: 0.0,
        placedAt: now,
        rejectionReason: 'Order quantity ${request.quantity} exceeds exchange freeze limit of ${instrument.freezeQty} shares.',
        timeline: [
          OrderEvent(
            status: OrderStatus.REJECTED,
            description: 'Rejected: Order quantity exceeds exchange freeze limit (${instrument.freezeQty})',
            at: now,
          ),
        ],
        charges: charges,
      );
      return _handleOrderRejection(rejOrder);
    }

    // 3. Price-Band / Circuit Limit Validation
    final double lowerCircuit = currentQuote.lowerCircuit;
    final double upperCircuit = currentQuote.upperCircuit;
    if ((isLimit || isStopLimit || isStop) && lowerCircuit > 0 && upperCircuit > 0) {
      final checkPrice = request.price ?? request.triggerPrice;
      if (checkPrice != null && (checkPrice < lowerCircuit || checkPrice > upperCircuit)) {
        final rejOrder = Order(
          orderId: orderId,
          exchangeOrderId: exchangeOrderId,
          instrument: instrument,
          request: request,
          status: OrderStatus.REJECTED,
          filledQty: 0,
          averagePrice: 0.0,
          placedAt: now,
          rejectionReason: 'Order price ₹${checkPrice.toStringAsFixed(2)} is outside daily circuit limit [₹${lowerCircuit.toStringAsFixed(2)} - ₹${upperCircuit.toStringAsFixed(2)}].',
          timeline: [
            OrderEvent(
              status: OrderStatus.REJECTED,
              description: 'Rejected: Price outside exchange circuit limits [${lowerCircuit.toStringAsFixed(2)} - ${upperCircuit.toStringAsFixed(2)}]',
              at: now,
            ),
          ],
          charges: charges,
        );
        return _handleOrderRejection(rejOrder);
      }
    }

    // 4. Market Hours Validation (when enforceMarketHours is active)
    if (enforceMarketHours) {
      final exchangeStatus = MarketStatusService.getStatusForExchange(instrument.exchange.name);
      if (exchangeStatus.state == MarketSessionState.closed && request.variety != OrderVariety.AMO) {
        final rejOrder = Order(
          orderId: orderId,
          exchangeOrderId: exchangeOrderId,
          instrument: instrument,
          request: request,
          status: OrderStatus.REJECTED,
          filledQty: 0,
          averagePrice: 0.0,
          placedAt: now,
          rejectionReason: 'Market is closed for ${instrument.exchange.name}. Please place as an After Market Order (AMO).',
          timeline: [
            OrderEvent(
              status: OrderStatus.REJECTED,
              description: 'Rejected: Regular market closed — place as AMO',
              at: now,
            ),
          ],
          charges: charges,
        );
        return _handleOrderRejection(rejOrder);
      }
    }

    // 5. Insufficient Margin Rejection
    final reqMargin = calculateRequiredMargin(request);
    if (request.side == TransactionType.BUY && reqMargin > _availableEquityMargin) {
      final rejOrder = Order(
        orderId: orderId,
        exchangeOrderId: exchangeOrderId,
        instrument: instrument,
        request: request,
        status: OrderStatus.REJECTED,
        filledQty: 0,
        averagePrice: 0.0,
        placedAt: now,
        rejectionReason: 'Insufficient margin. Required: ₹${reqMargin.toStringAsFixed(2)}, Available: ₹${_availableEquityMargin.toStringAsFixed(2)}',
        timeline: [
          OrderEvent(
            status: OrderStatus.REJECTED,
            description: 'Rejected: Insufficient margin (Required: ₹${reqMargin.toStringAsFixed(2)}, Available: ₹${_availableEquityMargin.toStringAsFixed(2)})',
            at: now,
          ),
        ],
        charges: charges,
      );
      return _handleOrderRejection(rejOrder);
    }

    // 6. Active Forced Liquidation / Margin Deficit Block
    if (_availableEquityMargin <= 0 && request.side == TransactionType.BUY) {
      final rejOrder = Order(
        orderId: orderId,
        exchangeOrderId: exchangeOrderId,
        instrument: instrument,
        request: request,
        status: OrderStatus.REJECTED,
        filledQty: 0,
        averagePrice: 0.0,
        placedAt: now,
        rejectionReason: 'Account is in forced liquidation / margin call deficit. New risk prohibited.',
        timeline: [
          OrderEvent(
            status: OrderStatus.REJECTED,
            description: 'Rejected: Margin call deficit active — adding new risk is blocked',
            at: now,
          ),
        ],
        charges: charges,
      );
      return _handleOrderRejection(rejOrder);
    }

    // ── 2. Determine lifecycle states based on order kind ───────────────────
    final OrderStatus activeStatus = (isStop || isStopLimit)
        ? OrderStatus.TRIGGER_PENDING
        : OrderStatus.OPEN;

    // ── 3. DRAFT: Order created locally, passed pre-flight risk checks ──────
    final draftOrder = Order(
      orderId: orderId,
      serverOrderId: serverOrderId,
      exchangeOrderId: exchangeOrderId,
      instrument: instrument,
      request: request,
      status: OrderStatus.DRAFT,
      filledQty: 0,
      averagePrice: 0.0,
      placedAt: now,
      timeline: [
        OrderEvent(
          status: OrderStatus.DRAFT,
          description: 'Order drafted — risk checks passed, awaiting submission to exchange',
          at: now,
        ),
      ],
      auditTrail: [
        OrderAuditEntry(
          timestamp: now,
          fromStatus: OrderStatus.DRAFT,
          toStatus: OrderStatus.DRAFT,
          action: 'ORDER_DRAFTED',
          actorId: 'CLIENT_INGRESS',
          details: 'Initial order validation passed. IdempotencyKey: ${request.idempotencyKey ?? "NONE"}',
        ),
      ],
      charges: charges,
    );

    _orders.insert(0, draftOrder);
    _ordersStreamController.add(List.unmodifiable(_orders));

    // ── 4. SUBMITTED: Sent to exchange, awaiting ACK (~150ms round-trip) ───
    await Future.delayed(const Duration(milliseconds: 150));

    // ── 5. Network Timeout Simulation (when simulateNetworkTimeout is true) ──
    if (simulateNetworkTimeout && _rng.nextInt(100) < 5) {
      _updateOrderStatus(
        orderId,
        OrderStatus.FAILED,
        'Network timeout — order could not reach exchange. Please retry.',
      );
      return _orders.firstWhere((o) => o.orderId == orderId);
    }

    _updateOrderStatus(
      orderId,
      OrderStatus.SUBMITTED,
      'Order submitted to exchange — awaiting acknowledgement (Ref: $exchangeOrderId)',
    );

    _dispatchNotification(
      type: NotificationType.orderSubmitted,
      category: NotificationCategory.orders,
      title: 'Order Submitted: ${request.side.name} ${instrument.symbol}',
      body: '${request.side.name} ${request.quantity} Qty ${instrument.symbol} @ ${request.price != null ? "₹${request.price!.toStringAsFixed(2)}" : "MARKET"} submitted.',
      deepLink: '/history',
      metadata: {'orderId': orderId, 'symbol': instrument.symbol, 'qty': request.quantity, 'price': request.price},
    );

    // ── 6. Exchange ACK → OPEN / TRIGGER_PENDING (~250ms) ──────────────────
    await Future.delayed(const Duration(milliseconds: 250));

    final String ackDescription = (isStop || isStopLimit)
        ? 'Stop order acknowledged — awaiting trigger @ ₹${request.triggerPrice?.toStringAsFixed(2) ?? "-"}'
        : isLimit
            ? 'Limit order active in book @ ₹${request.price?.toStringAsFixed(2) ?? "-"}'
            : 'Market order acknowledged — executing at best price';

    _updateOrderStatus(orderId, activeStatus, ackDescription);

    // ── 7. IOC Expiry: if IOC and not market, expire immediately if no fill ──
    if (isIoc && !isMarket) {
      Future.delayed(const Duration(milliseconds: 300), () {
        final idx = _orders.indexWhere((o) => o.orderId == orderId);
        if (idx != -1 && (_orders[idx].status == OrderStatus.OPEN || _orders[idx].status == OrderStatus.TRIGGER_PENDING)) {
          _updateOrderStatus(orderId, OrderStatus.EXPIRED, 'IOC order expired — not filled immediately');
        }
      });
    }

    // ── 8. Market order auto-fill ────────────────────────────────────────────
    if (isMarket) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _executeOrder(orderId, execPrice, request.quantity);
      });
    } else if (isStop || isStopLimit) {
      // Stop orders: simulate trigger after 3-8 seconds
      final simulatedTriggerDelay = Duration(milliseconds: 3000 + _rng.nextInt(5000));
      Future.delayed(simulatedTriggerDelay, () {
        final triggerQuote = _ref.read(tickerServiceProvider).getQuote(request.instrumentToken);
        final triggerFillPrice = isStop
            ? triggerQuote.ltp
            : (request.price ?? triggerQuote.ltp);
        _triggerStopOrder(orderId, triggerFillPrice, request.quantity);
      });
    }
    // LIMIT + DAY orders stay OPEN until user cancels

    return _orders.firstWhere((o) => o.orderId == orderId);
  }

  // Helper: update order status and append timeline event
  void _updateOrderStatus(String orderId, OrderStatus status, String description) {
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index == -1) return;
    final existing = _orders[index];
    if (!canTransition(existing.status, status)) return;

    final updatedTimeline = List<OrderEvent>.from(existing.timeline)
      ..add(OrderEvent(status: status, description: description, at: DateTime.now()));
    final updatedAudit = List<OrderAuditEntry>.from(existing.auditTrail)
      ..add(OrderAuditEntry(
        timestamp: DateTime.now(),
        fromStatus: existing.status,
        toStatus: status,
        action: 'STATUS_TRANSITION',
        actorId: 'EXCHANGE_OMS',
        details: description,
      ));
    _orders[index] = existing.copyWith(
      status: status,
      timeline: updatedTimeline,
      auditTrail: updatedAudit,
    );
    _ordersStreamController.add(List.unmodifiable(_orders));
  }


  void _triggerStopOrder(String orderId, double fillPrice, int qty) {
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index == -1) return;
    final existing = _orders[index];
    // Only trigger if still in TRIGGER_PENDING state (not already cancelled)
    if (existing.status != OrderStatus.TRIGGER_PENDING) return;

    final updatedTimeline = List<OrderEvent>.from(existing.timeline)
      ..add(OrderEvent(
        status: OrderStatus.OPEN,
        description: 'Trigger hit — order activated @ ₹${fillPrice.toStringAsFixed(2)}',
        at: DateTime.now(),
      ));

    _orders[index] = existing.copyWith(
      status: OrderStatus.OPEN,
      timeline: updatedTimeline,
    );
    _ordersStreamController.add(List.unmodifiable(_orders));

    // Then fill ~400ms later (simulate exchange matching)
    Future.delayed(const Duration(milliseconds: 400), () {
      _executeOrder(orderId, fillPrice, qty);
    });
  }

  void _executeOrder(String orderId, double price, int qty) {
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index == -1) return;

    final existing = _orders[index];
    final bool isPartial = qty < existing.request.quantity;
    final targetStatus = isPartial ? OrderStatus.PARTIALLY_FILLED : OrderStatus.COMPLETE;

    final updatedTimeline = List<OrderEvent>.from(existing.timeline)
      ..add(OrderEvent(
        status: targetStatus,
        description: isPartial
            ? 'Partially filled $qty/${existing.request.quantity} qty @ ₹$price'
            : 'Filled $qty qty @ ₹$price',
        at: DateTime.now(),
      ));

    final updatedAudit = List<OrderAuditEntry>.from(existing.auditTrail)
      ..add(OrderAuditEntry(
        timestamp: DateTime.now(),
        fromStatus: existing.status,
        toStatus: targetStatus,
        action: isPartial ? 'EXECUTION_PARTIAL_FILL' : 'EXECUTION_FULL_FILL',
        actorId: 'MATCHING_ENGINE',
        details: 'Matched $qty shares @ ₹$price',
      ));

    final completedOrder = existing.copyWith(
      status: targetStatus,
      filledQty: qty,
      averagePrice: price,
      timeline: updatedTimeline,
      auditTrail: updatedAudit,
    );

    _orders[index] = completedOrder;
    _ordersStreamController.add(List.unmodifiable(_orders));

    // Update Positions / Holdings / Margin
    _applyFill(completedOrder);

    _dispatchNotification(
      type: isPartial ? NotificationType.orderPartiallyFilled : NotificationType.orderFilled,
      category: NotificationCategory.orders,
      title: isPartial
          ? 'Partial Fill: ${completedOrder.request.side.name} ${completedOrder.instrument.symbol}'
          : 'Order Executed: ${completedOrder.request.side.name} ${completedOrder.instrument.symbol}',
      body: isPartial
          ? '${completedOrder.request.side.name} $qty/${completedOrder.request.quantity} Qty ${completedOrder.instrument.symbol} filled at ₹${price.toStringAsFixed(2)}.'
          : '${completedOrder.request.side.name} $qty Qty ${completedOrder.instrument.symbol} filled at ₹${price.toStringAsFixed(2)}.',
      deepLink: '/history',
      metadata: {'orderId': orderId, 'symbol': completedOrder.instrument.symbol, 'qty': qty, 'price': price},
    );
  }

  void simulatePartialFill(String orderId, int fillQty, double fillPrice) {
    _executeOrder(orderId, fillPrice, fillQty);
  }

  void _applyFill(Order order) {
    final instrument = order.instrument;
    final side = order.request.side;
    final qty = order.filledQty;
    final price = order.averagePrice;
    final product = order.request.product;

    final totalTradeValue = price * qty;

    if (product == ProductType.MIS || product == ProductType.NRML) {
      // Positions
      final posIndex = _positions.indexWhere((p) => p.instrument.token == instrument.token && p.product == product);
      final leverage = (product == ProductType.MIS)
          ? (instrument.leverageMultiplier > 0 ? instrument.leverageMultiplier : 5.0)
          : (instrument.exchange == Exchange.MCX ? 20.0 : 1.0);
      final contractMultiplier = instrument.exchange == Exchange.MCX ? instrument.contractMultiplier : 1.0;

      if (posIndex == -1) {
        final initialMargin = (qty * price * contractMultiplier) / leverage;
        _positions.insert(0, Position(
          id: 'pos_${instrument.token}',
          instrument: instrument,
          product: product,
          buyQty: side == TransactionType.BUY ? qty : 0,
          sellQty: side == TransactionType.SELL ? qty : 0,
          netQty: side == TransactionType.BUY ? qty : -qty,
          buyAvg: side == TransactionType.BUY ? price : 0.0,
          sellAvg: side == TransactionType.SELL ? price : 0.0,
          ltp: price,
          realizedPnl: 0.0,
          unrealizedPnl: 0.0,
          stopLoss: order.request.bracket?.stopLoss,
          takeProfit: order.request.bracket?.target,
          leverage: leverage,
          usedMargin: initialMargin,
          openTime: DateTime.now(),
        ));

        // Deduct initial margin for new position (whether long or short)
        _availableEquityMargin -= initialMargin;
        _usedEquityMargin += initialMargin;
      } else {
        final cur = _positions[posIndex];
        final oldMargin = cur.usedMargin;

        final fillResult = FinancialCalculationService.calculatePositionFill(
          currentNetQty: cur.netQty,
          currentEntryPrice: cur.entryPrice,
          currentRealizedPnl: cur.realizedPnl,
          fillSide: side,
          fillQty: qty,
          fillPrice: price,
          contractMultiplier: contractMultiplier,
        );

        final newBuyQty = cur.buyQty + (side == TransactionType.BUY ? qty : 0);
        final newSellQty = cur.sellQty + (side == TransactionType.SELL ? qty : 0);
        final newMargin = (fillResult.newNetQty.abs() * fillResult.newEntryPrice * contractMultiplier) / leverage;

        _positions[posIndex] = cur.copyWith(
          buyQty: newBuyQty,
          sellQty: newSellQty,
          netQty: fillResult.newNetQty,
          buyAvg: fillResult.newNetQty > 0 ? fillResult.newEntryPrice : cur.buyAvg,
          sellAvg: fillResult.newNetQty < 0 ? fillResult.newEntryPrice : cur.sellAvg,
          usedMargin: newMargin,
          realizedPnl: fillResult.newRealizedPnl,
        );

        // Adjust used margin
        final marginDelta = newMargin - oldMargin;
        _availableEquityMargin -= marginDelta;
        _usedEquityMargin = (_usedEquityMargin + marginDelta).clamp(0.0, double.infinity);

        // Direct P&L realization into cash balance
        _availableEquityMargin += fillResult.realizedPnlDelta;
      }
      _positionsStreamController.add(List.unmodifiable(_positions));
    } else if (product == ProductType.CNC) {
      // CNC modifies holdings
      final holdIndex = _holdings.indexWhere((h) => h.instrument.token == instrument.token);
      if (side == TransactionType.BUY) {
        _availableEquityMargin -= totalTradeValue;
        if (holdIndex == -1) {
          _holdings.insert(0, Holding(
            instrument: instrument,
            quantity: qty,
            averagePrice: price,
            ltp: price,
            closePrice: price,
            firstBuyDate: DateTime.now(),
          ));
        } else {
          final cur = _holdings[holdIndex];
          final totalQty = cur.quantity + qty;
          final newAvg = ((cur.averagePrice * cur.quantity) + (price * qty)) / totalQty;
          _holdings[holdIndex] = cur.copyWith(
            quantity: totalQty,
            averagePrice: newAvg,
          );
        }
      } else {
        // Sell CNC
        _availableEquityMargin += totalTradeValue;
        if (holdIndex != -1) {
          final cur = _holdings[holdIndex];
          final remQty = cur.quantity - qty;
          if (remQty <= 0) {
            _holdings.removeAt(holdIndex);
          } else {
            _holdings[holdIndex] = cur.copyWith(quantity: remQty);
          }
        }
      }
      _holdingsStreamController.add(List.unmodifiable(_holdings));
    }

    // Record in unified transactions
    final charges = order.charges;
    _unifiedTransactions.insert(
      0,
      TransactionRecord(
        id: 'TXN-${order.orderId}',
        orderId: order.orderId,
        category: TransactionCategory.TRADE,
        title: '${side.name} ${instrument.symbol}',
        narration: 'Executed ${side.name} order for $qty shares of ${instrument.name} @ ₹${price.toStringAsFixed(2)}',
        instrumentSymbol: instrument.symbol,
        quantity: qty,
        price: price,
        amount: totalTradeValue,
        isCredit: side == TransactionType.SELL,
        runningBalance: _availableEquityMargin,
        timestamp: order.placedAt,
        status: 'COMPLETE',
        account: 'Equity (${instrument.exchange.name})',
        feeBreakdown: {
          'Brokerage': charges.brokerage,
          'STT': charges.stt,
          'Exchange Charges': charges.exchangeTxnCharge,
          'GST': charges.gst,
          'SEBI Charges': charges.sebiCharges,
          'Stamp Duty': charges.stampDuty,
        },
      ),
    );
    _unifiedTransactionsStreamController.add(List.unmodifiable(_unifiedTransactions));
  }

  Future<void> cancelOrder(String orderId) async {
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index == -1) return;

    final existing = _orders[index];
    if (!canTransition(existing.status, OrderStatus.CANCELLED)) return;

    final updatedTimeline = List<OrderEvent>.from(existing.timeline)
      ..add(OrderEvent(
        status: OrderStatus.CANCELLED,
        description: 'Cancelled by client',
        at: DateTime.now(),
      ));

    final updatedAudit = List<OrderAuditEntry>.from(existing.auditTrail)
      ..add(OrderAuditEntry(
        timestamp: DateTime.now(),
        fromStatus: existing.status,
        toStatus: OrderStatus.CANCELLED,
        action: 'ORDER_CANCELLED_ACK',
        actorId: 'CLIENT_RMS',
        details: 'Cancellation request acknowledged and processed',
      ));

    _orders[index] = existing.copyWith(
      status: OrderStatus.CANCELLED,
      timeline: updatedTimeline,
      auditTrail: updatedAudit,
    );
    _ordersStreamController.add(List.unmodifiable(_orders));

    _dispatchNotification(
      type: NotificationType.orderCancelled,
      category: NotificationCategory.orders,
      title: 'Order Cancelled: ${existing.request.side.name} ${existing.instrument.symbol}',
      body: '${existing.request.side.name} ${existing.request.quantity} Qty ${existing.instrument.symbol} cancelled.',
      deepLink: '/history',
      metadata: {'orderId': orderId, 'symbol': existing.instrument.symbol},
    );
  }

  Future<void> modifyOrder(String orderId, OrderRequest updatedReq) async {
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index == -1) return;

    final existing = _orders[index];
    final updatedTimeline = List<OrderEvent>.from(existing.timeline)
      ..add(OrderEvent(
        status: existing.status,
        description: 'Order modified (Price: ${updatedReq.price}, Qty: ${updatedReq.quantity})',
        at: DateTime.now(),
      ));

    final updatedAudit = List<OrderAuditEntry>.from(existing.auditTrail)
      ..add(OrderAuditEntry(
        timestamp: DateTime.now(),
        fromStatus: existing.status,
        toStatus: existing.status,
        action: 'ORDER_MODIFICATION_ACK',
        actorId: 'CLIENT_RMS',
        details: 'Modified parameters acknowledged (Price: ${updatedReq.price}, Qty: ${updatedReq.quantity})',
      ));

    _orders[index] = existing.copyWith(
      request: updatedReq,
      timeline: updatedTimeline,
      auditTrail: updatedAudit,
    );
    _ordersStreamController.add(List.unmodifiable(_orders));
  }

  // ─── Deposit Operations ──────────────────────────────────────────────────
  Future<WalletTransaction> initiateDeposit({
    required double amount,
    required PaymentMethod method,
    String? upiId,
    String? bankName,
    WalletTransactionStatus outcome = WalletTransactionStatus.SUCCESS,
    String? failureReason,
  }) async {
    // Limits check
    if (amount < 100.0) {
      throw Exception('Minimum deposit amount is ₹100.');
    }
    if (method == PaymentMethod.UPI && amount > 200000.0) {
      throw Exception('UPI deposit limit is ₹2,00,000 per transaction by NPCI guidelines.');
    }
    if ((method == PaymentMethod.NET_BANKING || method == PaymentMethod.CARD) && amount > 1000000.0) {
      throw Exception('Maximum deposit limit per transaction is ₹10,00,000.');
    }

    // Duplicate submission protection (within 2 seconds)
    final key = '${method.name}|${amount.toStringAsFixed(2)}';
    final last = _paymentKeys[key];
    if (last != null && DateTime.now().difference(last).inMilliseconds < 2000) {
      throw Exception('Duplicate deposit submission detected. Please wait a moment.');
    }
    _paymentKeys[key] = DateTime.now();

    final now = DateTime.now();
    final refId = 'ZD-PAY-${now.millisecondsSinceEpoch.toString().substring(5)}';
    final id = 'wt_dep_${now.millisecondsSinceEpoch}';

    final txn = WalletTransaction(
      id: id,
      referenceId: refId,
      type: WalletTransactionType.DEPOSIT,
      amount: amount,
      status: outcome,
      method: method,
      upiId: upiId ?? (method == PaymentMethod.UPI ? 'user@upi' : null),
      bankAccount: bankName ?? (method == PaymentMethod.NET_BANKING ? 'HDFC Bank Ltd' : null),
      createdAt: now,
      updatedAt: now,
      failureReason: outcome == WalletTransactionStatus.FAILED
          ? (failureReason ?? 'Bank server timed out or payment declined')
          : null,
    );

    if (outcome == WalletTransactionStatus.SUCCESS) {
      _availableEquityMargin += amount;
      _ledger.insert(
        0,
        LedgerEntry(
          id: _uuid.v4(),
          date: now,
          narration: 'Deposit via ${method.name} (Ref: $refId)',
          credit: amount,
          debit: 0.0,
          runningBalance: _availableEquityMargin,
        ),
      );
    }

    _walletTransactions.insert(0, txn);
    _walletTransactionsStreamController.add(List.unmodifiable(_walletTransactions));

    // Record in unified transactions
    _unifiedTransactions.insert(
      0,
      TransactionRecord(
        id: refId,
        orderId: null,
        category: TransactionCategory.DEPOSIT,
        title: 'Deposit via ${method.name.replaceAll('_', ' ')}',
        narration: 'Deposit of ₹${amount.toStringAsFixed(2)} via ${method.name} ($refId)',
        amount: amount,
        isCredit: true,
        runningBalance: _availableEquityMargin,
        timestamp: now,
        status: outcome.name,
        account: 'Bank A/C',
      ),
    );
    _unifiedTransactionsStreamController.add(List.unmodifiable(_unifiedTransactions));

    _dispatchNotification(
      type: outcome == WalletTransactionStatus.SUCCESS
          ? NotificationType.depositSuccess
          : (outcome == WalletTransactionStatus.PENDING ? NotificationType.depositPending : NotificationType.depositFailed),
      category: NotificationCategory.funds,
      title: outcome == WalletTransactionStatus.SUCCESS ? 'Deposit Successful' : 'Deposit Update',
      body: outcome == WalletTransactionStatus.SUCCESS
          ? '₹${amount.toStringAsFixed(2)} credited to your trading margin via ${method.name}.'
          : 'Deposit of ₹${amount.toStringAsFixed(2)} is ${outcome.name.toLowerCase()}.',
      deepLink: '/funds',
      metadata: {'amount': amount, 'method': method.name, 'refId': refId},
    );

    return txn;
  }

  // ─── Withdrawal Operations ───────────────────────────────────────────────
  Future<WalletTransaction> requestWithdrawal({
    required double amount,
    required String destination,
    bool isUpi = false,
    String otp = '1234',
  }) async {
    if (amount < 100.0) {
      throw Exception('Minimum withdrawal amount is ₹100.');
    }
    if (amount > _availableEquityMargin) {
      throw Exception('Withdrawal amount ₹${amount.toStringAsFixed(2)} exceeds available balance of ₹${_availableEquityMargin.toStringAsFixed(2)}.');
    }
    if (otp != '1234') {
      throw Exception('Invalid 2FA OTP entered.');
    }

    final now = DateTime.now();
    final refId = 'ZD-WTH-${now.millisecondsSinceEpoch.toString().substring(5)}';
    final id = 'wt_wth_${now.millisecondsSinceEpoch}';

    // Deduct margin immediately to prevent double spending
    _availableEquityMargin -= amount;

    final txn = WalletTransaction(
      id: id,
      referenceId: refId,
      type: WalletTransactionType.WITHDRAWAL,
      amount: amount,
      status: WalletTransactionStatus.PENDING,
      method: isUpi ? PaymentMethod.UPI : PaymentMethod.NET_BANKING,
      bankAccount: isUpi ? null : destination,
      upiId: isUpi ? destination : null,
      createdAt: now,
      updatedAt: now,
    );

    _ledger.insert(
      0,
      LedgerEntry(
        id: _uuid.v4(),
        date: now,
        narration: 'Payout requested to $destination (Ref: $refId)',
        credit: 0.0,
        debit: amount,
        runningBalance: _availableEquityMargin,
      ),
    );

    _walletTransactions.insert(0, txn);
    _walletTransactionsStreamController.add(List.unmodifiable(_walletTransactions));

    // Record in unified transactions
    _unifiedTransactions.insert(
      0,
      TransactionRecord(
        id: refId,
        orderId: null,
        category: TransactionCategory.WITHDRAWAL,
        title: 'Payout to $destination',
        narration: 'Payout request of ₹${amount.toStringAsFixed(2)} to $destination ($refId)',
        amount: amount,
        isCredit: false,
        runningBalance: _availableEquityMargin,
        timestamp: now,
        status: WalletTransactionStatus.PENDING.name,
        account: isUpi ? 'UPI VPA' : 'Bank A/C',
      ),
    );
    _unifiedTransactionsStreamController.add(List.unmodifiable(_unifiedTransactions));

    _dispatchNotification(
      type: NotificationType.withdrawalInitiated,
      category: NotificationCategory.funds,
      title: 'Payout Request Initiated',
      body: 'Withdrawal of ₹${amount.toStringAsFixed(2)} initiated to $destination.',
      deepLink: '/funds',
      metadata: {'amount': amount, 'destination': destination, 'refId': refId},
    );

    return txn;
  }

  Future<void> cancelWithdrawal(String transactionId) async {
    final index = _walletTransactions.indexWhere(
      (t) => t.id == transactionId || t.referenceId == transactionId,
    );
    if (index == -1) {
      throw Exception('Withdrawal transaction not found.');
    }

    final txn = _walletTransactions[index];
    if (txn.type != WalletTransactionType.WITHDRAWAL) {
      throw Exception('Transaction is not a withdrawal.');
    }
    if (txn.status != WalletTransactionStatus.PENDING) {
      throw Exception('Only pending withdrawals can be cancelled.');
    }

    // Restore available margin
    _availableEquityMargin += txn.amount;
    final now = DateTime.now();

    _walletTransactions[index] = txn.copyWith(
      status: WalletTransactionStatus.CANCELLED,
      updatedAt: now,
    );

    _ledger.insert(
      0,
      LedgerEntry(
        id: _uuid.v4(),
        date: now,
        narration: 'Payout cancelled & margin restored (Ref: ${txn.referenceId})',
        credit: txn.amount,
        debit: 0.0,
        runningBalance: _availableEquityMargin,
      ),
    );

    _walletTransactionsStreamController.add(List.unmodifiable(_walletTransactions));

    // Update in unified transactions
    final uIdx = _unifiedTransactions.indexWhere((t) => t.id == txn.referenceId || t.id == txn.id);
    if (uIdx != -1) {
      _unifiedTransactions[uIdx] = _unifiedTransactions[uIdx].copyWith(
        status: 'CANCELLED',
        runningBalance: _availableEquityMargin,
      );
      _unifiedTransactionsStreamController.add(List.unmodifiable(_unifiedTransactions));
    }

    _dispatchNotification(
      type: NotificationType.withdrawalFailed,
      category: NotificationCategory.funds,
      title: 'Withdrawal Cancelled',
      body: 'Payout of ₹${txn.amount.toStringAsFixed(2)} was cancelled and funds restored to margin.',
      deepLink: '/funds',
      metadata: {'amount': txn.amount, 'refId': txn.referenceId},
    );
  }

  // Funds Add/Withdraw Compatibility Wrappers
  Future<void> addFunds(double amount, PaymentMethod method) async {
    await initiateDeposit(amount: amount, method: method);
  }

  Future<void> withdrawFunds(double amount, String bankAccount) async {
    await requestWithdrawal(amount: amount, destination: bankAccount);
  }

  // GTT
  Future<GttOrder> createGtt(GttRequest req) async {
    final instrument = SeedInstruments.findByToken(req.instrumentToken) ??
        const Instrument(token: 'unknown', symbol: 'UNKNOWN', name: 'Unknown', exchange: Exchange.NSE, type: InstrumentType.EQ);
    final gtt = GttOrder(
      id: 'GTT-${DateTime.now().millisecondsSinceEpoch}',
      instrument: instrument,
      request: req,
      status: GttStatus.ACTIVE,
      createdAt: DateTime.now(),
    );
    _gtts.insert(0, gtt);
    _gttStreamController.add(List.unmodifiable(_gtts));
    return gtt;
  }

  Future<void> deleteGtt(String id) async {
    _gtts.removeWhere((g) => g.id == id);
    _gttStreamController.add(List.unmodifiable(_gtts));
  }

  // Position Management (Modify SL/TP, Full & Partial Close)
  void modifyPositionSlTp(String positionId, {double? stopLoss, double? takeProfit}) {
    final index = _positions.indexWhere((p) => p.id == positionId);
    if (index != -1) {
      _positions[index] = _positions[index].copyWith(
        stopLoss: stopLoss,
        takeProfit: takeProfit,
      );
      _positionsStreamController.add(List.unmodifiable(_positions));
    }
  }

  Future<Order> closePosition(String positionId, {int? quantity}) async {
    final pos = _positions.firstWhere(
      (p) => p.id == positionId,
      orElse: () => throw Exception('Position not found'),
    );
    final closeQty = (quantity != null && quantity > 0 && quantity <= pos.netQty.abs())
        ? quantity
        : pos.netQty.abs();
    final exitSide = pos.isLong ? TransactionType.SELL : TransactionType.BUY;

    return placeOrder(OrderRequest(
      instrumentToken: pos.instrument.token,
      side: exitSide,
      product: pos.product,
      kind: OrderKind.MARKET,
      quantity: closeQty,
    ));
  }

  // ─── RMS Forced Liquidation Engine ──────────────────────────────────────────
  Future<List<Order>> triggerRmsLiquidation() async {
    final funds = getFundsSummary(Segment.EQUITY);
    if (!funds.isForcedLiquidation && funds.marginLevel >= 100.0) {
      return [];
    }

    final openPositions = _positions.where((p) => !p.isClosed).toList();
    if (openPositions.isEmpty) return [];

    // Prioritize liquidating the highest unrealized loss positions first
    openPositions.sort((a, b) => a.unrealizedPnl.compareTo(b.unrealizedPnl));

    final liquidated = <Order>[];
    for (final pos in openPositions) {
      final exitOrder = await closePosition(pos.id);
      liquidated.add(exitOrder);
      if (getFundsSummary(Segment.EQUITY).marginLevel >= 100.0 && _availableEquityMargin > 0) {
        break;
      }
    }

    if (liquidated.isNotEmpty) {
      _dispatchNotification(
        type: NotificationType.liquidationWarning,
        category: NotificationCategory.riskMargin,
        title: 'RMS Forced Liquidation Executed',
        body: 'Account margin deficit triggered auto square-off of ${liquidated.length} open position(s).',
        deepLink: '/funds',
        metadata: {'liquidatedOrders': liquidated.map((o) => o.orderId).toList()},
        isCritical: true,
      );
    }

    return liquidated;
  }
}

final orderSimulationEngineProvider = Provider<OrderSimulationEngine>((ref) {
  return OrderSimulationEngine(ref);
});

final ordersListProvider = StreamProvider<List<Order>>((ref) {
  final engine = ref.watch(orderSimulationEngineProvider);
  return engine.ordersStream;
});

final positionsListProvider = StreamProvider<List<Position>>((ref) {
  final engine = ref.watch(orderSimulationEngineProvider);
  return engine.positionsStream;
});

final holdingsListProvider = StreamProvider<List<Holding>>((ref) {
  final engine = ref.watch(orderSimulationEngineProvider);
  return engine.holdingsStream;
});

final gttsListProvider = StreamProvider<List<GttOrder>>((ref) {
  final engine = ref.watch(orderSimulationEngineProvider);
  return engine.gttStream;
});

final walletTransactionsListProvider = StreamProvider<List<WalletTransaction>>((ref) {
  final engine = ref.watch(orderSimulationEngineProvider);
  return engine.walletTransactionsStream;
});

final unifiedTransactionsListProvider = StreamProvider<List<TransactionRecord>>((ref) {
  final engine = ref.watch(orderSimulationEngineProvider);
  return engine.unifiedTransactionsStream;
});

