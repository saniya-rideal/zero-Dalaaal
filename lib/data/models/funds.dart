import 'enums.dart';

enum PaymentMethod { UPI, NET_BANKING, CARD }

class FundsSummary {
  final Segment segment;
  final double availableMargin;
  final double usedMargin;
  final double openingBalance;
  final double payin;
  final double payout;
  final double spanMargin;
  final double exposureMargin;

  const FundsSummary({
    required this.segment,
    required this.availableMargin,
    required this.usedMargin,
    required this.openingBalance,
    this.payin = 0.0,
    this.payout = 0.0,
    this.spanMargin = 0.0,
    this.exposureMargin = 0.0,
  });

  double get totalMargin => availableMargin + usedMargin;

  FundsSummary copyWith({
    Segment? segment,
    double? availableMargin,
    double? usedMargin,
    double? openingBalance,
    double? payin,
    double? payout,
    double? spanMargin,
    double? exposureMargin,
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
