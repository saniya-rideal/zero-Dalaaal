import 'package:flutter/material.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/mock/seed_instruments.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/instrument.dart';

class AddScriptFolder {
  final String name;
  final int selectedCount;
  final int totalCount;
  final List<Instrument> scripts;

  const AddScriptFolder({
    required this.name,
    required this.selectedCount,
    required this.totalCount,
    required this.scripts,
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

  final Set<String> _selectedTokens = {
    'copper_mcx',
    'ltc_spot',
    'mankind_sep',
    'gold_mcx',
    'mazdock_sep',
    'natgas_mcx',
    'crude_mcx',
    'nifty_50',
  };

  late List<AddScriptFolder> _folders;

  @override
  void initState() {
    super.initState();
    _initFolders();
  }

  void _initFolders() {
    final globalScripts = [
      const Instrument(token: 'fx_eurusd', symbol: 'EURUSD', name: 'Euro / US Dollar', exchange: Exchange.CDS, type: InstrumentType.FUT),
      const Instrument(token: 'fx_gbpusd', symbol: 'GBPUSD', name: 'British Pound / US Dollar', exchange: Exchange.CDS, type: InstrumentType.FUT),
      const Instrument(token: 'fx_usdjpy', symbol: 'USDJPY', name: 'US Dollar / Japanese Yen', exchange: Exchange.CDS, type: InstrumentType.FUT),
      const Instrument(token: 'crypto_btcusd', symbol: 'BTCUSD', name: 'Bitcoin Spot', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'crypto_ethusd', symbol: 'ETHUSD', name: 'Ethereum Spot', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'ltc_spot', symbol: 'Litecoin Spot', name: 'Litecoin Spot', exchange: Exchange.CDS, type: InstrumentType.EQ),
      const Instrument(token: 'xau_usd', symbol: 'XAUUSD Spot', name: 'Gold Spot / US Dollar', exchange: Exchange.CDS, type: InstrumentType.FUT),
      const Instrument(token: 'us30_spot', symbol: 'US30 Cash', name: 'Wall Street 30 Index', exchange: Exchange.CDS, type: InstrumentType.INDEX),
      const Instrument(token: 'nas100_spot', symbol: 'NAS100 Cash', name: 'US Tech 100 Index', exchange: Exchange.CDS, type: InstrumentType.INDEX),
    ];

    final indianScripts = [
      ...SeedInstruments.all,
      const Instrument(token: 'copper_mcx', symbol: 'COPPER MCX Sep', name: 'Copper Futures', exchange: Exchange.MCX, type: InstrumentType.FUT),
      const Instrument(token: 'gold_mcx', symbol: 'GOLD MCX Oct', name: 'Gold Futures 1kg', exchange: Exchange.MCX, type: InstrumentType.FUT),
      const Instrument(token: 'natgas_mcx', symbol: 'NATURALGAS MCX Sep', name: 'Natural Gas Futures', exchange: Exchange.MCX, type: InstrumentType.FUT),
      const Instrument(token: 'crude_mcx', symbol: 'CRUDEOIL MCX Oct', name: 'Crude Oil 100 BBL', exchange: Exchange.MCX, type: InstrumentType.FUT),
      const Instrument(token: 'mankind_sep', symbol: 'MANKIND Sep', name: 'Mankind Pharma Futures', exchange: Exchange.NFO, type: InstrumentType.FUT),
      const Instrument(token: 'mazdock_sep', symbol: 'MAZDOCK Sep', name: 'Mazagon Dock Futures', exchange: Exchange.NFO, type: InstrumentType.FUT),
    ];

    _folders = [
      AddScriptFolder(
        name: 'Global',
        selectedCount: 1,
        totalCount: 47,
        scripts: globalScripts,
      ),
      AddScriptFolder(
        name: 'Indian',
        selectedCount: 19,
        totalCount: 816,
        scripts: indianScripts,
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
          icon: Icon(Icons.arrow_back, color: colors.textPrimary, size: 24),
          onPressed: () {
            if (_openedFolder != null) {
              setState(() => _openedFolder = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        centerTitle: true,
        title: Text(
          _openedFolder?.name ?? 'Add Script',
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
                  prefixIcon: Icon(Icons.search, color: colors.textSecondary.withValues(alpha: 0.7), size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
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

          // Content: Search Results, Folder Sub-list, or Main Folder List
          Expanded(
            child: _query.isNotEmpty
                ? _buildGlobalSearchResults(colors)
                : _openedFolder != null
                    ? _buildFolderDetailList(_openedFolder!, colors)
                    : _buildFolderList(colors),
          ),
        ],
      ),
    );
  }

  // 1. Folder List (Global 1/47, Indian 19/816)
  Widget _buildFolderList(TradingColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _folders.length,
      itemBuilder: (context, index) {
        final folder = _folders[index];

        return InkWell(
          onTap: () => setState(() => _openedFolder = folder),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Row(
              children: [
                // Yellow / Golden Folder Icon
                const Icon(
                  Icons.folder,
                  color: Color(0xFFF5A623), // Golden Yellow folder
                  size: 26,
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

  // 2. Folder Sub-list
  Widget _buildFolderDetailList(AddScriptFolder folder, TradingColors colors) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: folder.scripts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final script = folder.scripts[index];
        final isSelected = _selectedTokens.contains(script.token);

        return ListTile(
          title: Text(script.symbol, style: AppTypography.body(weight: FontWeight.w700)),
          subtitle: Text(script.name, style: AppTypography.caption(color: colors.textSecondary)),
          trailing: IconButton(
            icon: Icon(
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              color: isSelected ? colors.primary : colors.secondary,
              size: 24,
            ),
            onPressed: () => _toggleScript(script.token),
          ),
        );
      },
    );
  }

  // 3. Global Search across all scripts
  Widget _buildGlobalSearchResults(TradingColors colors) {
    final all = [
      ..._folders[0].scripts,
      ..._folders[1].scripts,
    ];

    final matches = all
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
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              color: isSelected ? colors.primary : colors.secondary,
              size: 24,
            ),
            onPressed: () => _toggleScript(script.token),
          ),
        );
      },
    );
  }
}
