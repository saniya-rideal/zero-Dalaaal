import 'enums.dart';

class IpoListing {
  final String id;
  final String companyName;
  final String symbol;
  final DateTime openDate;
  final DateTime closeDate;
  final double priceBandLow;
  final double priceBandHigh;
  final int lotSize;
  final double gmp; // Grey market premium
  final IpoStatus status;
  final String description;

  const IpoListing({
    required this.id,
    required this.companyName,
    required this.symbol,
    required this.openDate,
    required this.closeDate,
    required this.priceBandLow,
    required this.priceBandHigh,
    required this.lotSize,
    this.gmp = 0.0,
    required this.status,
    this.description = '',
  });

  double get minInvestment => lotSize * priceBandHigh;

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyName': companyName,
    'symbol': symbol,
    'openDate': openDate.toIso8601String(),
    'closeDate': closeDate.toIso8601String(),
    'priceBandLow': priceBandLow,
    'priceBandHigh': priceBandHigh,
    'lotSize': lotSize,
    'gmp': gmp,
    'status': status.name,
    'description': description,
  };

  factory IpoListing.fromJson(Map<String, dynamic> json) => IpoListing(
    id: json['id'] as String,
    companyName: json['companyName'] as String,
    symbol: json['symbol'] as String,
    openDate: DateTime.parse(json['openDate'] as String),
    closeDate: DateTime.parse(json['closeDate'] as String),
    priceBandLow: (json['priceBandLow'] as num).toDouble(),
    priceBandHigh: (json['priceBandHigh'] as num).toDouble(),
    lotSize: (json['lotSize'] as num).toInt(),
    gmp: (json['gmp'] as num?)?.toDouble() ?? 0.0,
    status: IpoStatus.values.byName(json['status'] as String),
    description: json['description'] as String? ?? '',
  );
}

enum ApplicationStatus { APPLIED, ALLOTTED, NOT_ALLOTTED }

class IpoApplicationRequest {
  final String ipoId;
  final String upiId;
  final int lots;
  final double price;
  final bool isCutoff;

  const IpoApplicationRequest({
    required this.ipoId,
    required this.upiId,
    required this.lots,
    required this.price,
    this.isCutoff = true,
  });
}

class IpoApplication {
  final String id;
  final IpoListing ipo;
  final String upiId;
  final int lots;
  final double amount;
  final ApplicationStatus status;
  final DateTime appliedAt;

  const IpoApplication({
    required this.id,
    required this.ipo,
    required this.upiId,
    required this.lots,
    required this.amount,
    required this.status,
    required this.appliedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'ipo': ipo.toJson(),
    'upiId': upiId,
    'lots': lots,
    'amount': amount,
    'status': status.name,
    'appliedAt': appliedAt.toIso8601String(),
  };

  factory IpoApplication.fromJson(Map<String, dynamic> json) => IpoApplication(
    id: json['id'] as String,
    ipo: IpoListing.fromJson(json['ipo'] as Map<String, dynamic>),
    upiId: json['upiId'] as String,
    lots: (json['lots'] as num).toInt(),
    amount: (json['amount'] as num).toDouble(),
    status: ApplicationStatus.values.byName(json['status'] as String),
    appliedAt: DateTime.parse(json['appliedAt'] as String),
  );
}
