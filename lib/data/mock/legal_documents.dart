class LegalDocumentItem {
  final String id;
  final String title;
  final String subtitle;
  final String lastUpdated;
  final String content;

  const LegalDocumentItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.lastUpdated,
    required this.content,
  });
}

class LegalDocuments {
  LegalDocuments._();

  static const LegalDocumentItem termsAndConditions = LegalDocumentItem(
    id: 'terms_conditions',
    title: 'Terms & Conditions of Service',
    subtitle: 'Client Agreement & Platform Terms of Usage',
    lastUpdated: 'August 2026',
    content: '''
1. INTRODUCTION & REGULATORY FRAMEWORK
Welcome to Zero (Zero Dalali Securities Private Limited). By accessing or executing orders on this platform, you agree to comply with and be bound by these Terms and Conditions, all relevant Bye-laws, Rules, and Regulations of the Securities and Exchange Board of India (SEBI), National Stock Exchange of India (NSE), BSE Limited, and Multi Commodity Exchange (MCX).

2. CLIENT REPRESENTATIONS & COVENANTS
The client represents that they are competent to enter into a legally binding contract under the Indian Contract Act, 1872, and have valid KYC documentation registered with a SEBI-recognized KRA. The client agrees not to indulge in fraudulent or unfair trade practices including circular trading, pump-and-dump, insider trading, or spoofing order books.

3. ORDER ROUTING, EXECUTION & PRICE BANDS
Orders submitted through the platform are electronically validated and routed directly to exchange matching engines. Execution prices are subject to market conditions, daily circuit filters, freeze limits, and order queues. Zero shall not be liable for non-execution arising out of exchange downtime, connectivity failures, or circuit band freezes.

4. MARGIN TRADING & RMS AUTO-LIQUIDATION
For Intraday (MIS) and derivative positions, the client must maintain adequate margin at all times. If the account Margin Utilization exceeds 90% or the available margin enters a deficit, the automated Risk Management System (RMS) reserves the right to square off open positions without prior client notice to prevent debit balances. Intraday auto square-off begins daily at 03:20 PM IST.

5. BROKERAGE & CHARGES
Trading on Zero is subject to our published Tariff Schedule: ₹0 brokerage on Equity Delivery (CNC), and flat ₹20 or 0.05% per executed order on Intraday (MIS) and F&O derivatives. Government and statutory taxes including STT/CTT, Exchange Turnover Charges, SEBI Turnover Fees, Stamp Duty, and GST (18%) are debited as per actuals.

6. GOVERNING LAW & DISPUTE RESOLUTION
These terms are governed by the laws of the Republic of India. Any legal dispute shall be subject to the exclusive jurisdiction of the Courts in Mumbai and the Investor Grievance Redressal Mechanism / Arbitration Panels of the respective stock exchanges.
''',
  );

  static const LegalDocumentItem privacyPolicy = LegalDocumentItem(
    id: 'privacy_policy',
    title: 'Privacy Policy & Data Protection',
    subtitle: 'Standards for collection, encryption and processing of financial data',
    lastUpdated: 'August 2026',
    content: '''
1. DATA WE COLLECT
To provide brokerage services, Zero collects personal identification information (PAN, Aadhaar offline XML/e-KYC, address proof), financial records (bank account numbers, cancelled cheques, verified income proofs for derivatives), and device metadata (IP address, operating system, device hardware identifiers, and session timestamps).

2. BIOMETRIC & PIN DATA INVARIANT
Zero does NOT store your device fingerprint, FaceID biometrics, or raw App PIN on any remote server. Biometric verification is evaluated entirely on-device via Android BiometricPrompt and Apple LocalAuthentication secure enclaves.

3. 256-BIT ENCRYPTION & DATA SECURITY
All network communications between your trading terminal and Zero servers are encrypted using TLS 1.3 with AES-256 GCM cryptographic ciphers. Data at rest is encrypted in ISO/IEC 27001 certified Tier-IV data centers located within the territory of India.

4. THIRD-PARTY DISCLOSURE
We do not sell, rent, or trade your personal or transaction data to any third-party marketing entities. Information is shared strictly with regulatory authorities (SEBI, FIU-IND, Income Tax Department, Exchanges, Depositories CDSL/NSDL, and authorized clearing corporations) as mandated by Indian Law.

5. STATUTORY RETENTION UNDER PMLA
Under the Prevention of Money Laundering Act (PMLA), 2002 and SEBI regulations, client identification documents, order books, and trade transaction logs must be retained for a minimum period of 5 years following account closure.

6. PERMISSIONS & ANALYTICS DATA PROTECTION
Zero requests only necessary device permissions (Internet, secure biometric authentication, and storage for statement downloads). Any crash reporting or analytics telemetry collected contains zero sensitive PII, zero credentials, and automatically masks PAN and bank account numbers.
''',
  );

