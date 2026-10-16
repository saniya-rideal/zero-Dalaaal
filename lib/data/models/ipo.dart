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

  factory IpoListing.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] ?? 'CURRENT').toString().toUpperCase();
    IpoStatus stat = IpoStatus.CURRENT;
    if (statusStr == 'UPCOMING') {
      stat = IpoStatus.UPCOMING;
    } else if (statusStr == 'CLOSED') {
      stat = IpoStatus.CLOSED;
    }

    return IpoListing(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      companyName: (json['companyName'] ?? json['name'] ?? '').toString(),
      symbol: (json['symbol'] ?? '').toString(),
      openDate: DateTime.tryParse((json['openDate'] ?? '').toString()) ?? DateTime.now(),
      closeDate: DateTime.tryParse((json['closeDate'] ?? '').toString()) ?? DateTime.now().add(const Duration(days: 3)),
      priceBandLow: (json['priceBandLow'] as num?)?.toDouble() ?? 0.0,
      priceBandHigh: (json['priceBandHigh'] as num?)?.toDouble() ?? 0.0,
      lotSize: (json['lotSize'] as num?)?.toInt() ?? 1,
      gmp: (json['gmp'] as num?)?.toDouble() ?? 0.0,
      status: stat,
      description: (json['description'] ?? '').toString(),
    );
  }
}

enum ApplicationStatus { APPLIED, ALLOTTED, NOT_ALLOTTED, CANCELLED }

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

  factory IpoApplication.fromJson(Map<String, dynamic> json) {
    IpoListing listing;
    if (json['ipo'] is Map<String, dynamic>) {
      listing = IpoListing.fromJson(json['ipo'] as Map<String, dynamic>);
    } else {
      final sym = (json['symbol'] ?? '').toString();
      listing = IpoListing(
        id: (json['ipoId'] ?? json['ipo'] ?? '').toString(),
        companyName: sym,
        symbol: sym,
        openDate: DateTime.now(),
        closeDate: DateTime.now(),
        priceBandLow: 0.0,
        priceBandHigh: (json['bidPrice'] ?? json['price'] as num?)?.toDouble() ?? 0.0,
        lotSize: (json['lots'] as num?)?.toInt() ?? 1,
        status: IpoStatus.CURRENT,
      );
    }

    final statStr = (json['status'] ?? 'APPLIED').toString().toUpperCase();
    ApplicationStatus appStatus = ApplicationStatus.APPLIED;
    if (statStr == 'ALLOTTED') {
      appStatus = ApplicationStatus.ALLOTTED;
    } else if (statStr == 'NOT_ALLOTTED') {
      appStatus = ApplicationStatus.NOT_ALLOTTED;
    } else if (statStr == 'CANCELLED') {
      appStatus = ApplicationStatus.CANCELLED;
    }

    return IpoApplication(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      ipo: listing,
      upiId: (json['upiId'] ?? '').toString(),
      lots: (json['lots'] as num?)?.toInt() ?? 1,
      amount: (json['amount'] ?? json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: appStatus,
      appliedAt: DateTime.tryParse((json['appliedAt'] ?? json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
