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

  factory Sip.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? '').toString();
    final sym = (json['symbol'] ?? (json['instrument'] is Map ? (json['instrument'] as Map)['symbol'] : '') ?? '').toString();

    Instrument inst;
    if (json['instrument'] is Map<String, dynamic>) {
      inst = Instrument.fromJson(json['instrument'] as Map<String, dynamic>);
    } else {
      inst = Instrument(
        token: sym,
        symbol: sym,
        name: sym,
        exchange: Exchange.NSE,
        segment: 'EQUITY',
        type: InstrumentType.EQ,
        lotSize: 1.0,
        tickSize: 0.05,
      );
    }

    final amt = (json['amount'] as num?)?.toDouble() ?? 0.0;

    final freqStr = (json['frequency'] ?? 'MONTHLY').toString().toUpperCase();
    SipFrequency freq = SipFrequency.MONTHLY;
    if (freqStr == 'DAILY') {
      freq = SipFrequency.DAILY;
    } else if (freqStr == 'WEEKLY') {
      freq = SipFrequency.WEEKLY;
    }

    final start = json['startDate'] != null
        ? (DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now())
        : (json['createdAt'] != null
            ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
            : DateTime.now());

    final total = (json['totalInstallments'] as num?)?.toInt() ?? 12;
    final completed = (json['completedInstallments'] as num?)?.toInt() ?? 0;

    final statusStr = (json['status'] ?? 'ACTIVE').toString().toUpperCase();
    SipStatus st = SipStatus.ACTIVE;
    if (statusStr == 'PAUSED') {
      st = SipStatus.PAUSED;
    } else if (statusStr == 'CANCELLED' || statusStr == 'STOPPED') {
      st = SipStatus.CANCELLED;
    } else if (statusStr == 'COMPLETED') {
      st = SipStatus.COMPLETED;
    }

    return Sip(
      id: id,
      instrument: inst,
      amount: amt,
      frequency: freq,
      startDate: start,
      totalInstallments: total,
      completedInstallments: completed,
      status: st,
    );
  }
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
