import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/instrument.dart';

class AddScriptCategory {
  final String name;
  final int selectedCount;
  final int totalCount;
  final List<Instrument> scripts;

  const AddScriptCategory({
    required this.name,
    required this.selectedCount,
    required this.totalCount,
    required this.scripts,
  });
}

class AddScriptFolder {
  final String name;
  final int selectedCount;
  final int totalCount;
  final List<AddScriptCategory> categories;

  const AddScriptFolder({
    required this.name,
    required this.selectedCount,
    required this.totalCount,
    required this.categories,
  });
}

class AddScriptScreen extends StatefulWidget {
  const AddScriptScreen({super.key});

  @override
  State<AddScriptScreen> createState() => _AddScriptScreenState();
}

class _AddScriptScreenState extends State<AddScriptScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  AddScriptFolder? _openedFolder;
  AddScriptCategory? _openedCategory;

  final Set<String> _selectedTokens = {
    'copper_mcx',
    'ltc_spot',
    'mankind_sep',
    'gold_mcx',
    'mazdock_sep',
    'natgas_mcx',
    'crude_mcx',
    'nifty_50',
    'bnty_55000c',
    'bnty_55200c',
    'bnty_55300c',
    'bnty_55100p',
    'bnty_55500c',
    'bnty_55500p',
  };

  late List<AddScriptFolder> _folders;

  @override
  void initState() {
    super.initState();
    _initFolders();
  }

  void _initFolders() {
    // ────────────── GLOBAL SUB-CATEGORIES ──────────────
    final commoditiesScripts = [
      const Instrument(token: 'brent_crude', symbol: 'BRENT Crude Spot', name: 'Brent Crude Oil Spot', exchange: Exchange.CDS, type: InstrumentType.FUT),
      const Instrument(token: 'wti_crude', symbol: 'WTI Crude Spot', name: 'WTI Crude Oil Spot', exchange: Exchange.CDS, type: InstrumentType.FUT),
      const Instrument(token: 'natgas_spot', symbol: 'Natural Gas Spot', name: 'US Natural Gas Spot', exchange: Exchange.CDS, type: InstrumentType.FUT),
      const Instrument(token: 'wheat_spot', symbol: 'Wheat Spot', name: 'US Wheat Futures', exchange: Exchange.CDS, type: InstrumentType.FUT),
      const Instrument(token: 'corn_spot', symbol: 'Corn Spot', name: 'US Corn Futures', exchange: Exchange.CDS, type: InstrumentType.FUT),
    ];

    final cryptoScripts = [
      const Instrument(token: 'crypto_btcusd', symbol: 'BTCUSD Spot', name: 'Bitcoin / US Dollar', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'crypto_ethusd', symbol: 'ETHUSD Spot', name: 'Ethereum / US Dollar', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'ltc_spot', symbol: 'LTCUSD Spot', name: 'Litecoin Spot', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'crypto_xrpusd', symbol: 'XRPUSD Spot', name: 'Ripple / US Dollar', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'crypto_solusd', symbol: 'SOLUSD Spot', name: 'Solana / US Dollar', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'crypto_adausd', symbol: 'ADAUSD Spot', name: 'Cardano / US Dollar', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'crypto_dogeusd', symbol: 'DOGEUSD Spot', name: 'Dogecoin / US Dollar', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'crypto_dotusd', symbol: 'DOTUSD Spot', name: 'Polkadot / US Dollar', exchange: Exchange.CDS, type: InstrumentType.EQ),
    ];

    final currencyPairsScripts = List.generate(
      95,
      (i) => Instrument(
        token: 'curr_$i',
        symbol: 'CURR_PAIR_${i + 1}',
        name: 'Currency Pair ${i + 1} Spot',
        exchange: Exchange.CDS,
        type: InstrumentType.FUT,
      ),
    );

    final forexScripts = [
      const Instrument(token: 'fx_eurusd', symbol: 'EURUSD Spot', name: 'Euro / US Dollar', exchange: Exchange.CDS, type: InstrumentType.FUT),
      const Instrument(token: 'fx_gbpusd', symbol: 'GBPUSD Spot', name: 'British Pound / US Dollar', exchange: Exchange.CDS, type: InstrumentType.FUT),
      const Instrument(token: 'fx_usdjpy', symbol: 'USDJPY Spot', name: 'US Dollar / Japanese Yen', exchange: Exchange.CDS, type: InstrumentType.FUT),
      const Instrument(token: 'fx_audusd', symbol: 'AUDUSD Spot', name: 'Australian Dollar / US Dollar', exchange: Exchange.CDS, type: InstrumentType.FUT),
      const Instrument(token: 'fx_usdcad', symbol: 'USDCAD Spot', name: 'US Dollar / Canadian Dollar', exchange: Exchange.CDS, type: InstrumentType.FUT),
      const Instrument(token: 'fx_usdchf', symbol: 'USDCHF Spot', name: 'US Dollar / Swiss Franc', exchange: Exchange.CDS, type: InstrumentType.FUT),
    ];

    final globalIndicesScripts = [
      const Instrument(token: 'us30_spot', symbol: 'US30 Cash', name: 'Dow Jones Industrial Average', exchange: Exchange.CDS, type: InstrumentType.INDEX),
      const Instrument(token: 'nas100_spot', symbol: 'NAS100 Cash', name: 'Nasdaq 100 Tech Index', exchange: Exchange.CDS, type: InstrumentType.INDEX),
      const Instrument(token: 'spx500_spot', symbol: 'SPX500 Cash', name: 'S&P 500 Index', exchange: Exchange.CDS, type: InstrumentType.INDEX),
      const Instrument(token: 'uk100_spot', symbol: 'UK100 Cash', name: 'FTSE 100 Index', exchange: Exchange.CDS, type: InstrumentType.INDEX),
      const Instrument(token: 'ger40_spot', symbol: 'GER40 Cash', name: 'DAX 40 Index', exchange: Exchange.CDS, type: InstrumentType.INDEX),
      const Instrument(token: 'jpn225_spot', symbol: 'JPN225 Cash', name: 'Nikkei 225 Index', exchange: Exchange.CDS, type: InstrumentType.INDEX),
      const Instrument(token: 'hk50_spot', symbol: 'HK50 Cash', name: 'Hang Seng Index', exchange: Exchange.CDS, type: InstrumentType.INDEX),
    ];

    final metalsSpotScripts = [
      const Instrument(token: 'xau_usd', symbol: 'XAUUSD Spot', name: 'Gold Spot / US Dollar', exchange: Exchange.CDS, type: InstrumentType.FUT),
      const Instrument(token: 'xag_usd', symbol: 'XAGUSD Spot', name: 'Silver Spot / US Dollar', exchange: Exchange.CDS, type: InstrumentType.FUT),
    ];

    final usStocksScripts = [
      const Instrument(token: 'us_aapl', symbol: 'AAPL Spot', name: 'Apple Inc.', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'us_tsla', symbol: 'TSLA Spot', name: 'Tesla Inc.', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'us_nvda', symbol: 'NVDA Spot', name: 'NVIDIA Corp.', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'us_msft', symbol: 'MSFT Spot', name: 'Microsoft Corp.', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'us_amzn', symbol: 'AMZN Spot', name: 'Amazon.com Inc.', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'us_googl', symbol: 'GOOGL Spot', name: 'Alphabet Inc.', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'us_meta', symbol: 'META Spot', name: 'Meta Platforms Inc.', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'us_nflx', symbol: 'NFLX Spot', name: 'Netflix Inc.', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'us_amd', symbol: 'AMD Spot', name: 'Advanced Micro Devices', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'us_intc', symbol: 'INTC Spot', name: 'Intel Corp.', exchange: Exchange.CDS, type: InstrumentType.EQ),
    ];

    // ────────────── INDIAN SUB-CATEGORIES ──────────────
    final giftNiftyScripts = [
      const Instrument(token: 'gift_nifty_fut', symbol: 'GIFT NIFTY Sep FUT', name: 'NSE IX Gift Nifty Futures', exchange: Exchange.CDS, type: InstrumentType.FUT),
    ];

    final indianIndexOptionsScripts = [
      const Instrument(token: 'bnty_55000c', symbol: 'BNTY29SEPN55000C', name: 'BANKNIFTY 29SEP 55000 CE', exchange: Exchange.NFO, type: InstrumentType.CE),
      const Instrument(token: 'bnty_55200c', symbol: 'BNTY29SEPN55200C', name: 'BANKNIFTY 29SEP 55200 CE', exchange: Exchange.NFO, type: InstrumentType.CE),
      const Instrument(token: 'bnty_55300c', symbol: 'BNTY29SEPN55300C', name: 'BANKNIFTY 29SEP 55300 CE', exchange: Exchange.NFO, type: InstrumentType.CE),
      const Instrument(token: 'bnty_55100p', symbol: 'BNTY29SEPN55100P', name: 'BANKNIFTY 29SEP 55100 PE', exchange: Exchange.NFO, type: InstrumentType.PE),
      const Instrument(token: 'bnty_55500c', symbol: 'BNTY29SEPN55500C', name: 'BANKNIFTY 29SEP 55500 CE', exchange: Exchange.NFO, type: InstrumentType.CE),
      const Instrument(token: 'bnty_55500p', symbol: 'BNTY29SEPN55500P', name: 'BANKNIFTY 29SEP 55500 PE', exchange: Exchange.NFO, type: InstrumentType.PE),
      const Instrument(token: 'nifty_25200c', symbol: 'NIFTY26SEPN25200C', name: 'NIFTY 26SEP 25200 CE', exchange: Exchange.NFO, type: InstrumentType.CE),
      const Instrument(token: 'nifty_25000p', symbol: 'NIFTY26SEPN25000P', name: 'NIFTY 26SEP 25000 PE', exchange: Exchange.NFO, type: InstrumentType.PE),
    ];

    final indianIndicesScripts = [
      const Instrument(token: 'nifty_50', symbol: 'NIFTY 50', name: 'NSE Nifty 50 Index', exchange: Exchange.NSE, type: InstrumentType.INDEX),
      const Instrument(token: 'nifty_bank', symbol: 'NIFTY BANK', name: 'NSE Bank Nifty Index', exchange: Exchange.NSE, type: InstrumentType.INDEX),
      const Instrument(token: 'nifty_fin', symbol: 'FINNIFTY', name: 'Nifty Financial Services', exchange: Exchange.NSE, type: InstrumentType.INDEX),
      const Instrument(token: 'nifty_mid', symbol: 'MIDCPNIFTY', name: 'Nifty Midcap Select', exchange: Exchange.NSE, type: InstrumentType.INDEX),
      const Instrument(token: 'sensex_idx', symbol: 'SENSEX', name: 'BSE Sensex Index', exchange: Exchange.BSE, type: InstrumentType.INDEX),
    ];

    final mcxFuturesScripts = [
      const Instrument(token: 'copper_mcx', symbol: 'COPPER MCX Sep', name: 'Copper Futures 2500kg', exchange: Exchange.MCX, type: InstrumentType.FUT),
      const Instrument(token: 'gold_mcx', symbol: 'GOLD MCX Oct', name: 'Gold Futures 1kg', exchange: Exchange.MCX, type: InstrumentType.FUT),
      const Instrument(token: 'natgas_mcx', symbol: 'NATURALGAS MCX Sep', name: 'Natural Gas Futures 1250 MMBtu', exchange: Exchange.MCX, type: InstrumentType.FUT),
      const Instrument(token: 'crude_mcx', symbol: 'CRUDEOIL MCX Oct', name: 'Crude Oil Futures 100 BBL', exchange: Exchange.MCX, type: InstrumentType.FUT),
      const Instrument(token: 'silver_mcx', symbol: 'SILVER MCX Dec', name: 'Silver Futures 30kg', exchange: Exchange.MCX, type: InstrumentType.FUT),
    ];

    final mcxFuturesMiniScripts = [
      const Instrument(token: 'goldm_mcx', symbol: 'GOLDM MCX Oct', name: 'Gold Mini Futures 100g', exchange: Exchange.MCX, type: InstrumentType.FUT),
      const Instrument(token: 'silverm_mcx', symbol: 'SILVERM MCX Nov', name: 'Silver Mini Futures 5kg', exchange: Exchange.MCX, type: InstrumentType.FUT),
    ];

    final mcxOptionsScripts = [
      const Instrument(token: 'crude_6200c', symbol: 'CRUDEOIL19OCT6200CE', name: 'Crude Oil 19OCT 6200 CE', exchange: Exchange.MCX, type: InstrumentType.CE),
      const Instrument(token: 'crude_6000p', symbol: 'CRUDEOIL19OCT6000PE', name: 'Crude Oil 19OCT 6000 PE', exchange: Exchange.MCX, type: InstrumentType.PE),
    ];

    final nseStockFuturesScripts = [
      const Instrument(token: 'mankind_sep', symbol: 'MANKIND Sep', name: 'Mankind Pharma Futures', exchange: Exchange.NFO, type: InstrumentType.FUT),
      const Instrument(token: 'mazdock_sep', symbol: 'MAZDOCK Sep', name: 'Mazagon Dock Futures', exchange: Exchange.NFO, type: InstrumentType.FUT),
      const Instrument(token: 'reliance_sep', symbol: 'RELIANCE Sep FUT', name: 'Reliance Industries Futures', exchange: Exchange.NFO, type: InstrumentType.FUT),
      const Instrument(token: 'tcs_sep', symbol: 'TCS Sep FUT', name: 'Tata Consultancy Services FUT', exchange: Exchange.NFO, type: InstrumentType.FUT),
      const Instrument(token: 'hdfc_sep', symbol: 'HDFCBANK Sep FUT', name: 'HDFC Bank Futures', exchange: Exchange.NFO, type: InstrumentType.FUT),
    ];

    final nseStockOptionsScripts = [
      const Instrument(token: 'mankind_2400c', symbol: 'MANKIND26SEP2400CE', name: 'Mankind Pharma 26SEP 2400 CE', exchange: Exchange.NFO, type: InstrumentType.CE),
      const Instrument(token: 'mazdock_4400c', symbol: 'MAZDOCK26SEP4400CE', name: 'Mazagon Dock 26SEP 4400 CE', exchange: Exchange.NFO, type: InstrumentType.CE),
    ];

    _folders = [
      AddScriptFolder(
        name: 'Global',
        selectedCount: 1,
        totalCount: 47,
        categories: [
          AddScriptCategory(name: 'Commodities', selectedCount: 0, totalCount: 5, scripts: commoditiesScripts),
          AddScriptCategory(name: 'Crypto (Spot)', selectedCount: 0, totalCount: 8, scripts: cryptoScripts),
          AddScriptCategory(name: 'Currency pairs', selectedCount: 0, totalCount: 95, scripts: currencyPairsScripts),
          AddScriptCategory(name: 'Forex', selectedCount: 0, totalCount: 6, scripts: forexScripts),
          AddScriptCategory(name: 'Global Indices', selectedCount: 0, totalCount: 7, scripts: globalIndicesScripts),
          AddScriptCategory(name: 'Metals Spot', selectedCount: 0, totalCount: 2, scripts: metalsSpotScripts),
          AddScriptCategory(name: 'US Stocks', selectedCount: 0, totalCount: 19, scripts: usStocksScripts),
        ],
      ),
      AddScriptFolder(
        name: 'Indian',
        selectedCount: 19,
        totalCount: 816,
        categories: [
          AddScriptCategory(name: 'Gift Nifty', selectedCount: 0, totalCount: 1, scripts: giftNiftyScripts),
          AddScriptCategory(name: 'Indian Index Options', selectedCount: 14, totalCount: 374, scripts: indianIndexOptionsScripts),
          AddScriptCategory(name: 'Indian Indices', selectedCount: 0, totalCount: 5, scripts: indianIndicesScripts),
          AddScriptCategory(name: 'MCX Futures', selectedCount: 2, totalCount: 5, scripts: mcxFuturesScripts),
          AddScriptCategory(name: 'MCX Futures Mini', selectedCount: 0, totalCount: 2, scripts: mcxFuturesMiniScripts),
          AddScriptCategory(name: 'MCX Options', selectedCount: 0, totalCount: 64, scripts: mcxOptionsScripts),
          AddScriptCategory(name: 'NSE Stock Futures', selectedCount: 0, totalCount: 172, scripts: nseStockFuturesScripts),
          AddScriptCategory(name: 'NSE Stock Options', selectedCount: 0, totalCount: 222, scripts: nseStockOptionsScripts),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleScript(String token) {
    setState(() {
      if (_selectedTokens.contains(token)) {
        _selectedTokens.remove(token);
      } else {
        _selectedTokens.add(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary, size: 22),
          onPressed: () {
            if (_openedCategory != null) {
              setState(() => _openedCategory = null);
            } else if (_openedFolder != null) {
              setState(() => _openedFolder = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        centerTitle: true,
        title: Text(
          _openedCategory?.name ?? 'Add Script',
          style: AppTypography.h1(color: colors.textPrimary, weight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
              ),
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                style: AppTypography.body(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by Script Name',
                  hintStyle: AppTypography.body(color: colors.textSecondary),
                  prefixIcon: Icon(LucideIcons.search, color: colors.textSecondary.withValues(alpha: 0.7), size: 18),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                onChanged: (val) => setState(() => _query = val.trim()),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Content: Search Results, Category Scripts List, Sub-Folder List, or Root Folder List
          Expanded(
            child: _query.isNotEmpty
                ? _buildGlobalSearchResults(colors)
                : _openedCategory != null
                    ? _buildCategoryScriptsList(_openedCategory!, colors)
                    : _openedFolder != null
                        ? _buildSubFolderList(_openedFolder!, colors)
                        : _buildRootFolderList(colors),
          ),
        ],
      ),
    );
  }

  // 1. Root Folder List (Global 1/47, Indian 19/816) - Matching Screenshot 1
  Widget _buildRootFolderList(TradingColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _folders.length,
      itemBuilder: (context, index) {
        final folder = _folders[index];

        return InkWell(
          onTap: () => setState(() {
            _openedFolder = folder;
            _openedCategory = null;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Row(
              children: [
                // Yellow / Golden Folder Icon
                const Icon(
                  LucideIcons.folder,
                  color: Color(0xFFF5A623),
                  size: 24,
                ),
                const SizedBox(width: 14),
                Text(
                  folder.name,
                  style: AppTypography.body(
                    color: colors.textPrimary,
                    weight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${folder.selectedCount}/${folder.totalCount}',
                  style: AppTypography.body(
                    color: colors.textPrimary,
                    weight: FontWeight.w500,
                    tabular: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. Sub-Folder List (Inside Global or Indian) - Matching Screenshots 2 & 3
  Widget _buildSubFolderList(AddScriptFolder folder, TradingColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: folder.categories.length,
      itemBuilder: (context, index) {
        final cat = folder.categories[index];

        return InkWell(
          onTap: () => setState(() => _openedCategory = cat),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Row(
              children: [
                // Golden Yellow Folder Icon
                const Icon(
                  LucideIcons.folder,
                  color: Color(0xFFF5A623),
                  size: 24,
                ),
                const SizedBox(width: 14),
                Text(
                  cat.name,
                  style: AppTypography.body(
                    color: colors.textPrimary,
                    weight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${cat.selectedCount}/${cat.totalCount}',
                  style: AppTypography.body(
                    color: colors.textPrimary,
                    weight: FontWeight.w500,
                    tabular: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 3. Category Scripts List (Inside a Category sub-folder)
  Widget _buildCategoryScriptsList(AddScriptCategory cat, TradingColors colors) {
    if (cat.scripts.isEmpty) {
      return Center(
        child: Text('No scripts available in ${cat.name}', style: AppTypography.body(color: colors.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: cat.scripts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final script = cat.scripts[index];
        final isSelected = _selectedTokens.contains(script.token);

        return ListTile(
          title: Text(script.symbol, style: AppTypography.body(weight: FontWeight.w700)),
          subtitle: Text('${script.name} • ${script.exchange.name}', style: AppTypography.caption(color: colors.textSecondary)),
          trailing: IconButton(
            icon: Icon(
              isSelected ? LucideIcons.checkCircle2 : LucideIcons.plusCircle,
              color: isSelected ? colors.primary : colors.secondary,
              size: 22,
            ),
            onPressed: () => _toggleScript(script.token),
          ),
        );
      },
    );
  }

  // 4. Global Search across all categories and scripts
  Widget _buildGlobalSearchResults(TradingColors colors) {
    final List<Instrument> allScripts = [];
    for (final f in _folders) {
      for (final cat in f.categories) {
        allScripts.addAll(cat.scripts);
      }
    }

    final matches = allScripts
        .where((s) =>
            s.symbol.toLowerCase().contains(_query.toLowerCase()) ||
            s.name.toLowerCase().contains(_query.toLowerCase()))
        .toSet()
        .toList();

    if (matches.isEmpty) {
      return Center(
        child: Text('No scripts found matching "$_query"', style: AppTypography.body(color: colors.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final script = matches[index];
        final isSelected = _selectedTokens.contains(script.token);

        return ListTile(
          title: Text(script.symbol, style: AppTypography.body(weight: FontWeight.w700)),
          subtitle: Text('${script.name} • ${script.exchange.name}', style: AppTypography.caption(color: colors.textSecondary)),
          trailing: IconButton(
            icon: Icon(
              isSelected ? LucideIcons.checkCircle2 : LucideIcons.plusCircle,
              color: isSelected ? colors.primary : colors.secondary,
              size: 22,
            ),
            onPressed: () => _toggleScript(script.token),
          ),
        );
      },
    );
  }
}
