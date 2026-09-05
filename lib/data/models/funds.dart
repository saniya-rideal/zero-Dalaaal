import 'enums.dart';

enum PaymentMethod { UPI, NET_BANKING, CARD }

enum MarginRiskLevel {
  NORMAL,
  HIGH_MARGIN,
  MARGIN_CALL,
  FORCED_LIQUIDATION,
}

class FundsSummary {
  final Segment segment;
  final double availableMargin;
  final double usedMargin;
  final double openingBalance;
  final double payin;
  final double payout;
  final double spanMargin;
  final double exposureMargin;
  final double unrealizedPnl;

  const FundsSummary({
    required this.segment,
    required this.availableMargin,
    required this.usedMargin,
    required this.openingBalance,
    this.payin = 0.0,
    this.payout = 0.0,
    this.spanMargin = 0.0,
    this.exposureMargin = 0.0,
    this.unrealizedPnl = 0.0,
  });

  double get totalMargin => availableMargin + usedMargin;

  /// Free margin available for placing new orders
  double get freeMargin => availableMargin;

  /// Current cash balance (Available Cash + Margin Blocked for Orders/Positions)
  double get balance => availableMargin + usedMargin;

  /// Net Liquidation Value / Total Account Equity = Balance + Unrealized P&L
  double get equity => balance + unrealizedPnl;

  /// Margin Level (%) = (Equity / Used Margin) * 100
  /// In standard brokerage risk controls, level < 100% indicates liquidation threat.
  double get marginLevel => usedMargin > 0 ? (equity / usedMargin) * 100 : 999.99;

  /// Percentage of margin currently utilized (0% to 100%+)
  double get marginUtilizationPercent =>
      totalMargin > 0 ? (usedMargin / totalMargin) * 100 : 0.0;

  /// Risk warning level based on regulatory & risk management thresholds
  MarginRiskLevel get riskLevel {
    if ((usedMargin >= totalMargin && totalMargin > 0) ||
        (availableMargin <= 0 && usedMargin > 0) ||
        (usedMargin > 0 && marginLevel < 100.0)) {
      return MarginRiskLevel.FORCED_LIQUIDATION;
    }
    if (marginUtilizationPercent >= 90.0 || (usedMargin > 0 && marginLevel < 110.0)) {
      return MarginRiskLevel.MARGIN_CALL;
    }
    if (marginUtilizationPercent >= 70.0 || (usedMargin > 0 && marginLevel < 130.0)) {
      return MarginRiskLevel.HIGH_MARGIN;
    }
    return MarginRiskLevel.NORMAL;
  }

  bool get isMarginCall => riskLevel == MarginRiskLevel.MARGIN_CALL;
  bool get isForcedLiquidation => riskLevel == MarginRiskLevel.FORCED_LIQUIDATION;

  FundsSummary copyWith({
    Segment? segment,
    double? availableMargin,
    double? usedMargin,
    double? openingBalance,
    double? payin,
    double? payout,
    double? spanMargin,
    double? exposureMargin,
    double? unrealizedPnl,
  }) {
    return FundsSummary(
      segment: segment ?? this.segment,
      availableMargin: availableMargin ?? this.availableMargin,
      usedMargin: usedMargin ?? this.usedMargin,
      openingBalance: openingBalance ?? this.openingBalance,
      payin: payin ?? this.payin,
      payout: payout ?? this.payout,
      spanMargin: spanMargin ?? this.spanMargin,
      exposureMargin: exposureMargin ?? this.exposureMargin,
      unrealizedPnl: unrealizedPnl ?? this.unrealizedPnl,
    );
  }

  Map<String, dynamic> toJson() => {
    'segment': segment.name,
    'availableMargin': availableMargin,
    'usedMargin': usedMargin,
    'openingBalance': openingBalance,
    'payin': payin,
    'payout': payout,
    'spanMargin': spanMargin,
    'exposureMargin': exposureMargin,
    'unrealizedPnl': unrealizedPnl,
  };

  factory FundsSummary.fromJson(Map<String, dynamic> json) => FundsSummary(
    segment: Segment.values.byName(json['segment'] as String),
    availableMargin: (json['availableMargin'] as num).toDouble(),
    usedMargin: (json['usedMargin'] as num).toDouble(),
    openingBalance: (json['openingBalance'] as num).toDouble(),
    payin: (json['payin'] as num?)?.toDouble() ?? 0.0,
    payout: (json['payout'] as num?)?.toDouble() ?? 0.0,
    spanMargin: (json['spanMargin'] as num?)?.toDouble() ?? 0.0,
    exposureMargin: (json['exposureMargin'] as num?)?.toDouble() ?? 0.0,
    unrealizedPnl: (json['unrealizedPnl'] as num?)?.toDouble() ?? 0.0,
  );
}

