import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/instrument.dart';
import '../../market/data/real_market_repository.dart';
import '../../watchlist/presentation/watchlist_controller.dart';

class AddScriptCategory {
  final String name;
  final List<Instrument> scripts;

  const AddScriptCategory({
    required this.name,
    required this.scripts,
  });

  int get totalCount => scripts.length;

  int getSelectedCount(Set<String> selectedTokens) {
    return scripts.where((s) {
      final tokUpper = s.token.toUpperCase();
      final symUpper = s.symbol.toUpperCase();
      return selectedTokens.any((t) => t.toUpperCase() == tokUpper || t.toUpperCase() == symUpper);
    }).length;
  }
}

class AddScriptFolder {
  final String name;
  final List<AddScriptCategory> categories;

  const AddScriptFolder({
    required this.name,
    required this.categories,
  });

  int get totalCount => categories.fold(0, (sum, cat) => sum + cat.totalCount);

  int getSelectedCount(Set<String> selectedTokens) {
    return categories.fold(0, (sum, cat) => sum + cat.getSelectedCount(selectedTokens));
  }
}

class AddScriptScreen extends ConsumerStatefulWidget {
  const AddScriptScreen({super.key});

  @override
  ConsumerState<AddScriptScreen> createState() => _AddScriptScreenState();
}

