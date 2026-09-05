class EntityDetails {
  final String entityName;
  final String operatingStructure;
  final String cin;
  final String pan;
  final String gstin;
  final String registeredOffice;
  final String corporateOffice;

  const EntityDetails({
    required this.entityName,
    required this.operatingStructure,
    required this.cin,
    required this.pan,
    required this.gstin,
    required this.registeredOffice,
    required this.corporateOffice,
  });
}

class BrokerLicenses {
  final String sebiBrokerReg;
  final String nseMemberId;
  final String bseMemberId;
  final String mcxMemberId;
  final String cdslDpId;
  final String nsdlDpId;
  final String sebiRaReg;

  const BrokerLicenses({
    required this.sebiBrokerReg,
    required this.nseMemberId,
    required this.bseMemberId,
    required this.mcxMemberId,
    required this.cdslDpId,
    required this.nsdlDpId,
    required this.sebiRaReg,
  });
}

class AmlTransactionAlert {
  final bool isSuspicious;
  final String? alertReason;
  final double amount;
  final bool requiresFiuReport;

  const AmlTransactionAlert({
    required this.isSuspicious,
    this.alertReason,
    required this.amount,
    required this.requiresFiuReport,
  });

  static const clean = AmlTransactionAlert(isSuspicious: false, amount: 0.0, requiresFiuReport: false);
}

class UpstreamingStatus {
  final double totalClientFunds;
  final double upstreamedToClearingCorp;
  final double retainedInBrokerPropAccount;
  final bool isCommingled;
  final bool isCompliant;

  const UpstreamingStatus({
    required this.totalClientFunds,
    required this.upstreamedToClearingCorp,
    required this.retainedInBrokerPropAccount,
    required this.isCommingled,
    required this.isCompliant,
  });
}

class TradeAuditLogEntry {
  final String orderId;
  final String clientCode;
  final DateTime ntpTimestamp;
  final String clientIpAddress;
  final String deviceFingerprint;
  final String macAddress;
  final String geoTag;
  final String exchangeOrderId;

  const TradeAuditLogEntry({
    required this.orderId,
    required this.clientCode,
    required this.ntpTimestamp,
    required this.clientIpAddress,
    required this.deviceFingerprint,
    required this.macAddress,
    required this.geoTag,
    required this.exchangeOrderId,
  });

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'clientCode': clientCode,
    'ntpTimestamp': ntpTimestamp.toIso8601String(),
    'clientIpAddress': clientIpAddress,
    'deviceFingerprint': deviceFingerprint,
    'macAddress': macAddress,
    'geoTag': geoTag,
    'exchangeOrderId': exchangeOrderId,
  };
}

class RealMoneyComplianceService {
  RealMoneyComplianceService._();

  // ─── 1. Legal Entity & Operating Structure ──────────────────────────────────
  static const EntityDetails corporateEntity = EntityDetails(
    entityName: 'Zero Dalali Securities Private Limited',
    operatingStructure: 'Private Limited Brokerage & Depository Participant',
    cin: 'U67120MH2020PTC342819',
    pan: 'AAACZ9821K',
    gstin: '27AAACZ9821K1ZZ',
    registeredOffice: 'Level 14, Tower 2, One International Center, Prabhadevi, Mumbai - 400013, Maharashtra, India',
    corporateOffice: 'Block B, Nesco IT Park, Western Express Highway, Goregaon East, Mumbai - 400063, Maharashtra, India',
  );

  // ─── 2. Permissions & Licenses ──────────────────────────────────────────────
  static const BrokerLicenses licenses = BrokerLicenses(
    sebiBrokerReg: 'INZ000031633',
    nseMemberId: '14288',
    bseMemberId: '6312',
    mcxMemberId: '56820',
    cdslDpId: '12081600',
    nsdlDpId: 'IN300126',
    sebiRaReg: 'INH000008412',
  );

  // ─── 3. Market Data Licensing & Vendor Agreements ───────────────────────────
  static const String marketDataLicenseAgreementRef = 'NSE-MKT-FEED-2026-L2-8921';
  static const String clearingMemberAgreementRef = 'NCL-CM-AGR-M51842';
  static const bool allowsRedistributionWithoutLicense = false;

  // ─── 4. KYC, Identity, Age & Residency ──────────────────────────────────────
  static bool validateEligibility({
    required int age,
    required bool isIndianResident,
    required bool hasValidPan,
    required bool hasAadhaarLinked,
  }) {
    if (age < 18) return false;
    if (!isIndianResident) return false;
    if (!hasValidPan || !hasAadhaarLinked) return false;
    return true;
  }

  // ─── 5. AML & Sanctions/PEP Screening ───────────────────────────────────────
  /// Threshold for mandatory Cash Transaction Report (CTR) / Currency reporting is ₹10,00,000 under PMLA
  static const double pmlaReportingThreshold = 1000000.0;