class LedgerEntry {
  final String id;
  final DateTime date;
  final String narration;
  final double credit;
  final double debit;
  final double runningBalance;

  const LedgerEntry({
    required this.id,
    required this.date,
    required this.narration,
    required this.credit,
    required this.debit,
    required this.runningBalance,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'narration': narration,
    'credit': credit,
    'debit': debit,
    'runningBalance': runningBalance,
  };

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    narration: json['narration'] as String,
    credit: (json['credit'] as num).toDouble(),
    debit: (json['debit'] as num).toDouble(),
    runningBalance: (json['runningBalance'] as num).toDouble(),
  );
}

enum WalletTransactionType {
  DEPOSIT,
  WITHDRAWAL,
}

enum WalletTransactionStatus {
  INITIATED,
  PENDING,
  PROCESSING,
  SUCCESS,
  COMPLETED,
  FAILED,
  CANCELLED,
  REJECTED,
}

class LinkedBankAccount {
  final String id;
  final String bankName;
  final String accountNumberMasked;
  final String ifsc;
  final bool isPrimary;
  final bool isVerified;

  const LinkedBankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumberMasked,
    required this.ifsc,
    this.isPrimary = false,
    this.isVerified = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'bankName': bankName,
    'accountNumberMasked': accountNumberMasked,
    'ifsc': ifsc,
    'isPrimary': isPrimary,
    'isVerified': isVerified,
  };

  factory LinkedBankAccount.fromJson(Map<String, dynamic> json) => LinkedBankAccount(
    id: json['id'] as String,
    bankName: json['bankName'] as String,
    accountNumberMasked: json['accountNumberMasked'] as String,
    ifsc: json['ifsc'] as String,
    isPrimary: json['isPrimary'] as bool? ?? false,
    isVerified: json['isVerified'] as bool? ?? true,
  );
}

class WalletTransaction {
  final String id;
  final String referenceId;
  final WalletTransactionType type;
  final double amount;
  final WalletTransactionStatus status;
  final PaymentMethod method;
  final String? bankAccount;
  final String? upiId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? failureReason;

  const WalletTransaction({
    required this.id,
    required this.referenceId,
    required this.type,
    required this.amount,
    required this.status,
    required this.method,
    this.bankAccount,
    this.upiId,
    required this.createdAt,
    required this.updatedAt,
    this.failureReason,
  });

  bool get isDeposit => type == WalletTransactionType.DEPOSIT;
  bool get isWithdrawal => type == WalletTransactionType.WITHDRAWAL;
  bool get isPending => status == WalletTransactionStatus.PENDING || status == WalletTransactionStatus.INITIATED;
  bool get isSuccess => status == WalletTransactionStatus.SUCCESS || status == WalletTransactionStatus.COMPLETED;
  bool get isFailed => status == WalletTransactionStatus.FAILED || status == WalletTransactionStatus.REJECTED;
  bool get isCancelled => status == WalletTransactionStatus.CANCELLED;

  WalletTransaction copyWith({
    String? id,
    String? referenceId,
    WalletTransactionType? type,
    double? amount,
    WalletTransactionStatus? status,
    PaymentMethod? method,
    String? bankAccount,
    String? upiId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? failureReason,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      referenceId: referenceId ?? this.referenceId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      method: method ?? this.method,
      bankAccount: bankAccount ?? this.bankAccount,
      upiId: upiId ?? this.upiId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'referenceId': referenceId,
    'type': type.name,
    'amount': amount,
    'status': status.name,
    'method': method.name,
    'bankAccount': bankAccount,
    'upiId': upiId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'failureReason': failureReason,
  };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
    id: json['id'] as String,
    referenceId: json['referenceId'] as String,
    type: WalletTransactionType.values.byName(json['type'] as String),
    amount: (json['amount'] as num).toDouble(),
    status: WalletTransactionStatus.values.byName(json['status'] as String),
    method: PaymentMethod.values.byName(json['method'] as String),
    bankAccount: json['bankAccount'] as String?,
    upiId: json['upiId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    failureReason: json['failureReason'] as String?,
  );
}

class BalanceBreakdown {
  final double openingBalance;
  final double settledCash;
  final double unsettledDeliveryCredits;
  final double collateralMargin;
  final double blockedForOrders;
  final double withdrawableBalance;

  const BalanceBreakdown({
    required this.openingBalance,
    required this.settledCash,
    required this.unsettledDeliveryCredits,
    required this.collateralMargin,
    required this.blockedForOrders,
    required this.withdrawableBalance,
  });

  double get totalTradingMargin =>
      settledCash + unsettledDeliveryCredits + collateralMargin - blockedForOrders;
}

