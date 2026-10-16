import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zero_dalali/data/models/models.dart';

class NewsRepository {
  final List<NewsArticle> _articles = [];
  final List<LearningModule> _modules = [];
  final List<GlossaryTerm> _glossary = [];

  NewsRepository() {
    _initArticles();
    _initModules();
    _initGlossary();
  }

  // ─── News Feed API ─────────────────────────────────────────────────────────

  List<NewsArticle> getAllArticles() => List.unmodifiable(_articles);

  PaginatedResult<NewsArticle> getArticles({
    String? query,
    NewsCategory? category,
    int page = 1,
    int pageSize = 8,
  }) {
    var filtered = List<NewsArticle>.from(_articles);

    // Category filter
    if (category != null && category != NewsCategory.ALL) {
      filtered = filtered.where((a) => a.category == category).toList();
    }

    // Keyword search filter
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      filtered = filtered.where((a) {
        return a.title.toLowerCase().contains(q) ||
            a.summary.toLowerCase().contains(q) ||
            a.source.toLowerCase().contains(q) ||
            a.relatedSymbols.any((s) => s.toLowerCase().contains(q));
      }).toList();
    }

    // Sort by timestamp descending (newest first)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final totalCount = filtered.length;
    final validPage = page < 1 ? 1 : page;
    final startIndex = (validPage - 1) * pageSize;

    if (startIndex >= totalCount) {
      return PaginatedResult(
        items: [],
        totalCount: totalCount,
        page: validPage,
        pageSize: pageSize,
        hasMore: false,
      );
    }

    final endIndex = min(startIndex + pageSize, totalCount);
    final pageItems = filtered.sublist(startIndex, endIndex);
    final hasMore = endIndex < totalCount;

