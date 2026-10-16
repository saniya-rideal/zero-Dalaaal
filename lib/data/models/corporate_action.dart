/// Strongly typed model representing market-wide corporate actions (Dividends, Splits, Bonus, Buybacks, Rights).
library;

enum CorporateActionType {
  dividend,
  split,
  bonus,
  buyback,
  rights;

  String get label {
    switch (this) {
      case CorporateActionType.dividend:
        return 'Dividend';
      case CorporateActionType.split:
        return 'Stock Split';
      case CorporateActionType.bonus:
        return 'Bonus Issue';
      case CorporateActionType.buyback:
        return 'Buyback';
      case CorporateActionType.rights:
        return 'Rights Issue';
    }
  }

  String get pluralLabel {
    switch (this) {
      case CorporateActionType.dividend:
        return 'Dividends';
      case CorporateActionType.split:
        return 'Splits';
      case CorporateActionType.bonus:
        return 'Bonus';
      case CorporateActionType.buyback:
        return 'Buybacks';
      case CorporateActionType.rights:
        return 'Rights';
    }
  }

  String get shortCode {
    switch (this) {
      case CorporateActionType.dividend:
        return 'DIV';
      case CorporateActionType.split:
        return 'SPLIT';
      case CorporateActionType.bonus:
        return 'BONUS';
      case CorporateActionType.buyback:
        return 'BUYBACK';
      case CorporateActionType.rights:
        return 'RIGHTS';
    }
  }
}

class CorporateAction {
  final String id;
  final String symbol;
  final String companyName;
  final CorporateActionType actionType;
  final String details;
  final DateTime exDate;
  final DateTime recordDate;
  final DateTime announcementDate;
  final double currentPrice;
  final double? dividendYield; // in percentage e.g. 7.2
  final String? ratio; // e.g. '1:5', '1:1', '1:14'
  final String? remarks;

  const CorporateAction({
    required this.id,
    required this.symbol,
    required this.companyName,
    required this.actionType,
    required this.details,
    required this.exDate,
    required this.recordDate,
    required this.announcementDate,
    required this.currentPrice,
    this.dividendYield,
    this.ratio,
    this.remarks,
  });

  /// Days remaining until the Ex-Date. Negative if past.
  int get daysUntilExDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(exDate.year, exDate.month, exDate.day);
    return target.difference(today).inDays;
  }

  bool get isExDatePassed => daysUntilExDate < 0;

  String get relativeTimeDescription {
    final diff = daysUntilExDate;
    if (diff == 0) return 'Today (Ex-Date)';
    if (diff == 1) return 'Tomorrow';
    if (diff > 1) return 'In $diff days';
    if (diff == -1) return 'Yesterday';
    return '${diff.abs()} days ago';
  }

  CorporateAction copyWith({
    String? id,
    String? symbol,
    String? companyName,
    CorporateActionType? actionType,
    String? details,
    DateTime? exDate,
    DateTime? recordDate,
    DateTime? announcementDate,
    double? currentPrice,
    double? dividendYield,
    String? ratio,
    String? remarks,
  }) {
    return CorporateAction(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      companyName: companyName ?? this.companyName,
      actionType: actionType ?? this.actionType,
      details: details ?? this.details,
      exDate: exDate ?? this.exDate,
      recordDate: recordDate ?? this.recordDate,
      announcementDate: announcementDate ?? this.announcementDate,
      currentPrice: currentPrice ?? this.currentPrice,
      dividendYield: dividendYield ?? this.dividendYield,
      ratio: ratio ?? this.ratio,
      remarks: remarks ?? this.remarks,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'companyName': companyName,
        'actionType': actionType.name,
        'details': details,
        'exDate': exDate.toIso8601String(),
        'recordDate': recordDate.toIso8601String(),
        'announcementDate': announcementDate.toIso8601String(),
        'currentPrice': currentPrice,
        'dividendYield': dividendYield,
        'ratio': ratio,
        'remarks': remarks,
      };

  factory CorporateAction.fromJson(Map<String, dynamic> json) =>
      CorporateAction(
        id: (json['id'] ?? json['_id'] ?? 'ca_${DateTime.now().millisecondsSinceEpoch}').toString(),
        symbol: (json['symbol'] ?? '').toString(),
        companyName: (json['companyName'] ?? json['symbol'] ?? '').toString(),
        actionType: CorporateActionType.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['actionType'] ?? json['type'] ?? '').toString().toLowerCase(),
          orElse: () => CorporateActionType.dividend,
        ),
        details: (json['details'] ?? json['description'] ?? '').toString(),
        exDate: DateTime.tryParse((json['exDate'] ?? '').toString()) ?? DateTime.now(),
        recordDate: DateTime.tryParse((json['recordDate'] ?? '').toString()) ?? DateTime.now(),
        announcementDate: DateTime.tryParse((json['announcementDate'] ?? '').toString()) ?? DateTime.now(),
        currentPrice: (json['currentPrice'] ?? json['price'] as num?)?.toDouble() ?? 0.0,
        dividendYield: (json['dividendYield'] ?? json['yield'] as num?)?.toDouble(),
        ratio: json['ratio']?.toString(),
        remarks: json['remarks']?.toString(),
      );
}