  static const LegalDocumentItem riskDisclosure = LegalDocumentItem(
    id: 'risk_disclosure',
    title: 'SEBI Mandatory Risk Disclosure on Derivatives',
    subtitle: 'Statutory advisory regarding high-risk derivatives trading',
    lastUpdated: 'Circular SEBI/HO/MIRSD/DOP/CIR/P/2023/73',
    content: '''
MANDATORY RISK DISCLOSURE DOCUMENT FOR CAPITAL & DERIVATIVES MARKETS:

• 9 out of 10 individual traders in equity Futures and Options (F&O) segment incurred net losses.
• On an average, loss makers registered net trading loss close to ₹50,000 per financial year.
• Over and above the net trading losses incurred, loss makers expended an additional 28% of net trading losses as transaction costs.
• Those making net trading profits incurred between 15% to 50% of such profits as transaction costs.

KEY RISK FACTORS IN INTRADAY & LEVERAGE TRADING:
1. Amplified Losses: Leverage multiplies both gains and losses. A 5x leverage implies that a 2% adverse market move results in a 10% loss on committed margin.
2. Market Volatility: Prices can fluctuate violently due to geopolitical events, macroeconomic announcements, or liquidity shocks. Stop-loss orders may not execute at the exact stop price under fast market conditions (slippage).
3. Option Buyer Decay: Long option contracts suffer from rapid time decay (Theta). Out-of-the-money options carry an extremely high probability of expiring worthless (100% capital loss).
4. Short Option Unlimited Risk: Writing options entails unlimited downside risk while capping maximum gain to the premium collected.
5. Technical & Operational Risks: Trading involves substantial technical risks. System errors, exchange matching engine latency, internet/telecom connectivity loss, hardware failure, server downtime, and delayed price feeds can impair order placement or execution. Zero provides no investment advice, makes no profit guarantees, and assumes no liability for technical interruptions.
''',
  );

  static const LegalDocumentItem tariffSchedule = LegalDocumentItem(
    id: 'tariff_schedule',
    title: 'Tariff & Statutory Charges Schedule',
    subtitle: 'Transparent breakdown of brokerage and statutory taxes',
    lastUpdated: 'September 2026',
    content: '''
BROKERAGE CHARGES:
• Equity Delivery (CNC): ₹0 (Free forever for lifetime).
• Equity Intraday (MIS): Flat ₹20 or 0.05% (whichever is lower) per executed order.
• Equity Futures: Flat ₹20 or 0.03% (whichever is lower) per executed order.
• Equity Options: Flat ₹20 per executed order.
• Currency & Commodity: Flat ₹20 per executed order.
• Account Opening: ₹0 (Free digital paperless onboarding).
• Annual Maintenance Charges (AMC): ₹0 for Demat basic trading accounts.

STATUTORY & REGULATORY LEVIES (Debited as per actuals):
1. Securities Transaction Tax (STT):
   - Equity Delivery: 0.1% on Buy & Sell.
   - Equity Intraday: 0.025% on Sell only.
   - Futures: 0.02% on Sell only.
   - Options: 0.1% on Sell value (premium) & 0.125% on exercised contracts.
2. Exchange Turnover Charges:
   - NSE Cash: 0.00297% | BSE Cash: 0.00375%
   - NSE Futures: 0.00173% | NSE Options: 0.03503% (on premium).
3. Goods and Services Tax (GST):
   - 18% on (Brokerage + Exchange Turnover Charges + SEBI Charges).
4. SEBI Turnover Charges:
   - ₹10 per crore of transaction value across all segments.
5. Stamp Duty:
   - As per Indian Stamp Act: 0.015% on Equity Delivery buy; 0.003% on Intraday buy; 0.002% on Futures buy; 0.003% on Options buy.
6. DP (Depository Participant) Charges:
   - ₹13.50 + GST per company debit from CDSL upon selling delivery holdings.
''',
  );