    return PaginatedResult(
      items: pageItems,
      totalCount: totalCount,
      page: validPage,
      pageSize: pageSize,
      hasMore: hasMore,
    );
  }

  NewsArticle? getArticleById(String id) {
    try {
      return _articles.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Learning Academy API ──────────────────────────────────────────────────

  List<LearningModule> getModules({LearningCategory? category}) {
    if (category == null || category == LearningCategory.ALL) {
      return List.unmodifiable(_modules);
    }
    return _modules.where((m) => m.category == category).toList();
  }

  LearningModule? getModuleById(String id) {
    try {
      return _modules.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Glossary API ──────────────────────────────────────────────────────────

  List<GlossaryTerm> getGlossaryTerms({String? query, LearningCategory? category}) {
    var list = List<GlossaryTerm>.from(_glossary);

    if (category != null && category != LearningCategory.ALL) {
      list = list.where((t) => t.category == category).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((t) {
        return t.term.toLowerCase().contains(q) ||
            t.definition.toLowerCase().contains(q) ||
            (t.example != null && t.example!.toLowerCase().contains(q));
      }).toList();
    }

    // Sort alphabetically
    list.sort((a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()));
    return list;
  }

  // ─── Seed Data Initializers ────────────────────────────────────────────────

  void _initArticles() {
    final now = DateTime.now();

    _articles.addAll([
      NewsArticle(
        id: 'news_01',
        title: 'Nifty 50 breaches 25,200 as Banking & IT majors lead broad-based rally',
        summary:
            'Benchmark equity indices scale fresh record highs in early trade, driven by persistent domestic institutional buying and strong quarterly earnings guidance across large-caps.',
        fullContent:
            'The Nifty 50 index surged past the psychological 25,200 threshold during Friday morning trade, buoyed by heavyweight gains in State Bank of India, Reliance Industries, and Tata Consultancy Services.\n\nForeign institutional investors (FIIs) turned net buyers for the third straight session, injecting ₹1,840 crore into cash equities, while DIIs continued steady SIP inflows. Market breadth remained decisively positive with 1,640 advancing stocks against 420 declines on the National Stock Exchange.\n\nAnalysts noted that sustained macroeconomic resilience, moderating wholesale inflation figures, and robust retail credit disbursement trends are providing fundamental support to corporate valuations.',
        timestamp: now.subtract(const Duration(minutes: 18)),
        source: 'LiveMint',
        sourceUrl: 'https://livemint.com/market/nifty-record-high-banking-it-rally',
        category: NewsCategory.EQUITIES,
        sentiment: NewsSentiment.BULLISH,
        relatedTokens: const ['idx_nifty50', 'eq_sbin', 'eq_reliance'],
        relatedSymbols: const ['NIFTY 50', 'SBIN', 'RELIANCE'],
        readTimeMinutes: 3,
        keyTakeaways: const [
          'Nifty 50 surges above 25,200 led by Banking and IT bellwethers.',
          'FIIs turn net buyers with ₹1,840 crore inflows; DII SIP flows remain firm.',
          'Market breadth is strongly positive at a 4:1 advance-decline ratio.',
        ],
      ),
      NewsArticle(
        id: 'news_02',
        title: 'State Bank of India reports 14.8% credit growth; asset quality hits decade best',
        summary:
            'India’s largest public lender registers strong retail and SME advances while Gross Non-Performing Assets (NPA) drop to 2.14% with a provision coverage ratio above 76%.',
        fullContent:
            'State Bank of India (SBIN) posted a resilient quarterly operational performance, led by strong traction in home loans, MSME working capital demand, and corporate infrastructure credit.\n\nNet interest margin (NIM) expanded 6 basis points sequentially to 3.32%, while Slippages remained well contained under 0.65% annualized. The bank management highlighted that capital adequacy remains well above regulatory thresholds at 14.12%, supporting medium-term loan book expansion without immediate dilution.\n\nBrokerage houses maintained "Overweight" ratings on the stock, hiking target prices to ₹920 citing robust return on equity (RoE) trajectory.',
        timestamp: now.subtract(const Duration(minutes: 42)),
        source: 'Moneycontrol',
        sourceUrl: 'https://moneycontrol.com/news/business/sbin-credit-growth-asset-quality',
        category: NewsCategory.EQUITIES,
        sentiment: NewsSentiment.BULLISH,
        relatedTokens: const ['eq_sbin'],
        relatedSymbols: const ['SBIN'],
        readTimeMinutes: 4,
        keyTakeaways: const [
          '14.8% YoY credit growth driven by retail and corporate lending.',
          'Gross NPA improves to 2.14%; provision coverage ratio stands at 76.5%.',
          'Management guides for steady loan momentum and sustained 15%+ RoE.',
        ],
      ),
      NewsArticle(
        id: 'news_03',
        title: 'Bank Nifty PCR climbs to 1.18; heavy Put writing witnessed at 51,500 strike',
        summary:
            'Derivative market participants build bullish option structures as Bank Nifty consolidates near highs, with open interest shifting toward higher strike put options.',
        fullContent:
            'In the derivative segment, the Put-Call Ratio (PCR) for Bank Nifty rose from 0.94 to 1.18, indicating aggressive Put writing across weekly strikes. The 51,500 Put strike witnessed substantial open interest addition of over 28 lakh shares, marking it as a critical immediate support zone.\n\nOn the Call side, maximum open interest accumulation was observed at the 52,500 and 53,000 strikes, suggesting traders expect a controlled breakout rather than an explosive directional move.\n\nVolatility benchmark India VIX dipped 4.2% to trade at 13.10, indicating minimal market fear and healthy liquidity across index option chains.',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 15)),
        source: 'CNBC-TV18',
        sourceUrl: 'https://cnbctv18.com/market/bank-nifty-pcr-put-writing-fno',
        category: NewsCategory.FNO,
        sentiment: NewsSentiment.BULLISH,
        relatedTokens: const ['idx_niftybank'],
        relatedSymbols: const ['NIFTY BANK'],
        readTimeMinutes: 3,
        keyTakeaways: const [
          'Bank Nifty PCR surges to 1.18 signaling supportive market positioning.',
          '51,500 Put emerges as crucial technical floor with heavy open interest additions.',
          'India VIX cools to 13.10, dampening option premium volatility.',
        ],
      ),
      NewsArticle(
        id: 'news_04',
        title: 'Gold touches fresh highs on MCX near ₹74,800/10g on US rate cut expectations',
        summary:
            'Precious metals advance sharply as benchmark US 10-year Treasury yields soften and global central banks continue bullion reserve diversification.',
        fullContent:
            'Gold futures on the Multi Commodity Exchange (MCX) rose ₹450 to touch an intraday high of ₹74,820 per 10 grams, taking cues from international spot bullion which hovered around \$2,525 per ounce.\n\nCooling US macroeconomic indicators, including softer labor market prints and modest non-farm payroll revisions, have reinforced market expectations that the US Federal Reserve will initiate interest rate reductions in its upcoming policy conclave.\n\nPhysical retail demand across India remained buoyant ahead of the festive season, with jewelers in Zaveri Bazaar noting steady advance bookings despite elevated price levels.',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 10)),
        source: 'Reuters',
        sourceUrl: 'https://reuters.com/markets/commodities/gold-mcx-record-us-fed-rate-cuts',
        category: NewsCategory.COMMODITIES,
        sentiment: NewsSentiment.BULLISH,
        relatedTokens: const ['mcx_gold'],
        relatedSymbols: const ['GOLD'],
        readTimeMinutes: 3,
        keyTakeaways: const [
          'MCX Gold trades near record highs of ₹74,820/10 grams.',
          'International bullion tests \$2,525/oz supported by weakening US Dollar Index.',
          'Physical demand ahead of festive season remains resilient.',
        ],
      ),
      NewsArticle(
        id: 'news_05',
        title: 'Crude Oil slips 1.8% toward \$88.50 as demand concerns counter OPEC+ supply curbs',
        summary:
            'WTI and Brent benchmarks experience downward pressure as refinery maintenance shutdowns and mixed economic readings from major Asian importers temper bullish momentum.',
        fullContent:
            'Crude oil futures traded on MCX opened lower following weakness in international benchmarks. Brent crude traded down 1.8% at \$88.40 per barrel, while West Texas Intermediate (WTI) traded around \$84.20.\n\nWhile OPEC+ delegates reiterated voluntary output quota discipline of 2.2 million barrels per day through the end of the quarter, rising non-OPEC production from the Americas and cautious industrial demand forecasts capped upside attempts.\n\nEnergy analysts suggest oil may trade in a bounded range between \$82 and \$91 until concrete inventory drawdown datasets are released by the US Energy Information Administration.',
        timestamp: now.subtract(const Duration(hours: 3, minutes: 25)),
        source: 'Bloomberg',
        sourceUrl: 'https://bloomberg.com/news/crude-oil-wti-brent-mcx-opec-supply',
        category: NewsCategory.COMMODITIES,
        sentiment: NewsSentiment.BEARISH,
        relatedTokens: const ['mcx_crudeoil'],
        relatedSymbols: const ['CRUDEOIL'],
        readTimeMinutes: 4,
        keyTakeaways: const [
          'Brent crude slides 1.8% to \$88.40 per barrel on demand headwinds.',
          'OPEC+ production voluntary cuts cushion deeper price corrections.',
          'MCX Crude oil active contract tests key technical support near ₹6,950.',
        ],
      ),
      NewsArticle(
        id: 'news_06',
        title: 'Indian Rupee firms to 83.74 vs US Dollar; RBI market operations anchor volatility',
        summary:
            'The domestic currency advances against the Greenback as foreign capital inflows into sovereign debt and local equities outweigh month-end dollar bids from importers.',
        fullContent:
            'The Indian Rupee (INR) appreciated 11 paise to trade at 83.74 against the US Dollar in interbank foreign exchange markets. A weaker US Dollar Index (DXY), which traded near 101.40, alongside robust foreign portfolio investor inflows into Indian government bonds following global bond index inclusion, lent significant support.\n\nTreasury officials noted that regular liquidity operations by the Reserve Bank of India continue to maintain two-way order flow and suppress speculative intraday currency spikes.\n\nForward premia across 1-year tenors held steady at 2.15%, signaling well-anchored interest rate differential expectations between Mumbai and New York.',
        timestamp: now.subtract(const Duration(hours: 4, minutes: 15)),
        source: 'FXStreet',
        sourceUrl: 'https://fxstreet.com/news/inr-usdinr-rbi-volatility-forex',
        category: NewsCategory.FOREX,
        sentiment: NewsSentiment.BULLISH,
        relatedTokens: const ['fx_usdinr'],
        relatedSymbols: const ['USDINR'],
        readTimeMinutes: 3,
        keyTakeaways: const [
          'Rupee gains 11 paise to trade at 83.74 against the US Dollar.',
          'FPI inflows into Indian sovereign debt provide underlying dollar supply.',
          'RBI intervention ensures low volatility and tight bid-ask spreads.',
        ],
      ),
      NewsArticle(
        id: 'news_07',
        title: 'India Q1 GDP expands 7.2%; manufacturing and infrastructure capex drive momentum',
        summary:
            'Official government statistics show the Indian economy continuing its fast-paced growth trajectory, beating analyst consensus forecasts of 6.9%.',
        fullContent:
            'India’s gross domestic product (GDP) expanded by 7.2% year-on-year in the April-June quarter, propelled by robust public infrastructure capital expenditure, double-digit manufacturing expansion, and healthy service exports.\n\nGross Fixed Capital Formation (GFCF), a key barometer of real investment activity, surged 8.5% over the preceding year. Urban consumption indicators showed steady strength in automotive, aviation, and digital services, while rural consumption exhibited recovery supported by favorable monsoon progress.\n\nChief Economic Advisor remarked that strong corporate balance sheets and resilient tax collections position the nation favorably against global macroeconomic headwinds.',
        timestamp: now.subtract(const Duration(hours: 5, minutes: 40)),
        source: 'LiveMint',
        sourceUrl: 'https://livemint.com/economy/india-q1-gdp-growth-infrastructure-capex',
        category: NewsCategory.ECONOMY,
        sentiment: NewsSentiment.BULLISH,
        relatedTokens: const ['idx_nifty50'],
        relatedSymbols: const ['NIFTY 50'],
        readTimeMinutes: 5,
        keyTakeaways: const [
          'Q1 GDP growth beats expectations, coming in at 7.2% YoY.',
          'Manufacturing and gross capital formation show robust double-digit expansion.',
          'Rural consumption indicators show gradual revival alongside steady urban demand.',
        ],
      ),
      NewsArticle(
        id: 'news_08',
        title: 'TCS secures \$450M multi-year cloud transformation deal with European logistics giant',
        summary:
            'The country’s largest IT services firm strengthens its European presence with a comprehensive digital core modernization and enterprise AI integration mandate.',
        fullContent:
            'Tata Consultancy Services (TCS) has inked an expanded five-year strategic engagement valued at \$450 million with a premier European logistics and supply-chain enterprise.\n\nUnder the partnership, TCS will deploy its proprietary AI-driven cloud automation suite, migrate legacy mainframe operations to scalable hybrid cloud platforms, and establish real-time predictive shipment tracking infrastructure.\n\nTCS management highlighted that international deal pipelines remain healthy, with enterprise clients prioritizing cost-optimization transformations and generative AI business process integrations.\n\nThe stock traded 1.2% higher at ₹4,185 on the National Stock Exchange.',
        timestamp: now.subtract(const Duration(hours: 7, minutes: 10)),
        source: 'Moneycontrol',
        sourceUrl: 'https://moneycontrol.com/news/business/tcs-european-cloud-deal',
        category: NewsCategory.EQUITIES,
        sentiment: NewsSentiment.BULLISH,
        relatedTokens: const ['eq_tcs'],
        relatedSymbols: const ['TCS'],
        readTimeMinutes: 3,
        keyTakeaways: const [
          'TCS bags \$450M five-year digital transformation contract in Europe.',
          'Deal involves AI automation, legacy modernization, and hybrid cloud integration.',
          'Shares gain 1.2% on NSE following announcement.',
        ],
      ),
      NewsArticle(
        id: 'news_09',
        title: 'SEBI tightens Index Derivative framework: minimum contract value raised to ₹15 Lakhs',
        summary:
            'Market regulator notifies revised rules for index futures and options to curb speculative retail derivative exposure, hiking lot sizes and upfront margin requirements.',
        fullContent:
            'The Securities and Exchange Board of India (SEBI) has released a comprehensive circular revising the risk management parameters for exchange-traded equity derivatives.\n\nKey changes include increasing the minimum contract value of index futures and options from ₹5 Lakhs to ₹15 Lakhs, effectively revising lot sizes upward. Furthermore, exchanges will restrict weekly index expiry contracts to only one benchmark index per exchange, mitigating fragmented speculative turnover.\n\nMarket participants are also required to collect 100% upfront extreme loss margin (ELM) on calendar spread positions approaching expiry day to prevent systemic settlement defaults.',
        timestamp: now.subtract(const Duration(hours: 9, minutes: 30)),
        source: 'CNBC-TV18',
        sourceUrl: 'https://cnbctv18.com/market/sebi-index-derivative-regulations-lot-size',
        category: NewsCategory.FNO,
        sentiment: NewsSentiment.NEUTRAL,
        relatedTokens: const ['idx_nifty50', 'idx_niftybank'],
        relatedSymbols: const ['NIFTY 50', 'NIFTY BANK'],
        readTimeMinutes: 4,
        keyTakeaways: const [
          'Minimum derivative contract value increased from ₹5L to ₹15L.',
          'Weekly expiry contracts limited to one benchmark index per exchange.',
          'Higher upfront margin requirements to safeguard retail capital.',
        ],
      ),
      NewsArticle(
        id: 'news_10',
        title: 'Reliance Industries announces mega green hydrogen gigafactory commissioning timeline',
        summary:
            'Energy conglomerate confirms Phase-1 electrolyzer manufacturing facility at Jamnagar will commence commercial testing by the end of Q4.',
        fullContent:
            'Reliance Industries Limited (RIL) delivered key strategic updates during its investor conference regarding the progress of its new energy gigacomplex in Jamnagar, Gujarat.\n\nThe initial phase of the multi-gigawatt electrolyzer manufacturing plant is slated to initiate trial runs by December, utilizing indigenously developed pressurized alkaline technology. The company confirmed that green hydrogen production will be captive-consumed in its petrochemical cracking units, progressively displacing grey hydrogen.\n\nAnalysts noted that renewable energy investments will begin contributing to consolidated EBITDA margins from FY27 onwards.',
        timestamp: now.subtract(const Duration(hours: 12, minutes: 15)),
        source: 'Reuters',
        sourceUrl: 'https://reuters.com/business/reliance-green-hydrogen-jamnagar-gigafactory',
        category: NewsCategory.EQUITIES,
        sentiment: NewsSentiment.BULLISH,
        relatedTokens: const ['eq_reliance'],
        relatedSymbols: const ['RELIANCE'],
        readTimeMinutes: 4,
        keyTakeaways: const [
          'Phase-1 electrolyzer gigafactory on track for commissioning by Q4.',
          'Captive green hydrogen will reduce Jamnagar refining carbon intensity.',
          'New energy segment expected to drive long-term structural valuation upside.',
        ],
      ),
      NewsArticle(
        id: 'news_11',
        title: 'GST collections hit ₹1.82 Lakh Crore in August, recording 9.8% annualized growth',
        summary:
            'Gross Goods and Services Tax revenue collections remain robust, reflecting high compliance and sustained domestic trade activity across key industrial states.',
        fullContent:
            'India’s gross Goods and Services Tax (GST) revenue collections stood at ₹1,82,410 crore for the month of August, marking a 9.8% increase compared to the corresponding period last year.\n\nDomestic transactions grew by 11.2%, while imports accounted for ₹42,100 crore in tax revenues. Maharashtra, Karnataka, Tamil Nadu, and Gujarat contributed significantly to the revenue collection pool, reflecting strong industrial output and logistics freight movement.\n\nFinance Ministry officials stated that consistent monthly collections above ₹1.7 Lakh Crore provide the fiscal headroom necessary for sustaining planned infrastructure spending.',
        timestamp: now.subtract(const Duration(hours: 16, minutes: 40)),
        source: 'Bloomberg',
        sourceUrl: 'https://bloomberg.com/news/india-gst-collections-growth-august',
        category: NewsCategory.ECONOMY,
        sentiment: NewsSentiment.BULLISH,
        relatedTokens: const ['idx_nifty50'],
        relatedSymbols: const ['NIFTY 50'],
        readTimeMinutes: 3,
        keyTakeaways: const [
          'August GST collections reach ₹1.82 Lakh Crore (+9.8% YoY).',
          'Domestic transactions surge 11.2% indicating healthy consumer demand.',
          'Robust revenue trajectory supports Central Government fiscal consolidation goals.',
        ],
      ),
      NewsArticle(
        id: 'news_12',
        title: 'Copper futures edge up on MCX as LME stockpiles decline to three-month lows',
        summary:
            'Base metal contracts gain traction as supply tightness at London warehouses and green energy grid investments support spot pricing.',
        fullContent:
            'Copper contracts on the MCX traded 0.9% higher at ₹845.60 per kilogram following inventory drawdowns across major London Metal Exchange (LME) registered storage depots.\n\nRefined copper stockpiles in bonded warehouses declined by 12,400 tonnes, while demand from electric vehicle battery manufacturers and renewable power transmission lines in India and Southeast Asia remained solid.\n\nTechnical charts indicate copper is finding firm support above its 50-day moving average, with resistance projected near ₹865.',
        timestamp: now.subtract(const Duration(hours: 20, minutes: 10)),
        source: 'FXStreet',
        sourceUrl: 'https://fxstreet.com/commodities/copper-mcx-lme-stockpiles',
        category: NewsCategory.COMMODITIES,
        sentiment: NewsSentiment.BULLISH,
        relatedTokens: const ['mcx_copper'],
        relatedSymbols: const ['COPPER'],
        readTimeMinutes: 3,
        keyTakeaways: const [
          'MCX Copper gains 0.9% to ₹845.60/kg on shrinking global stockpiles.',
          'LME copper inventory drops to fresh 3-month lows.',
          'EV and transmission sector consumption supports physical demand.',
        ],
      ),
    ]);
  }

  void _initModules() {
    _modules.addAll([
      const LearningModule(
        id: 'mod_01',
        title: 'Stock Market Mechanics & Order Types',
        description:
            'Master the core architecture of equity exchanges, price discovery, order books, and how to use Market, Limit, Stop-Loss, and AMO orders.',
        category: LearningCategory.BASICS,
        level: DifficultyLevel.BEGINNER,
        readTimeMinutes: 6,
        iconName: 'account_balance',
        sections: [
          LearningSection(
            title: '1. How Price Discovery Works',
            content:
                'Every stock price you see on your screen is the Last Traded Price (LTP) — the price at which the most recent trade occurred between a willing buyer and seller.\n\nStock exchanges like the National Stock Exchange (NSE) and Bombay Stock Exchange (BSE) maintain an electronic order matching engine that pairs Buy orders (Bids) with Sell orders (Asks) according to Price-Time Priority. The best buy order (highest price) is always matched against the best sell order (lowest price).',
            keyTakeaways: [
              'LTP is the price of the latest executed transaction, not a guaranteed future price.',
              'Orders are matched strictly by Price-Time priority.',
              'The gap between the best Bid and best Ask is called the Spread.',
            ],
            proTip:
                'Avoid market orders during the first 5 minutes of market open (9:15–9:20 AM) when the spread is typically wide due to opening volatility.',
          ),
          LearningSection(
            title: '2. Complete Guide to Order Types',
            content:
                'Selecting the correct order type ensures you control price and execution speed:\n\n• MARKET: Executes immediately at the best available counter-party price. Guarantees execution, but not price.\n• LIMIT: Executes only at your specified limit price or better. Protects you from slippage, but may remain unfulfilled if market moves away.\n• STOP-MARKET (SL-M): Inactive until the trigger price is touched, after which it becomes an immediate Market order.\n• STOP-LIMIT (SL): Inactive until the trigger price is touched, after which it places a Limit order at your specified limit price.\n• AMO (After Market Order): Placed when exchange sessions are closed; queued for opening at 9:15 AM.\n• IOC (Immediate or Cancel): Must execute instantly upon reaching the exchange; unfilled quantities are cancelled immediately.',
            keyTakeaways: [
              'Use Limit orders in illiquid or high-volatility markets.',
              'Stop-Loss orders are essential safety nets for capital preservation.',
              'AMOs let you plan and place trades outside active market hours.',
            ],
            proTip:
                'In volatile markets, Stop-Limit (SL) is safer than Stop-Market (SL-M) to prevent executing at an extreme spike.',
          ),
        ],
      ),
      const LearningModule(
        id: 'mod_02',
        title: 'Market Depth & Order Book Analysis',
        description:
            'Understand how to read the Level-2 order book, evaluate liquidity, detect bid-ask imbalances, and measure market impact cost.',
        category: LearningCategory.BASICS,
        level: DifficultyLevel.INTERMEDIATE,
        readTimeMinutes: 5,
        iconName: 'view_list',
        sections: [
          LearningSection(
            title: '1. Reading the 5-Level Market Depth',
            content:
                'Market Depth displays the top 5 buy (Bid) and sell (Ask/Offer) price levels along with the number of orders and aggregate shares at each price.\n\n• Left Column (Blue): Buy Bids and Quantities queued in descending price order.\n• Right Column (Red): Sell Asks and Quantities queued in ascending price order.\n• Total Bids vs Total Offers: The cumulative demand versus supply in the queue.',
            keyTakeaways: [
              'Top of the book represents immediate liquidity for market orders.',
              'Large quantity walls can act as short-term psychological support or resistance.',
              'Total Bid/Ask ratio gives directional sentiment insight.',
            ],
            proTip:
                'Watch out for "spoofing" — large orders that appear at deep levels and cancel right before execution to lure retail traders.',
          ),
          LearningSection(
            title: '2. Slippage & Market Impact Cost',
            content:
                'When you place a large market order that exceeds the quantity available at the best Bid or Ask, your order sweeps through multiple depth levels. The difference between the expected price and the actual executed average price is called Slippage or Impact Cost.\n\nExample: If Ask 1 is 100 shares @ ₹800, and Ask 2 is 400 shares @ ₹802, a market buy order for 500 shares will average ₹801.60 instead of ₹800.00.',
            keyTakeaways: [
              'High impact cost eats into trading profits over time.',
              'Always size orders relative to the depth liquidity.',
            ],
            proTip:
                'Break large orders into smaller tranches or use Iceberg/Disclosed Quantity orders.',
          ),
        ],
      ),
      const LearningModule(
        id: 'mod_03',
        title: 'Risk Management: Capital Preservation & RRR',
        description:
            'The definitive guide to the 1% risk rule, mathematical position sizing, stop-loss discipline, and maintaining a positive expectancy.',
        category: LearningCategory.RISK_MANAGEMENT,
        level: DifficultyLevel.BEGINNER,
        readTimeMinutes: 7,
        iconName: 'security',
        sections: [
          LearningSection(
            title: '1. The Golden 1% Risk Rule',
            content:
                'Professional traders never risk more than 1% to 2% of their total trading capital on any single trade.\n\nIf your total account equity is ₹2,00,000, your maximum dollar loss on a trade if stopped out must not exceed ₹2,000 (1%).\n\nPosition Sizing Formula:\nQuantity = Maximum Risk Amount / (Entry Price - Stop Loss Price)\n\nExample:\n• Account: ₹2,00,000 (Max Risk 1% = ₹2,000)\n• Entry: ₹1,000 | Stop-Loss: ₹980 (Risk per share = ₹20)\n• Quantity = ₹2,000 / ₹20 = 100 Shares.',
            keyTakeaways: [
              'Never base position size on gut feeling; calculate it mathematically.',
              'Sticking to 1% ensures you can endure 10 consecutive losses and retain >90% of your capital.',
            ],
            proTip:
                'Always set your Stop-Loss on your chart first based on technical structure, then calculate your quantity backwards.',
          ),
          LearningSection(
            title: '2. Risk-to-Reward Ratio (RRR) & Win Rate Math',
            content:
                'You do not need a high win rate to be profitable. If your average Risk-to-Reward Ratio is 1:2 (you risk ₹1 to make ₹2), you only need a 35% win rate to break even.\n\n• At 1:2 RRR with a 50% win rate across 100 trades:\n50 Wins x ₹2,000 = +₹1,00,000\n50 Losses x ₹1,000 = -₹50,000\nNet Profit = +₹50,000!\n\nReject trades that offer less than a 1:1.5 Risk-Reward ratio.',
            keyTakeaways: [
              'High RRR compensates for human errors and sub-50% win rates.',
              'Cut losing trades quickly; let winning trades reach their target.',
            ],
            proTip:
                'Never widen or remove a Stop-Loss in the hope that price will turn back around.',
          ),
        ],
      ),
      const LearningModule(
        id: 'mod_04',
        title: 'Margin, Leverage & Liquidation Framework',
        description:
            'Understand how broker leverage magnifies gains and losses, margin calls at 90% utilization, and RMS forced-liquidation safety mechanisms.',
        category: LearningCategory.MARGIN_LEVERAGE,
        level: DifficultyLevel.INTERMEDIATE,
        readTimeMinutes: 6,
        iconName: 'trending_up',
        sections: [
          LearningSection(
            title: '1. What is Financial Leverage?',
            content:
                'Leverage allows you to control a large market exposure with a fraction of your own capital (the Margin).\n\n• 5x Leverage (Equity Intraday / MIS): With ₹20,000 margin, you control ₹1,00,000 worth of shares.\n• 20x Leverage (MCX / F&O): With ₹50,000 margin, you control ₹10,00,000 worth of contracts.\n\nAmplified Returns & Amplified Losses:\nIf a 5x leveraged position rises by 2%, your return on invested margin is 10%!\nHowever, if the stock drops by 2%, your loss on invested margin is also 10%!\nA 20% drop would wipe out 100% of your capital.',
            keyTakeaways: [
              'Leverage is a double-edged sword that amplifies volatility.',
              'SEBI mandates strict peak margin collection rules across all Indian brokerages.',
            ],
            proTip:
                'Never use maximum available leverage simply because it is offered. Size positions to match your personal risk tolerance.',
          ),
          LearningSection(
            title: '2. Margin Calls and RMS Auto-Liquidation',
            content:
                'Brokerages monitor account solvency in real-time through the Margin Level:\nMargin Level (%) = (Equity / Used Margin) * 100\n\n• Healthy State (>130%): Ample free margin buffer.\n• Margin Call Warning (90% - 110%): Warning notification sent to deposit funds or reduce exposure.\n• Forced Liquidation (<100% / Deficit): Automated Risk Management System (RMS) steps in and auto-squares off losing positions to prevent negative balance debt.',
            keyTakeaways: [
              'Maintain at least a 30% free margin cash buffer at all times.',
              'Ignoring a Margin Call warning leads to automatic square-off at current market bids.',
            ],
            proTip:
                'Use the ZeroDalali Leverage Simulator in the Order Entry sheet to preview margin requirements before placing trades.',
          ),
        ],
      ),
      const LearningModule(
        id: 'mod_05',
        title: 'Intraday (MIS) Trading Blueprint',
        description:
            'Master day trading rules, 3:20 PM exchange auto square-off, Volume Weighted Average Price (VWAP) setups, and avoiding noon chop.',
        category: LearningCategory.INTRADAY,
        level: DifficultyLevel.INTERMEDIATE,
        readTimeMinutes: 5,
        iconName: 'timer',
        sections: [
          LearningSection(
            title: '1. Intraday MIS Rules & Auto Square-Off',
            content:
                'Margin Intraday Square-off (MIS) orders offer 5x leverage on selected liquid equities. All open MIS positions MUST be closed before the trading day ends.\n\n• Auto Square-Off Timing: At 3:20 PM (NSE/BSE) or 11:15 PM (MCX), the broker\'s automated RMS system initiates market orders to close all outstanding intraday positions.\n• Call & Trade Charges: An administrative RMS fee (typically ₹50 + GST) is levied for positions squared off by the system rather than the client.',
            keyTakeaways: [
              'Intraday positions do not result in Demat delivery.',
              'Manually square off your trades by 3:15 PM to avoid automated RMS charges.',
            ],
            proTip:
                'Set an alarm for 3:10 PM every trading day so you are never caught off-guard by auto square-off.',
          ),
          LearningSection(
            title: '2. Trading with VWAP (Volume Weighted Average Price)',
            content:
                'VWAP is the single most important intraday indicator used by institutional desks:\n\n• Bullish Bias: Price holding firmly above rising VWAP indicates aggressive institutional buying interest.\n• Bearish Bias: Price rejecting and staying below falling VWAP signals distribution.\n• Mean Reversion: Extreme extensions away from VWAP often snap back toward the mean.',
            keyTakeaways: [
              'Never buy a stock that is trading well below its intraday VWAP.',
              'VWAP serves as dynamic institutional support and resistance.',
            ],
            proTip:
                'Combine VWAP with the 20-period Exponential Moving Average (EMA) on the 5-minute chart for high-probability pullbacks.',
          ),
        ],
      ),
      const LearningModule(
        id: 'mod_06',
        title: 'Futures & Options (F&O) Essentials',
        description:
            'Understand Call (CE) & Put (PE) options, Strike Selection, Option Greeks (Delta, Theta Decay), and the statutory SEBI risk reality.',
        category: LearningCategory.FNO,
        level: DifficultyLevel.ADVANCED,
        readTimeMinutes: 8,
        iconName: 'analytics',
        sections: [
          LearningSection(
            title: '1. Options 101: Calls, Puts & Moneyness',
            content:
                'An Option is a contract giving the buyer the right (not obligation) to buy (Call) or sell (Put) an underlying asset at a set price (Strike Price) on or before expiry.\n\n• Call Option (CE): You profit when the underlying stock goes UP.\n• Put Option (PE): You profit when the underlying stock goes DOWN.\n\nOption Moneyness:\n• ITM (In-The-Money): Contains intrinsic real value + time value. Highest Delta.\n• ATM (At-The-Money): Strike closest to current spot price. 0.50 Delta.\n• OTM (Out-of-The-Money): Contains ZERO intrinsic value, only speculative time value. Cheaper, but high risk of expiring worthless at ₹0.',
            keyTakeaways: [
              'Buying cheap, deep OTM options is mathematically equivalent to buying lottery tickets.',
              'Option sellers (writers) receive the premium upfront but carry theoretically unlimited risk.',
            ],
            proTip:
                'For directional intraday trades, buy slightly ITM or ATM strikes with Delta >= 0.50 to capture genuine underlying movement.',
          ),
          LearningSection(
            title: '2. The Option Greeks Demystified',
            content:
                'Option pricing is dictated by mathematical sensitivities called Greeks:\n\n• DELTA: How much the option price moves for every ₹1 change in the underlying stock.\n• THETA (Time Decay): The rate at which an option loses value every passing day, accelerating rapidly into expiry week.\n• GAMMA: The rate of change of Delta (creates the "Hero-or-Zero" explosive expiry moves).\n• VEGA: Sensitivity to changes in implied volatility (IV).',
            keyTakeaways: [
              'Theta decay constantly works against Option Buyers and benefits Option Sellers.',
              'Buying options before major earnings announcements exposes you to an "IV Crush" even if the direction is right.',
            ],
            proTip:
                'Statutory SEBI Advisory: 9 out of 10 individual retail traders in equity F&O incur net financial losses. Trade derivatives with defined capital only.',
          ),
        ],
      ),
      const LearningModule(
        id: 'mod_07',
        title: 'Commodities (MCX) & Currency (Forex) Trading',
        description:
            'Understand commodity lot multipliers, gold/crude oil contract specifications, tick sizes, currency pairs, and regulatory compliance.',
        category: LearningCategory.COMMODITY_FOREX,
        level: DifficultyLevel.INTERMEDIATE,
        readTimeMinutes: 6,
        iconName: 'language',
        sections: [
          LearningSection(
            title: '1. MCX Commodity Trading Rules',
            content:
                'The Multi Commodity Exchange (MCX) allows trading in bullion, energy, and base metals with extended trading hours (9:00 AM to 11:30 PM IST).\n\nKey Contract Specifications:\n• GOLD Mega: 1 kg lot size (₹100 per 1 point move).\n• GOLD Mini: 100 grams lot size (₹10 per 1 point move).\n• CRUDE OIL: 100 barrels lot size (₹100 per ₹1 move).\n• NATURAL GAS: 1,250 mmBtu lot size.\n\nPhysical Delivery Period:\nCommodity futures enter a "Tender Period" 5 days prior to expiry. To prevent compulsory physical delivery, brokerages close client contracts before the tender period begins.',
            keyTakeaways: [
              'Extended trading hours allow reaction to US and European market events.',
              'Never hold commodity futures into the tender period unless you intend to accept physical warehouse delivery.',
            ],
            proTip:
                'Crude Oil and Natural Gas are highly sensitive to Wednesday US inventory datasets released at 8:00 PM IST.',
          ),
          LearningSection(
            title: '2. Currency Derivatives (Forex) in India',
            content:
                'Indian currency trading is strictly regulated by the Reserve Bank of India (RBI) and permitted only through authorized stock exchanges (NSE/BSE).\n\n• Permitted Pairs: USD/INR, EUR/INR, GBP/INR, JPY/INR.\n• Underlying Requirement: Under RBI directives, currency derivative participants must possess an underlying commercial economic exposure or contract declaration.\n• Tick Size: ₹0.0025 (e.g. 83.7425 to 83.7450).',
            keyTakeaways: [
              'Unauthorized offshore forex CFD platforms are illegal in India under FEMA guidelines.',
              'Trade only exchange-listed currency futures and options on SEBI-regulated platforms.',
            ],
            proTip:
                'USD/INR volatility is typically lowest during mid-day and picks up around European open (12:30 PM IST).',
          ),
        ],
      ),
    ]);
  }

  void _initGlossary() {
    _glossary.addAll([
      const GlossaryTerm(
        term: 'Ask Price (Offer)',
        category: LearningCategory.BASICS,
        definition:
            'The lowest price at which a seller is currently willing to sell a security.',
        example: 'If the Ask for SBIN is ₹810.20, your market buy order will execute at ₹810.20.',
      ),
      const GlossaryTerm(
        term: 'Bid Price',
        category: LearningCategory.BASICS,
        definition:
            'The highest price that a buyer is currently willing to pay for a security.',
        example: 'If the Bid for Reliance is ₹2,900.00, your market sell order will execute at ₹2,900.00.',
      ),
      const GlossaryTerm(
        term: 'Bid-Ask Spread',
        category: LearningCategory.BASICS,
        definition:
            'The price difference between the best Bid and the best Ask. A narrow spread signifies high market liquidity.',
        formula: 'Spread = Ask Price - Bid Price',
        example: 'Ask ₹100.05 - Bid ₹100.00 = Spread ₹0.05.',
      ),
      const GlossaryTerm(
        term: 'LTP (Last Traded Price)',
        category: LearningCategory.BASICS,
        definition:
            'The exact price at which the most recent executed transaction occurred on the exchange order matching engine.',
      ),
      const GlossaryTerm(
        term: 'Market Order',
        category: LearningCategory.BASICS,
        definition:
            'An order to buy or sell immediately at the best available prevailing market price.',
      ),
      const GlossaryTerm(
        term: 'Limit Order',
        category: LearningCategory.BASICS,
        definition:
            'An order to buy or sell a security at a specified price or better, protecting the trader from slippage.',
      ),
      const GlossaryTerm(
        term: 'Stop-Loss (SL)',
        category: LearningCategory.RISK_MANAGEMENT,
        definition:
            'An order placed with a broker to buy or sell once the stock reaches a certain trigger price, designed to limit investor loss.',
        example: 'Bought @ ₹500 with SL Trigger @ ₹485 to cap maximum loss at ₹15 per share.',
      ),
      const GlossaryTerm(
        term: 'Trailing Stop-Loss',
        category: LearningCategory.RISK_MANAGEMENT,
        definition:
            'A dynamic stop-loss order that automatically moves upward with the price as the stock gains, locking in profits.',
      ),
      const GlossaryTerm(
        term: 'AMO (After Market Order)',
        category: LearningCategory.BASICS,
        definition:
            'An order placed outside regular market hours that is queued and sent to the exchange when the market opens at 9:15 AM.',
      ),
      const GlossaryTerm(
        term: 'IOC (Immediate or Cancel)',
        category: LearningCategory.BASICS,
        definition:
            'A validity condition where an order must be filled immediately upon arrival at the exchange, with any unfilled quantity cancelled.',
      ),
      const GlossaryTerm(
        term: 'MIS (Margin Intraday Square-off)',
        category: LearningCategory.INTRADAY,
        definition:
            'An intraday product type offering broker leverage with mandatory auto square-off before market close (3:20 PM).',
      ),
      const GlossaryTerm(
        term: 'CNC (Cash and Carry)',
        category: LearningCategory.BASICS,
        definition:
            'An equity delivery product requiring 100% upfront cash with shares credited to the Demat account in T+1 settlement.',
      ),
      const GlossaryTerm(
        term: 'NRML (Normal F&O Margin)',
        category: LearningCategory.FNO,
        definition:
            'A derivative and currency product type that allows holding overnight positions until contract expiry.',
      ),
      const GlossaryTerm(
        term: 'Market Depth',
        category: LearningCategory.BASICS,
        definition:
            'A real-time electronic display showing the top 5 levels of pending buy bids and sell offers waiting to be matched.',
      ),
      const GlossaryTerm(
        term: 'Liquidity',
        category: LearningCategory.BASICS,
        definition:
            'The ease with which a security can be converted into cash without causing a significant price movement.',
      ),
      const GlossaryTerm(
        term: 'Volume',
        category: LearningCategory.BASICS,
        definition:
            'The total number of shares or contracts traded during a specified timeframe or trading session.',
      ),
      const GlossaryTerm(
        term: 'VWAP (Volume Weighted Average Price)',
        category: LearningCategory.INTRADAY,
        definition:
            'The average benchmark price a security has traded at throughout the day, based on both volume and price.',
        formula: 'VWAP = Sum(Price * Volume) / Total Volume',
      ),
      const GlossaryTerm(
        term: 'Circuit Limits (Price Bands)',
        category: LearningCategory.RISK_MANAGEMENT,
        definition:
            'The exchange-mandated maximum percentage (e.g. 5%, 10%, 20%) that a stock is permitted to rise or fall in a single trading session.',
      ),
      const GlossaryTerm(
        term: 'Haircut',
        category: LearningCategory.MARGIN_LEVERAGE,
        definition:
            'The percentage deduction applied to the value of pledged securities when using them as collateral for trading margin.',
        example: 'A ₹1,00,000 blue-chip stock with a 15% haircut yields ₹85,000 in collateral margin.',
      ),
      const GlossaryTerm(
        term: 'Margin Call',
        category: LearningCategory.MARGIN_LEVERAGE,
        definition:
            'A formal demand from a broker requiring the trader to deposit additional cash or securities to cover adverse floating losses.',
      ),
      const GlossaryTerm(
        term: 'Forced Liquidation',
        category: LearningCategory.MARGIN_LEVERAGE,
        definition:
            'Automatic square-off of losing positions executed by the broker’s Risk Management System when margin level falls below critical thresholds.',
      ),
      const GlossaryTerm(
        term: 'Leverage',
        category: LearningCategory.MARGIN_LEVERAGE,
        definition:
            'Using borrowed purchasing power from the broker to increase potential investment returns and market exposure.',
        formula: 'Leverage = Total Exposure / Required Margin',
      ),
      const GlossaryTerm(
        term: 'Drawdown',
        category: LearningCategory.RISK_MANAGEMENT,
        definition:
            'The peak-to-trough decline during a specific record period of an investment portfolio or trading account.',
        formula: 'Drawdown (%) = ((Peak Value - Trough Value) / Peak Value) * 100',
      ),
      const GlossaryTerm(
        term: 'Risk-to-Reward Ratio (RRR)',
        category: LearningCategory.RISK_MANAGEMENT,
        definition:
            'The prospective profit expected on a trade relative to the maximum potential loss defined by the stop-loss.',
        formula: 'RRR = (Target Price - Entry Price) / (Entry Price - Stop Loss Price)',
      ),
      const GlossaryTerm(
        term: 'Call Option (CE)',
        category: LearningCategory.FNO,
        definition:
            'A derivative financial contract giving the buyer the right to purchase the underlying asset at a specified strike price.',
      ),
      const GlossaryTerm(
        term: 'Put Option (PE)',
        category: LearningCategory.FNO,
        definition:
            'A derivative financial contract giving the buyer the right to sell the underlying asset at a specified strike price.',
      ),
      const GlossaryTerm(
        term: 'Strike Price',
        category: LearningCategory.FNO,
        definition:
            'The pre-determined agreed price at which an option contract can be bought or sold upon exercise.',
      ),
      const GlossaryTerm(
        term: 'In-The-Money (ITM)',
        category: LearningCategory.FNO,
        definition:
            'An option that possesses intrinsic real market value (e.g. Call Strike below current spot price).',
      ),
      const GlossaryTerm(
        term: 'At-The-Money (ATM)',
        category: LearningCategory.FNO,
        definition:
            'An option whose strike price is identical or closest to the current spot market price of the underlying asset.',
      ),
      const GlossaryTerm(
        term: 'Out-of-The-Money (OTM)',
        category: LearningCategory.FNO,
        definition:
            'An option with no intrinsic value, consisting entirely of time value that will expire at ₹0 if spot does not cross the strike.',
      ),
      const GlossaryTerm(
        term: 'Delta',
        category: LearningCategory.FNO,
        definition:
            'An Option Greek that measures the expected change in option premium for every ₹1 change in the underlying asset.',
      ),
      const GlossaryTerm(
        term: 'Theta (Time Decay)',
        category: LearningCategory.FNO,
        definition:
            'An Option Greek that measures the daily decay in option premium as the expiration date approaches.',
      ),
      const GlossaryTerm(
        term: 'Open Interest (OI)',
        category: LearningCategory.FNO,
        definition:
            'The total number of outstanding derivative contracts that have not yet been settled, closed, or exercised.',
      ),
      const GlossaryTerm(
        term: 'Mark-to-Market (MTM)',
        category: LearningCategory.FNO,
        definition:
            'The daily or real-time settlement of open futures and options positions based on closing exchange prices.',
      ),
      const GlossaryTerm(
        term: 'Tick Size',
        category: LearningCategory.COMMODITY_FOREX,
        definition:
            'The minimum allowable price movement of a trading instrument on the exchange (e.g., ₹0.05 for Indian equities).',
      ),
      const GlossaryTerm(
        term: 'Lot Size',
        category: LearningCategory.COMMODITY_FOREX,
        definition:
            'The standardized minimum number of shares or units that can be bought or sold in a single futures or options contract.',
      ),
      const GlossaryTerm(
        term: 'Beta',
        category: LearningCategory.BASICS,
        definition:
            'A measure of a stock’s price volatility in relation to the overall market (Nifty 50). Beta > 1 means higher volatility than the index.',
      ),
      const GlossaryTerm(
        term: 'P/E Ratio (Price-to-Earnings)',
        category: LearningCategory.BASICS,
        definition:
            'A valuation metric measuring a company\'s current share price relative to its per-share earnings.',
        formula: 'P/E Ratio = Market Price per Share / Earnings per Share (EPS)',
      ),
      const GlossaryTerm(
        term: 'Short Selling',
        category: LearningCategory.INTRADAY,
        definition:
            'Selling a stock you do not currently own with the intention of buying it back later at a lower price to profit from a falling market.',
      ),
      const GlossaryTerm(
        term: 'Demat Account',
        category: LearningCategory.BASICS,
        definition:
            'A Dematerialized account maintained with a central depository (NSDL/CDSL) that electronically holds your shares, bonds, and mutual funds.',
      ),
    ]);
  }
}

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepository();
});