  static AmlTransactionAlert monitorAmlTransaction({
    required double transactionAmount,
    required bool isPep,
    required bool isSanctionedEntity,
    required int transactionsInLastHour,
  }) {
    if (isSanctionedEntity) {
      return AmlTransactionAlert(
        isSuspicious: true,
        alertReason: 'Entity is flagged on international OFAC/UN sanctions high-risk watch list',
        amount: transactionAmount,
        requiresFiuReport: true,
      );
    }
    if (isPep) {
      return AmlTransactionAlert(
        isSuspicious: true,
        alertReason: 'Politically Exposed Person (PEP) transaction flagged for enhanced due diligence (EDD)',
        amount: transactionAmount,
        requiresFiuReport: false,
      );
    }
    if (transactionAmount >= pmlaReportingThreshold) {
      return AmlTransactionAlert(
        isSuspicious: true,
        alertReason: 'High-value transaction exceeding PMLA ₹10 Lakh statutory threshold (CTR/STR required)',
        amount: transactionAmount,
        requiresFiuReport: true,
      );
    }
    if (transactionsInLastHour > 10 && transactionAmount > 200000.0) {
      return AmlTransactionAlert(
        isSuspicious: true,
        alertReason: 'Possible structuring / rapid layered deposit velocity anomaly detected',
        amount: transactionAmount,
        requiresFiuReport: true,
      );
    }
    return AmlTransactionAlert.clean;
  }

  // ─── 6. Client Fund Segregation & Upstreaming (SEBI Circular) ───────────────
  /// Validates SEBI mandate on Upstreaming of Client Funds to Clearing Corporations.
  /// Retained in broker prop account MUST be 0.0, and zero commingling is permitted.
  static UpstreamingStatus auditClientFundsSegregation({
    required double totalClientFunds,
    required double upstreamedAmount,
    required double brokerPropFundsCommited,
  }) {
    final retainedInProp = (totalClientFunds - upstreamedAmount).clamp(0.0, double.infinity);
    final isCommingled = brokerPropFundsCommited < 0 || retainedInProp > 0;
    final isCompliant = retainedInProp == 0.0 && !isCommingled && upstreamedAmount == totalClientFunds;

    return UpstreamingStatus(
      totalClientFunds: totalClientFunds,
      upstreamedToClearingCorp: upstreamedAmount,
      retainedInBrokerPropAccount: retainedInProp,
      isCommingled: isCommingled,
      isCompliant: isCompliant,
    );
  }

  // ─── 7. Record Retention & Trade Audit Logs ──────────────────────────────────
  static const int pmlaRetentionYears = 5;
  static const int companiesActRetentionYears = 7;

  static TradeAuditLogEntry generateAuditLog({
    required String orderId,
    required String clientCode,
    required String ipAddress,
    required String deviceFingerprint,
    required String macAddress,
    required String geoTag,
    required String exchangeOrderId,
  }) {
    return TradeAuditLogEntry(
      orderId: orderId,
      clientCode: clientCode,
      ntpTimestamp: DateTime.now().toUtc(),
      clientIpAddress: ipAddress,
      deviceFingerprint: deviceFingerprint,
      macAddress: macAddress,
      geoTag: geoTag,
      exchangeOrderId: exchangeOrderId,
    );
  }

  // ─── 8. Privacy, Data Residency & DPDP Act ───────────────────────────────────
  static const String primaryDataCenterLocation = 'Mumbai (CtrlS Tier-IV DC, Maharashtra, India)';
  static const String drDataCenterLocation = 'Hyderabad (Yotta Tier-IV DC, Telangana, India)';
  static const bool isDataStoredExclusivelyInIndia = true;
  static const String dataProtectionLegislation = 'Digital Personal Data Protection (DPDP) Act, 2023';

  // ─── 9. Business Continuity, Incident Response & Penetration Testing ─────────
  static const int recoveryPointObjectiveMinutes = 15; // RPO < 15 mins
  static const int recoveryTimeObjectiveHours = 4; // RTO < 4 hours
  static const int certInMandatoryIncidentReportingHours = 6; // CERT-In 6-hour mandate
  static const String annualVaptAuditor = 'CERT-In Empaneled Cybersecurity Audit Board';
  static const String lastVaptAuditDate = '2026-06-15';
  static const bool isVaptCompliant = true;

  // ─── 10. Responsible Advertising & Leverage Disclosures ──────────────────────
  static const bool allowsGuaranteedReturnClaims = false;
  static const double sebiPeakIntradayMarginMultiplier = 5.0; // Max 5x for equity intraday
  static const double mtfMinimumClientContributionPercent = 20.0; // 20% minimum cash margin
  static const String sebiFoLossWarning = '9 out of 10 individual traders in equity Futures and Options Segment incurred net losses.';
}
