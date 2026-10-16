class LegalDocItem {
  final String id;
  final String title;
  final String content;

  const LegalDocItem({
    required this.id,
    required this.title,
    required this.content,
  });
}

class LegalDocuments {
  static const termsAndConditions = LegalDocItem(
    id: 'terms_and_conditions',
    title: 'Terms & Conditions',
    content: 'Zero Dalali Securities terms and conditions of brokerage services...',
  );

  static const privacyPolicy = LegalDocItem(
    id: 'privacy_policy',
    title: 'Privacy Policy',
    content:
        'Zero Dalali Privacy Policy. 256-BIT ENCRYPTION. BIOMETRIC & PIN DATA INVARIANT: evaluated entirely on-device; does NOT store your device fingerprint. DATA WE COLLECT: PAN, Aadhaar offline XML/e-KYC. STATUTORY RETENTION UNDER PMLA: 5 years. PERMISSIONS & ANALYTICS DATA PROTECTION: zero sensitive PII, masks PAN and bank account numbers.',
  );

  static const riskDisclosure = LegalDocItem(
    id: 'risk_disclosure',
    title: 'Risk Disclosure Document',
    content:
        'MANDATORY RISK DISCLOSURE on Derivatives. 9 out of 10 individual traders in equity F&O segment incurred net losses averaging ₹50,000. Technical & Operational Risks: System errors, exchange matching engine latency, internet/telecom connectivity loss, server downtime, and delayed price feeds. Zero provides no investment advice, makes no profit guarantees.',
  );

  static const tariffSchedule = LegalDocItem(
    id: 'tariff_schedule',
    title: 'Tariff & Brokerage Charges',
    content:
        'Equity Delivery (CNC): ₹0 brokerage. Equity Intraday & F&O: Flat ₹20 per executed order. Statutory taxes: Securities Transaction Tax (STT), GST, stamp duty.',
  );

  static const regulatoryDisclosures = LegalDocItem(
    id: 'regulatory_disclosures',
    title: 'Regulatory Disclosures',
    content:
        'Zero Dalali Securities is a SEBI Registered Broker (INZ000000000). Member of NSE, BSE, MCX.',
  );

  static const accountDeletionPolicy = LegalDocItem(
    id: 'account_deletion_policy',
    title: 'Account Deletion Policy',
    content:
        'Account closure and statutory 5-YEAR DATA RETENTION under PMLA guidelines.',
  );

  static const clientFundsSegregation = LegalDocItem(
    id: 'client_funds_segregation',
    title: 'Client Funds Segregation Policy',
    content:
        '100% UPSTREAMING to clearing corporation. ZERO PROPRIETARY COMMINGLING.',
  );

  static const amlCftPolicy = LegalDocItem(
    id: 'aml_cft_policy',
    title: 'AML & CFT Policy',
    content:
        'Reporting of suspicious transactions to FIU-IND for transactions exceeding ₹10,00,000.',
  );

  static const bcpDrPolicy = LegalDocItem(
    id: 'bcp_dr_policy',
    title: 'BCP & DR Policy',
    content:
        'Business Continuity and Disaster Recovery replication across data centers.',
  );

  static const marketDataLicensing = LegalDocItem(
    id: 'market_data_licensing',
    title: 'Market Data Licensing',
    content:
        'Real-time broadcast licensing agreements with NSE and BSE.',
  );

  static const all = [
    termsAndConditions,
    privacyPolicy,
    riskDisclosure,
    tariffSchedule,
    regulatoryDisclosures,
    accountDeletionPolicy,
    clientFundsSegregation,
    amlCftPolicy,
    bcpDrPolicy,
    marketDataLicensing,
  ];
}
