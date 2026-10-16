import 'enums.dart';

class PriceAlert {
  final String id;
  final List<String> instrumentTokens;
  final String instrumentSymbol;
  final AlertCondition condition;
  final double targetValue;
  final AlertStatus status;
  final DateTime createdAt;
  final DateTime? triggeredAt;

  const PriceAlert({
    required this.id,
    required this.instrumentTokens,
    required this.instrumentSymbol,
    required this.condition,
    required this.targetValue,
    this.status = AlertStatus.ACTIVE,
    required this.createdAt,
    this.triggeredAt,
  });

  bool get isActive => status == AlertStatus.ACTIVE;

  PriceAlert copyWith({
    String? id,
    List<String>? instrumentTokens,
    String? instrumentSymbol,
    AlertCondition? condition,
    double? targetValue,
    AlertStatus? status,
    DateTime? createdAt,
    DateTime? triggeredAt,
  }) {
    return PriceAlert(
      id: id ?? this.id,
      instrumentTokens: instrumentTokens ?? this.instrumentTokens,
      instrumentSymbol: instrumentSymbol ?? this.instrumentSymbol,
      condition: condition ?? this.condition,
      targetValue: targetValue ?? this.targetValue,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      triggeredAt: triggeredAt ?? this.triggeredAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'instrumentTokens': instrumentTokens,
    'instrumentSymbol': instrumentSymbol,
    'condition': condition.name,
    'targetValue': targetValue,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'triggeredAt': triggeredAt?.toIso8601String(),
  };

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    final sym = (json['instrumentSymbol'] ?? json['symbol'] ?? '').toString();
    List<String> tokens = [];
    if (json['instrumentTokens'] is List) {
      tokens = (json['instrumentTokens'] as List).map((e) => e.toString()).toList();
    } else if (sym.isNotEmpty) {
      tokens = [sym];
    }

    final condStr = (json['condition'] ?? 'GTE').toString().toUpperCase();
    AlertCondition cond;
    if (condStr.contains('LTE') || condStr.contains('LESS') || condStr.contains('<=')) {
      cond = AlertCondition.LESS_THAN_OR_EQUAL;
    } else {
      cond = AlertCondition.GREATER_THAN_OR_EQUAL;
    }

    final target = (json['targetPrice'] ?? json['targetValue'] ?? json['price'] as num?)?.toDouble() ?? 0.0;

    AlertStatus stat = AlertStatus.ACTIVE;
    if (json['isActive'] == false || json['status'] == 'TRIGGERED' || json['status'] == 'DISABLED') {
      stat = json['status'] == 'TRIGGERED' ? AlertStatus.TRIGGERED : AlertStatus.DISABLED;
    }

    DateTime created = DateTime.now();
    if (json['createdAt'] != null) {
      created = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    }

    DateTime? triggered;
    if (json['triggeredAt'] != null) {
      triggered = DateTime.tryParse(json['triggeredAt'].toString());
    }

    return PriceAlert(
      id: (json['id'] ?? json['_id'] ?? 'al_${DateTime.now().millisecondsSinceEpoch}').toString(),
      instrumentTokens: tokens,
      instrumentSymbol: sym,
      condition: cond,
      targetValue: target,
      status: stat,
      createdAt: created,
      triggeredAt: triggered,
    );
  }
}

class AlertRequest {
  final List<String> instrumentTokens;
  final String instrumentSymbol;
  final AlertCondition condition;
  final double targetValue;

  const AlertRequest({
    required this.instrumentTokens,
    required this.instrumentSymbol,
    required this.condition,
    required this.targetValue,
  });
}
