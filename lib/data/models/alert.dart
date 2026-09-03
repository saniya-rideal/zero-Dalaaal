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

  factory PriceAlert.fromJson(Map<String, dynamic> json) => PriceAlert(
    id: json['id'] as String,
    instrumentTokens: (json['instrumentTokens'] as List<dynamic>).map((e) => e as String).toList(),
    instrumentSymbol: json['instrumentSymbol'] as String,
    condition: AlertCondition.values.byName(json['condition'] as String),
    targetValue: (json['targetValue'] as num).toDouble(),
    status: AlertStatus.values.byName(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    triggeredAt: json['triggeredAt'] != null ? DateTime.parse(json['triggeredAt'] as String) : null,
  );
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
