enum TransactionCategory {
  TRADE,
  DEPOSIT,
  WITHDRAWAL,
  FEE_CHARGE,
  DIVIDEND,
  TRANSFER,
}

class TransactionRecord {
  final String id;
  final String? orderId;
  final TransactionCategory category;
  final String title;
  final String narration;
  final String? instrumentSymbol;
  final int? quantity;
  final double? price;
  final double amount;
  final bool isCredit;
  final double runningBalance;
  final DateTime timestamp;
  final String status;
  final String account;
  final Map<String, double>? feeBreakdown;

  const TransactionRecord({
    required this.id,
    this.orderId,
    required this.category,
    required this.title,
    required this.narration,
    this.instrumentSymbol,
    this.quantity,
    this.price,
    required this.amount,
    required this.isCredit,
    required this.runningBalance,
    required this.timestamp,
    required this.status,
    required this.account,
    this.feeBreakdown,
  });

  bool get isTrade => category == TransactionCategory.TRADE;
  bool get isDeposit => category == TransactionCategory.DEPOSIT;
  bool get isWithdrawal => category == TransactionCategory.WITHDRAWAL;
  bool get isFee => category == TransactionCategory.FEE_CHARGE;
  bool get isDividend => category == TransactionCategory.DIVIDEND;

  double get totalFees {
    if (feeBreakdown == null || feeBreakdown!.isEmpty) return 0.0;
    return feeBreakdown!.values.fold(0.0, (sum, f) => sum + f);
  }

  TransactionRecord copyWith({
    String? id,
    String? orderId,
    TransactionCategory? category,
    String? title,
    String? narration,
    String? instrumentSymbol,
    int? quantity,
    double? price,
    double? amount,
    bool? isCredit,
    double? runningBalance,
    DateTime? timestamp,
    String? status,
    String? account,
    Map<String, double>? feeBreakdown,
  }) {
    return TransactionRecord(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      category: category ?? this.category,
      title: title ?? this.title,
      narration: narration ?? this.narration,
      instrumentSymbol: instrumentSymbol ?? this.instrumentSymbol,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      amount: amount ?? this.amount,
      isCredit: isCredit ?? this.isCredit,
      runningBalance: runningBalance ?? this.runningBalance,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      account: account ?? this.account,
      feeBreakdown: feeBreakdown ?? this.feeBreakdown,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'category': category.name,
    'title': title,
    'narration': narration,
    'instrumentSymbol': instrumentSymbol,
    'quantity': quantity,
    'price': price,
    'amount': amount,
    'isCredit': isCredit,
    'runningBalance': runningBalance,
    'timestamp': timestamp.toIso8601String(),
    'status': status,
    'account': account,
    'feeBreakdown': feeBreakdown,
  };

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] ?? json['category'] ?? 'TRANSFER').toString().toUpperCase();
    TransactionCategory cat = TransactionCategory.TRANSFER;
    bool isCredit = false;

    if (typeStr.contains('DEPOSIT') || typeStr.contains('BONUS') || typeStr.contains('PROFIT')) {
      cat = typeStr.contains('PROFIT') ? TransactionCategory.TRADE : TransactionCategory.DEPOSIT;
      isCredit = true;
    } else if (typeStr.contains('WITHDRAW')) {
      cat = TransactionCategory.WITHDRAWAL;
      isCredit = false;
    } else if (typeStr.contains('LOSS') || typeStr.contains('TRADE')) {
      cat = TransactionCategory.TRADE;
      isCredit = false;
    } else if (typeStr.contains('FEE')) {
      cat = TransactionCategory.FEE_CHARGE;
      isCredit = false;
    }

    if (json['isCredit'] != null) {
      isCredit = json['isCredit'] == true;
    }

    final amt = (json['amount'] as num?)?.toDouble().abs() ?? 0.0;
    final bal = (json['runningBalance'] ?? json['balance'] as num?)?.toDouble() ?? 0.0;
    final narr = (json['narration'] ?? json['description'] ?? json['title'] ?? '').toString();
    final title = (json['title'] ?? json['type'] ?? cat.name).toString();

    return TransactionRecord(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      orderId: json['orderId']?.toString(),
      category: cat,
      title: title,
      narration: narr,
      instrumentSymbol: json['instrumentSymbol']?.toString() ?? json['symbol']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toDouble(),
      amount: amt,
      isCredit: isCredit,
      runningBalance: bal,
      timestamp: DateTime.tryParse((json['timestamp'] ?? json['createdAt'] ?? json['date'] ?? '').toString()) ?? DateTime.now(),
      status: (json['status'] ?? 'COMPLETED').toString(),
      account: (json['account'] ?? 'Trading Ledger').toString(),
      feeBreakdown: (json['feeBreakdown'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
    );
  }

  /// Formats row for CSV statement export
  String toCsvRow() {
    final dateStr = timestamp.toIso8601String().split('T').first;
    final timeStr = timestamp.toIso8601String().split('T').last.substring(0, 8);
    final debitStr = !isCredit ? amount.toStringAsFixed(2) : '0.00';
    final creditStr = isCredit ? amount.toStringAsFixed(2) : '0.00';
    final feeStr = totalFees.toStringAsFixed(2);
    final cleanNarration = narration.replaceAll(',', ';');
    return '$dateStr $timeStr,$id,${orderId ?? ""},${category.name},${instrumentSymbol ?? ""},${quantity ?? ""},${price?.toStringAsFixed(2) ?? ""},$debitStr,$creditStr,${runningBalance.toStringAsFixed(2)},$feeStr,$status,$account,"$cleanNarration"';
  }
}

class StatementSummary {
  final DateTime fromDate;
  final DateTime toDate;
  final double openingBalance;
  final double closingBalance;
  final double totalCredits;
  final double totalDebits;
  final double totalCharges;
  final double netCashFlow;
  final int totalTransactions;

  const StatementSummary({
    required this.fromDate,
    required this.toDate,
    required this.openingBalance,
    required this.closingBalance,
    required this.totalCredits,
    required this.totalDebits,
    required this.totalCharges,
    required this.netCashFlow,
    required this.totalTransactions,
  });
}

class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  int get totalPages => (totalCount / pageSize).ceil();
}
