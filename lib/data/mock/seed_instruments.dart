import '../models/models.dart';

class SeedInstruments {
  SeedInstruments._();

  static final List<Instrument> indices = [
    const Instrument(
      token: 'idx_nifty50',
      symbol: 'NIFTY 50',
      name: 'NIFTY 50 Index',
      exchange: Exchange.NSE,
      type: InstrumentType.INDEX,
      tickSize: 0.05,
      freezeQty: 1800,
    ),
    const Instrument(
      token: 'idx_niftybank',
      symbol: 'NIFTY BANK',
      name: 'Nifty Bank Index',
      exchange: Exchange.NSE,
      type: InstrumentType.INDEX,
      tickSize: 0.05,
      freezeQty: 900,
    ),
    const Instrument(
      token: 'idx_sensex',
      symbol: 'SENSEX',
      name: 'BSE Sensex Index',
      exchange: Exchange.BSE,
      type: InstrumentType.INDEX,
      tickSize: 0.05,
      freezeQty: 1000,
    ),
    const Instrument(
      token: 'idx_niftyit',
      symbol: 'NIFTY IT',
      name: 'Nifty IT Index',
      exchange: Exchange.NSE,
      type: InstrumentType.INDEX,
      tickSize: 0.05,
      freezeQty: 1800,
    ),
    const Instrument(
      token: 'idx_finnifty',
      symbol: 'FINNIFTY',
      name: 'Nifty Financial Services Index',
      exchange: Exchange.NSE,
      type: InstrumentType.INDEX,
      tickSize: 0.05,
      freezeQty: 1800,
    ),
  ];