class _AddScriptScreenState extends ConsumerState<AddScriptScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  AddScriptFolder? _openedFolder;
  AddScriptCategory? _openedCategory;

  final Set<String> _selectedTokens = {};
  List<AddScriptFolder> _folders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final wl = ref.read(watchlistControllerProvider).watchlist;
      if (wl != null && mounted) {
        setState(() {
          _selectedTokens.clear();
          _selectedTokens.addAll(wl.instrumentTokens);
        });
      }
      _loadInstruments();
    });
  }

  Future<void> _loadInstruments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final instruments = await ref.read(marketRepositoryProvider).getInstruments();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _initFolders(instruments);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _initFolders(List<Instrument> instruments) {
    if (instruments.isEmpty) {
      _folders = [];
      return;
    }

    final Map<String, Map<String, List<Instrument>>> folderMap = {};

    for (final inst in instruments) {
      final mkt = inst.market.isNotEmpty ? inst.market.toUpperCase() : 'OTHER';
      final seg = inst.segment.isNotEmpty ? inst.segment.toUpperCase() : 'GENERAL';

      String folderName;
      String categoryName;

      if (mkt == 'CRYPTO') {
        folderName = 'Crypto';
        categoryName = 'Crypto (Spot)';
      } else if (mkt == 'FOREX' || seg == 'FOREX' || seg == 'CURRENCY') {
        folderName = 'Forex';
        categoryName = 'Currency Pairs';
      } else if (mkt == 'COMMODITY' || seg == 'COMMODITY' || seg == 'COMMODITIES') {
        folderName = 'Commodities';
        categoryName = 'MCX & Commodities';
      } else if (mkt == 'INDIAN') {
        folderName = 'Indian Markets';
        if (inst.type == InstrumentType.INDEX || seg == 'INDEX') {
          categoryName = 'Indian Indices';
        } else if (inst.type == InstrumentType.FUT || inst.type == InstrumentType.CE || inst.type == InstrumentType.PE) {
          categoryName = 'F&O Derivatives';
        } else {
          categoryName = 'Equities';
        }
      } else {
        folderName = mkt;
        categoryName = seg;
      }

      folderMap.putIfAbsent(folderName, () => {});
      folderMap[folderName]!.putIfAbsent(categoryName, () => []);
      folderMap[folderName]![categoryName]!.add(inst);
    }

    _folders = folderMap.entries.map((fEntry) {
      final categories = fEntry.value.entries.map((cEntry) {
        return AddScriptCategory(name: cEntry.key, scripts: cEntry.value);
      }).toList();
      return AddScriptFolder(name: fEntry.key, categories: categories);
    }).toList();

    // Maintain current navigation if opened
    if (_openedFolder != null) {
      final match = _folders.where((f) => f.name == _openedFolder!.name).firstOrNull;
      if (match != null) {
        _openedFolder = match;
        if (_openedCategory != null) {
          _openedCategory = match.categories.where((c) => c.name == _openedCategory!.name).firstOrNull;
        }
      } else {
        _openedFolder = null;
        _openedCategory = null;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isScriptSelected(Instrument script) {
    final tokUpper = script.token.toUpperCase();
    final symUpper = script.symbol.toUpperCase();
    return _selectedTokens.any(
      (t) => t.toUpperCase() == tokUpper || t.toUpperCase() == symUpper,
    );
  }

  void _toggleScript(Instrument script) async {
    final sym = script.symbol;
    final isSelected = _isScriptSelected(script);
    final notifier = ref.read(watchlistControllerProvider.notifier);

    if (isSelected) {
      setState(() {
        _selectedTokens.removeWhere(
          (t) => t.toUpperCase() == script.token.toUpperCase() || t.toUpperCase() == sym.toUpperCase(),
        );
      });
      final success = await notifier.removeInstrument(sym);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed ${script.symbol} from Watchlist'),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: Colors.white,
                onPressed: () => notifier.addInstrument(sym),
              ),
            ),
          );
        }
      }
    } else {
      if (_selectedTokens.length >= 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Watchlist limit reached: Maximum 50 symbols allowed.'),
            backgroundColor: Color(0xFFC62828),
          ),
        );
        return;
      }
      setState(() {
        _selectedTokens.add(sym);
      });
      final success = await notifier.addInstrument(sym);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${script.symbol} to Watchlist'),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: Colors.white,
                onPressed: () => notifier.removeInstrument(sym),
              ),
            ),
          );
        } else {
          setState(() {
            _selectedTokens.removeWhere(
              (t) => t.toUpperCase() == script.token.toUpperCase() || t.toUpperCase() == sym.toUpperCase(),
            );
          });
          final err = ref.read(watchlistControllerProvider).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err == 'MAX_SYMBOLS_EXCEEDED'
                  ? 'Watchlist limit reached: Maximum 50 symbols allowed.'
                  : (err ?? 'Failed to add ${script.symbol}')),
              backgroundColor: const Color(0xFFC62828),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    ref.listen<WatchlistState>(watchlistControllerProvider, (prev, next) {
      if (next.watchlist != null) {
        setState(() {
          _selectedTokens.clear();
          _selectedTokens.addAll(next.watchlist!.instrumentTokens);
        });
      }
    });

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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _openedCategory?.name ?? (_openedFolder?.name ?? 'Add Script'),
              style: AppTypography.h1(color: colors.textPrimary, weight: FontWeight.w600),
            ),
            Text(
              '${_selectedTokens.length} / 50 symbols',
              style: AppTypography.caption(color: colors.textSecondary),
            ),
          ],
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

          // Content States: Loading, Error, Empty, or Hierarchical Lists
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.alertCircle, size: 40, color: colors.bearish),
                              const SizedBox(height: 12),
                              Text(
                                'Failed to load instruments',
                                style: AppTypography.h2(color: colors.textPrimary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: AppTypography.caption(color: colors.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadInstruments,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _folders.isEmpty
                        ? Center(
                            child: Text(
                              'No instruments available from market exchange',
                              style: AppTypography.body(color: colors.textSecondary),
                            ),
                          )
                        : _query.isNotEmpty
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

  // 1. Root Folder List
  Widget _buildRootFolderList(TradingColors colors) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _folders.length,
      itemBuilder: (context, index) {
        final folder = _folders[index];
        final selectedCount = folder.getSelectedCount(_selectedTokens);
        final totalCount = folder.totalCount;

        return InkWell(
          onTap: () => setState(() {
            _openedFolder = folder;
            _openedCategory = null;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Row(
              children: [
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
                  '$selectedCount/$totalCount',
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

  // 2. Sub-Folder List
  Widget _buildSubFolderList(AddScriptFolder folder, TradingColors colors) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: folder.categories.length,
      itemBuilder: (context, index) {
        final cat = folder.categories[index];
        final selectedCount = cat.getSelectedCount(_selectedTokens);
        final totalCount = cat.totalCount;

        return InkWell(
          onTap: () => setState(() => _openedCategory = cat),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Row(
              children: [
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
                  '$selectedCount/$totalCount',
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

  // 3. Category Scripts List
  Widget _buildCategoryScriptsList(AddScriptCategory cat, TradingColors colors) {
    if (cat.scripts.isEmpty) {
      return Center(
        child: Text('No scripts available in ${cat.name}', style: AppTypography.body(color: colors.textSecondary)),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: cat.scripts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final script = cat.scripts[index];
        final isSelected = _isScriptSelected(script);

        return ListTile(
          title: Text(script.symbol, style: AppTypography.body(weight: FontWeight.w700)),
          subtitle: Text('${script.name} • ${script.exchange.name}', style: AppTypography.caption(color: colors.textSecondary)),
          trailing: IconButton(
            icon: Icon(
              isSelected ? LucideIcons.check : LucideIcons.plus,
              color: isSelected ? colors.bullish : colors.primary,
              size: 22,
            ),
            tooltip: isSelected ? 'In Watchlist' : 'Add to Watchlist',
            onPressed: () => _toggleScript(script),
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
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final script = matches[index];
        final isSelected = _isScriptSelected(script);

        return ListTile(
          title: Text(script.symbol, style: AppTypography.body(weight: FontWeight.w700)),
          subtitle: Text('${script.name} • ${script.exchange.name}', style: AppTypography.caption(color: colors.textSecondary)),
          trailing: IconButton(
            icon: Icon(
              isSelected ? LucideIcons.check : LucideIcons.plus,
              color: isSelected ? colors.bullish : colors.primary,
              size: 22,
            ),
            tooltip: isSelected ? 'In Watchlist' : 'Add to Watchlist',
            onPressed: () => _toggleScript(script),
          ),
        );
      },
    );
  }
}
