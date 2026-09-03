import 'enums.dart';
import 'instrument.dart';

class Sip {
  final String id;
  final Instrument instrument;
  final double amount;
  final SipFrequency frequency;
  final DateTime startDate;
  final int totalInstallments;
  final int completedInstallments;
  final SipStatus status;

  const Sip({
    required this.id,
    required this.instrument,
    required this.amount,
    required this.frequency,
    required this.startDate,
    required this.totalInstallments,
    this.completedInstallments = 0,
    this.status = SipStatus.ACTIVE,
  });

  Sip copyWith({
    String? id,
    Instrument? instrument,
    double? amount,
    SipFrequency? frequency,
    DateTime? startDate,
    int? totalInstallments,
    int? completedInstallments,
    SipStatus? status,
  }) {
    return Sip(
      id: id ?? this.id,
      instrument: instrument ?? this.instrument,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      completedInstallments: completedInstallments ?? this.completedInstallments,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'instrument': instrument.toJson(),
    'amount': amount,
    'frequency': frequency.name,
    'startDate': startDate.toIso8601String(),
    'totalInstallments': totalInstallments,
    'completedInstallments': completedInstallments,
    'status': status.name,
  };

  factory Sip.fromJson(Map<String, dynamic> json) => Sip(
    id: json['id'] as String,
    instrument: Instrument.fromJson(json['instrument'] as Map<String, dynamic>),
    amount: (json['amount'] as num).toDouble(),
    frequency: SipFrequency.values.byName(json['frequency'] as String),
    startDate: DateTime.parse(json['startDate'] as String),
    totalInstallments: (json['totalInstallments'] as num).toInt(),
    completedInstallments: (json['completedInstallments'] as num?)?.toInt() ?? 0,
    status: SipStatus.values.byName(json['status'] as String),
  );
}

class SipRequest {
  final String instrumentToken;
  final double amount;
  final SipFrequency frequency;
  final DateTime startDate;
  final int totalInstallments;

  const SipRequest({
    required this.instrumentToken,
    required this.amount,
    required this.frequency,
    required this.startDate,
    required this.totalInstallments,
  });
}