  static final List<Instrument> equities = [
    const Instrument(token: 'eq_reliance', symbol: 'RELIANCE', name: 'Reliance Industries Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_tcs', symbol: 'TCS', name: 'Tata Consultancy Services Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_hdfcbank', symbol: 'HDFCBANK', name: 'HDFC Bank Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_icicibank', symbol: 'ICICIBANK', name: 'ICICI Bank Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_infy', symbol: 'INFY', name: 'Infosys Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_itc', symbol: 'ITC', name: 'ITC Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_bhartiartl', symbol: 'BHARTIARTL', name: 'Bharti Airtel Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_sbin', symbol: 'SBIN', name: 'State Bank of India', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_lici', symbol: 'LICI', name: 'Life Insurance Corp of India', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_hindunilvr', symbol: 'HINDUNILVR', name: 'Hindustan Unilever Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_lt', symbol: 'LT', name: 'Larsen & Toubro Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_bajfinance', symbol: 'BAJFINANCE', name: 'Bajaj Finance Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_maruti', symbol: 'MARUTI', name: 'Maruti Suzuki India Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_hcltech', symbol: 'HCLTECH', name: 'HCL Technologies Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_sunpharma', symbol: 'SUNPHARMA', name: 'Sun Pharmaceutical Ind Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_tatamotors', symbol: 'TATAMOTORS', name: 'Tata Motors Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_ntpc', symbol: 'NTPC', name: 'NTPC Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_axisbank', symbol: 'AXISBANK', name: 'Axis Bank Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_ongc', symbol: 'ONGC', name: 'Oil & Natural Gas Corp Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_titan', symbol: 'TITAN', name: 'Titan Company Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_adanient', symbol: 'ADANIENT', name: 'Adani Enterprises Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_kotakbank', symbol: 'KOTAKBANK', name: 'Kotak Mahindra Bank Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_coalindia', symbol: 'COALINDIA', name: 'Coal India Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_powergrid', symbol: 'POWERGRID', name: 'Power Grid Corp of India Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_tatasteel', symbol: 'TATASTEEL', name: 'Tata Steel Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_mm', symbol: 'M&M', name: 'Mahindra & Mahindra Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_bajajfinsv', symbol: 'BAJAJFINSV', name: 'Bajaj Finserv Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_jswsteel', symbol: 'JSWSTEEL', name: 'JSW Steel Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_adaniports', symbol: 'ADANIPORTS', name: 'Adani Ports & SEZ Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_ultracemco', symbol: 'ULTRACEMCO', name: 'UltraTech Cement Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_asianpaint', symbol: 'ASIANPAINT', name: 'Asian Paints Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_siemens', symbol: 'SIEMENS', name: 'Siemens Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_nestleind', symbol: 'NESTLEIND', name: 'Nestle India Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_wipro', symbol: 'WIPRO', name: 'Wipro Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_ioc', symbol: 'IOC', name: 'Indian Oil Corp Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_bpcl', symbol: 'BPCL', name: 'Bharat Petroleum Corp Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_grasim', symbol: 'GRASIM', name: 'Grasim Industries Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_techm', symbol: 'TECHM', name: 'Tech Mahindra Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_hindalco', symbol: 'HINDALCO', name: 'Hindalco Industries Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_heromotoco', symbol: 'HEROMOTOCO', name: 'Hero MotoCorp Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_cipla', symbol: 'CIPLA', name: 'Cipla Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_sbilife', symbol: 'SBILIFE', name: 'SBI Life Insurance Co Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_drreddy', symbol: 'DRREDDY', name: 'Dr. Reddys Laboratories Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_eichermot', symbol: 'EICHERMOT', name: 'Eicher Motors Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_britannia', symbol: 'BRITANNIA', name: 'Britannia Industries Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_tataconsum', symbol: 'TATACONSUM', name: 'Tata Consumer Products Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_apollohosp', symbol: 'APOLLOHOSP', name: 'Apollo Hospitals Enterprise', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_divislab', symbol: 'DIVISLAB', name: 'Divis Laboratories Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_bajajauto', symbol: 'BAJAJ-AUTO', name: 'Bajaj Auto Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_indusindbk', symbol: 'INDUSINDBK', name: 'IndusInd Bank Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    
    // High Growth & Midcaps
    const Instrument(token: 'eq_zomato', symbol: 'ZOMATO', name: 'Zomato Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_paytm', symbol: 'PAYTM', name: 'One97 Communications Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_jiofin', symbol: 'JIOFIN', name: 'Jio Financial Services Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_irfc', symbol: 'IRFC', name: 'Indian Railway Finance Corp Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(
      token: 'eq_yesbank',
      symbol: 'YESBANK',
      name: 'Yes Bank Ltd',
      exchange: Exchange.NSE,
      type: InstrumentType.EQ,
      surveillanceTag: 'ASM Stage 1',
      freezeQty: 10000,
    ),
    const Instrument(
      token: 'eq_dhfl',
      symbol: 'DHFL',
      name: 'Dewan Housing Finance Ltd',
      exchange: Exchange.NSE,
      type: InstrumentType.EQ,
      isSuspended: true,
      suspensionReason: 'Trading suspended by exchange due to corporate resolution',
      freezeQty: 1000,
    ),
    const Instrument(token: 'eq_rvnl', symbol: 'RVNL', name: 'Rail Vikas Nigam Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_suzlon', symbol: 'SUZLON', name: 'Suzlon Energy Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_trent', symbol: 'TRENT', name: 'Trent Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_bel', symbol: 'BEL', name: 'Bharat Electronics Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_hal', symbol: 'HAL', name: 'Hindustan Aeronautics Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_bhel', symbol: 'BHEL', name: 'Bharat Heavy Electricals Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_yesbank', symbol: 'YESBANK', name: 'Yes Bank Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_idea', symbol: 'IDEA', name: 'Vodafone Idea Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_vedl', symbol: 'VEDL', name: 'Vedanta Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_polycab', symbol: 'POLYCAB', name: 'Polycab India Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_cdsl', symbol: 'CDSL', name: 'Central Depository Services Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_bse', symbol: 'BSE', name: 'BSE Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_angelone', symbol: 'ANGELONE', name: 'Angel One Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_mcx', symbol: 'MCX', name: 'Multi Commodity Exchange Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_dmart', symbol: 'DMART', name: 'Avenue Supermarts Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_nykaa', symbol: 'NYKAA', name: 'FSN E-Commerce Ventures Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
    const Instrument(token: 'eq_policybzr', symbol: 'POLICYBZR', name: 'PB Fintech Ltd', exchange: Exchange.NSE, type: InstrumentType.EQ),
  ];

  static final List<Instrument> commodities = [
    const Instrument(
      token: 'mcx_copper',
      symbol: 'COPPER MCX Sep',
      name: 'Copper Futures September',
      exchange: Exchange.MCX,
      type: InstrumentType.FUT,
      lotSize: 2500,
      tickSize: 0.05,
    ),
    const Instrument(
      token: 'mcx_gold',
      symbol: 'GOLD MCX Oct',
      name: 'Gold 1kg Futures October',
      exchange: Exchange.MCX,
      type: InstrumentType.FUT,
      lotSize: 100,
      tickSize: 1.0,
    ),
    const Instrument(
      token: 'mcx_silver',
      symbol: 'SILVER MCX Dec',
      name: 'Silver 30kg Futures December',
      exchange: Exchange.MCX,
      type: InstrumentType.FUT,
      lotSize: 30,
      tickSize: 1.0,
    ),
    const Instrument(
      token: 'mcx_crudeoil',
      symbol: 'CRUDEOIL MCX Sep',
      name: 'Crude Oil 100 BBL Futures',
      exchange: Exchange.MCX,
      type: InstrumentType.FUT,
      lotSize: 100,
      tickSize: 1.0,
    ),
    const Instrument(
      token: 'mcx_naturalgas',
      symbol: 'NATURALGAS MCX Sep',
      name: 'Natural Gas 1250 MMBTU Futures',
      exchange: Exchange.MCX,
      type: InstrumentType.FUT,
      lotSize: 1250,
      tickSize: 0.10,
    ),
  ];

  static final List<Instrument> forex = [
    const Instrument(
      token: 'fx_usdinr',
      symbol: 'USDINR Sep FUT',
      name: 'US Dollar / Indian Rupee Futures',
      exchange: Exchange.CDS,
      type: InstrumentType.FUT,
      lotSize: 1000,
      tickSize: 0.0025,
    ),
    const Instrument(
      token: 'fx_eurinr',
      symbol: 'EURINR Sep FUT',
      name: 'Euro / Indian Rupee Futures',
      exchange: Exchange.CDS,
      type: InstrumentType.FUT,
      lotSize: 1000,
      tickSize: 0.0025,
    ),
    const Instrument(
      token: 'fx_gbpinr',
      symbol: 'GBPINR Sep FUT',
      name: 'British Pound / Indian Rupee Futures',
      exchange: Exchange.CDS,
      type: InstrumentType.FUT,
      lotSize: 1000,
      tickSize: 0.0025,
    ),
    const Instrument(
      token: 'fx_eurusd',
      symbol: 'EURUSD Spot',
      name: 'Euro / US Dollar Global Spot',
      exchange: Exchange.CDS,
      type: InstrumentType.FUT,
      lotSize: 1000,
      tickSize: 0.0001,
    ),
  ];

  static final List<Instrument> crypto = [
    const Instrument(
      token: 'crypto_btcusd',
      symbol: 'Bitcoin Spot (BTC)',
      name: 'Bitcoin / US Dollar Spot',
      exchange: Exchange.CDS,
      type: InstrumentType.EQ,
      lotSize: 1,
      tickSize: 0.50,
    ),
    const Instrument(
      token: 'crypto_ethusd',
      symbol: 'Ethereum Spot (ETH)',
      name: 'Ethereum / US Dollar Spot',
      exchange: Exchange.CDS,
      type: InstrumentType.EQ,
      lotSize: 1,
      tickSize: 0.10,
    ),
    const Instrument(
      token: 'crypto_solusd',
      symbol: 'Solana Spot (SOL)',
      name: 'Solana / US Dollar Spot',
      exchange: Exchange.CDS,
      type: InstrumentType.EQ,
      lotSize: 1,
      tickSize: 0.01,
    ),
  ];

  static final List<Instrument> globalIndices = [
    const Instrument(
      token: 'global_us500',
      symbol: 'US 500 (S&P 500)',
      name: 'S&P 500 Global Benchmark Index',
      exchange: Exchange.NSE,
      type: InstrumentType.INDEX,
      tickSize: 0.10,
    ),
    const Instrument(
      token: 'global_nasdaq',
      symbol: 'US Tech 100 (NASDAQ)',
      name: 'NASDAQ 100 Global Index',
      exchange: Exchange.NSE,
      type: InstrumentType.INDEX,
      tickSize: 0.10,
    ),
    const Instrument(
      token: 'global_dow',
      symbol: 'US Wall St 30 (DOW)',
      name: 'Dow Jones Industrial Average',
      exchange: Exchange.NSE,
      type: InstrumentType.INDEX,
      tickSize: 0.10,
    ),
  ];

  static final List<Instrument> all = [
    ...commodities,
    ...indices,
    ...globalIndices,
    ...forex,
    ...crypto,
    ...equities,
  ];

  static Instrument? findByToken(String token) {
    try {
      return all.firstWhere((e) => e.token == token || e.token == token.toLowerCase() || e.token.replaceAll('mcx_', '') == token.toLowerCase().replaceAll('mcx_', ''));
    } catch (_) {
      return null;
    }
  }

  static Instrument? findBySymbol(String symbol) {
    try {
      return all.firstWhere((e) =>
          e.symbol.toUpperCase() == symbol.toUpperCase() ||
          e.symbol.toUpperCase().contains(symbol.toUpperCase()) ||
          symbol.toUpperCase().contains(e.symbol.toUpperCase()));
    } catch (_) {
      return null;
    }
  }
}