  static const LegalDocumentItem regulatoryDisclosures = LegalDocumentItem(
    id: 'regulatory_disclosures',
    title: 'Regulatory Disclosures & Licenses',
    subtitle: 'Statutory registrations, exchange memberships and credentials',
    lastUpdated: 'September 2026',
    content: '''
CORPORATE INFORMATION:
• Entity: Zero Dalali Securities Private Limited
• Corporate Identification Number (CIN): U67120MH2020PTC342819
• Registered Office: Level 14, Tower 2, One International Center, Senapati Bapat Marg, Prabhadevi, Mumbai - 400013, Maharashtra, India.
• Corporate Office: Block B, Nesco IT Park, Western Express Highway, Goregaon East, Mumbai - 400063, Maharashtra, India.

SEBI REGISTRATIONS & EXCHANGE MEMBERSHIPS:
• SEBI Registration No: INZ000031633 (Stock Broker - Cash, F&O, Currency, Commodity)
• NSE Member ID: 14288 (Clearing Member No: M51842)
• BSE Member ID: 6312
• MCX Member ID: 56820
• CDSL DP ID: 12081600 (SEBI Reg: IN-DP-CDSL-421-2019)
• NSDL DP ID: IN300126 (SEBI Reg: IN-DP-NSDL-512-2020)
• SEBI Research Analyst Reg: INH000008412

COMPLIANCE & GRIEVANCE CONTACT:
• Principal Compliance Officer: Ananya Deshmukh
• Email: compliance@zerodalali.com | Phone: +91 22 6982 4499
• Investor Grievance Portal: grievances@zerodalali.com
• SEBI SCORES Portal: scores.gov.in | Smart ODR: smartodr.in
''',
  );

  static const LegalDocumentItem accountDeletionPolicy = LegalDocumentItem(
    id: 'account_deletion',
    title: 'Account Closure & Data Deletion Policy',
    subtitle: 'Procedure for demat account closure and statutory data retention',
    lastUpdated: 'September 2026',
    content: '''
ACCOUNT CLOSURE CONDITIONS & PREREQUISITES:
Before initiating formal closure of your trading and demat account, please ensure:
1. All open intraday and derivative positions have been squared off.
2. Demat holdings have either been sold off or transferred to another verified Demat account via CDSL Easiest / NSDL Speed-e DIS slip.
3. Your trading account has zero outstanding ledger debit balance. Any pending credit balance will be automatically remitted to your primary verified bank account within 2 business days.

STATUTORY 5-YEAR DATA RETENTION REQUIREMENT:
Under Section 12 of the Prevention of Money Laundering Act (PMLA), 2002 and Regulation 18 of the SEBI (Stock Brokers) Regulations, 1992, Zero is legally mandated to preserve all client KYC records, trade registers, bank transactions, and ledger logs for a minimum duration of 5 years following formal account closure.

Following the statutory 5-year cooling period, all user data, biometric tokens, and digital records are permanently wiped from production and cold backup storage systems.
''',
  );

  static const LegalDocumentItem clientFundsSegregationPolicy = LegalDocumentItem(
    id: 'client_funds_segregation',
    title: 'Client Funds Segregation & Upstreaming Policy',
    subtitle: 'SEBI compliance on daily upstreaming and zero proprietary commingling',
    lastUpdated: 'Circular SEBI/HO/MIRSD/MIRSD-PoD-1/P/CIR/2023/84',
    content: '''
1. 100% UPSTREAMING TO CLEARING CORPORATIONS:
In accordance with SEBI guidelines on Upstreaming of Client Funds, Zero upstreams 100% of all client pay-in funds to authorized Clearing Corporations (NCL/ICCL) by the end of each settlement day.

2. ZERO PROPRIETARY COMMINGLING:
Client money is held strictly in designated "Upstreaming Client Bank Accounts" and "Client Settlement Accounts". Under no circumstances are client funds commingled with Zero's proprietary corporate funds or utilized for broker-level proprietary trading or operating overheads.

3. QUARTERLY RUNNING ACCOUNT SETTLEMENT:
As per SEBI mandates, unutilized funds in a client's trading ledger are automatically refunded to their primary verified bank account on the first Friday of every calendar quarter (or monthly, based on client election).
''',
  );

  static const LegalDocumentItem antiMoneyLaunderingPolicy = LegalDocumentItem(
    id: 'aml_cft_policy',
    title: 'Anti-Money Laundering (AML) & CFT Policy',
    subtitle: 'Standards for prevention of money laundering and terrorist financing under PMLA 2002',
    lastUpdated: 'September 2026',
    content: '''
1. FIU-IND REPORTING MANDATES:
Zero complies fully with the Prevention of Money Laundering Act (PMLA), 2002. Any single cash/digital transaction exceeding ₹10,00,000 (Ten Lakhs) or series of interconnected structured transactions are reported directly to Financial Intelligence Unit - India (FIU-IND) under Cash Transaction Reports (CTR) / Suspicious Transaction Reports (STR).

2. SANCTIONS & PEP SCREENING:
All clients are continuously screened against international high-risk watchlists including United Nations Security Council (UNSC) Consolidated Lists, OFAC, and FATF non-cooperative jurisdictions. Politically Exposed Persons (PEPs) and their immediate relatives are subjected to mandatory Enhanced Due Diligence (EDD) and Principal Officer approval.
''',
  );

  static const LegalDocumentItem businessContinuityPolicy = LegalDocumentItem(
    id: 'bcp_dr_policy',
    title: 'Business Continuity & Disaster Recovery Policy',
    subtitle: 'High availability, secondary DR sites, and CERT-In cybersecurity incident response',
    lastUpdated: 'September 2026',
    content: '''
1. DUAL SEISMIC ZONE ARCHITECTURE:
Zero maintains a primary data center in Mumbai (CtrlS Tier-IV) and an active synchronous Disaster Recovery (DR) data center in Hyderabad (Yotta Tier-IV) located in a different seismic zone to ensure zero disruption during natural or regional catastrophes.

2. RPO & RTO METRICS:
• Recovery Point Objective (RPO): < 15 minutes for real-time transaction and trade ledgers.
• Recovery Time Objective (RTO): < 4 hours to complete full failover and resume order routing.

3. CERT-IN MANDATORY 6-HOUR INCIDENT REPORTING:
In compliance with CERT-In directives under Section 70B of the Information Technology Act, 2000, any cybersecurity breach, unauthorized access attempt, or ransomware event must be formally notified to CERT-In within 6 hours of detection.
''',
  );

  static const LegalDocumentItem marketDataVendorLicensingPolicy = LegalDocumentItem(
    id: 'market_data_licensing',
    title: 'Market Data Licensing & Vendor Agreements',
    subtitle: 'Authorized real-time market data distribution and exchange contracts',
    lastUpdated: 'September 2026',
    content: '''
1. AUTHORIZED DATA DISTRIBUTION:
Real-time quotes, order books, and depth charts provided on Zero are sourced through valid Data Feed Agreements with the National Stock Exchange of India (NSE), BSE Limited, and Multi Commodity Exchange (MCX).

2. REDISTRIBUTION RESTRICTION:
Clients and third parties are strictly prohibited from copying, redistributing, scraping, or sub-licensing real-time or delayed market data feeds without prior written consent from the respective stock exchange and Zero.
''',
  );

  static const List<LegalDocumentItem> all = [
    termsAndConditions,
    privacyPolicy,
    riskDisclosure,
    tariffSchedule,
    regulatoryDisclosures,
    accountDeletionPolicy,
    clientFundsSegregationPolicy,
    antiMoneyLaunderingPolicy,
    businessContinuityPolicy,
    marketDataVendorLicensingPolicy,
  ];
}
