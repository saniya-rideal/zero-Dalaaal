import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';

class AlertItem {
  final String id;
  final String symbol;
  final double triggerPrice;
  final String condition;
  final String createdTime;
  bool isActive;

  AlertItem({
    required this.id,
    required this.symbol,
    required this.triggerPrice,
    required this.condition,
    required this.createdTime,
    this.isActive = true,
  });
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<AlertItem> _alerts = [
    AlertItem(
      id: '1',
      symbol: 'COPPER MCX Sep',
      triggerPrice: 1375.00,
      condition: 'Price >= 1375.00',
      createdTime: '03 Sep 2026 10:15',
      isActive: true,
    ),
    AlertItem(
      id: '2',
      symbol: 'GOLD MCX Oct',
      triggerPrice: 71500.00,
      condition: 'Price >= 71500.00',
      createdTime: '03 Sep 2026 09:30',
      isActive: true,
    ),
    AlertItem(
      id: '3',
      symbol: 'SILVER MCX Dec',
      triggerPrice: 83000.00,
      condition: 'Price <= 83000.00',
      createdTime: '02 Sep 2026 18:45',
      isActive: false,
    ),
    AlertItem(
      id: '4',
      symbol: 'CRUDEOIL MCX Sep',
      triggerPrice: 6400.00,
      condition: 'Price >= 6400.00',
      createdTime: '02 Sep 2026 16:20',
      isActive: true,
    ),
  ];
  final Set<String> _selectedAlertIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddAlertDialog() {
    final colors = Theme.of(context).brightness == Brightness.dark
        ? TradingColors.dark
        : TradingColors.light;
    final scriptController = TextEditingController(text: 'COPPER MCX Sep');
    final priceController = TextEditingController(text: '1370.00');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (bottomContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(bottomContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create Price Alert',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: scriptController,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Script Name',
                labelStyle: TextStyle(color: colors.textSecondary),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Target Trigger Price',
                labelStyle: TextStyle(color: colors.textSecondary),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final target = double.tryParse(priceController.text) ?? 0.0;
                if (priceController.text.isNotEmpty && target > 0) {
                  setState(() {
                    _alerts.insert(
                      0,
                      AlertItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        symbol: scriptController.text.trim(),
                        triggerPrice: target,
                        condition: 'Price >= ${target.toStringAsFixed(2)}',
                        createdTime: 'Just now',
                        isActive: true,
                      ),
                    );
                  });
                  Navigator.pop(bottomContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Price alert created!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('SET ALERT',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final query = _searchController.text.trim().toLowerCase();

    var filteredAlerts = _alerts;
    if (query.isNotEmpty) {
      filteredAlerts = _alerts
          .where((a) =>
              a.symbol.toLowerCase().contains(query) ||
              a.condition.toLowerCase().contains(query))
          .toList();
    }

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/alerts'),
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (innerContext) {
            final canPop = Navigator.of(innerContext).canPop();
            if (canPop) {
              return IconButton(
                icon: Icon(Icons.arrow_back, color: colors.textPrimary, size: 24),
                onPressed: () => Navigator.of(innerContext).pop(),
                tooltip: 'Back',
              );
            }
            return IconButton(
              icon: Icon(Icons.menu, color: colors.textPrimary, size: 26),
              onPressed: () => Scaffold.of(innerContext).openDrawer(),
              tooltip: 'Menu',
            );
          },
        ),
        centerTitle: true,
        title: Text('Alerts',
            style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: colors.primary, size: 26),
            onPressed: _showAddAlertDialog,
            tooltip: 'Add Alert',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Public & Private News Ticker Strip
          const NewsTickerStrip(),

          // Dual Script Selector Bar
          const ScriptSelectorBar(),

          // Search Bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: colors.divider.withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                style: AppTypography.body(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by Script Name',
                  hintStyle: AppTypography.body(color: colors.textSecondary),
                  prefixIcon:
                      Icon(Icons.search, color: colors.textSecondary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: colors.textSecondary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          // Action Pill Strip (Select All | Delete)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colors.scriptBarBackground,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (_selectedAlertIds.length == filteredAlerts.length &&
                            filteredAlerts.isNotEmpty) {
                          _selectedAlertIds.clear();
                        } else {
                          _selectedAlertIds
                              .addAll(filteredAlerts.map((a) => a.id));
                        }
                      });
                    },
                    child: Text(
                      _selectedAlertIds.length == filteredAlerts.length &&
                              filteredAlerts.isNotEmpty
                          ? 'Deselect All'
                          : 'Select All',
                      style: AppTypography.body(
                          color: colors.secondary, weight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Alerts (${filteredAlerts.length})',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (_selectedAlertIds.isNotEmpty) {
                        setState(() {
                          _alerts.removeWhere(
                              (item) => _selectedAlertIds.contains(item.id));
                          _selectedAlertIds.clear();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Selected alerts deleted')),
                        );
                      }
                    },
                    child: Text(
                      'Delete',
                      style: AppTypography.body(
                          color: colors.primary, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body
          Expanded(
            child: filteredAlerts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 42,
                            color: colors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        Text(
                          'No Alerts Found',
                          style: GoogleFonts.inter(
                              color: colors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: filteredAlerts.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: colors.divider),
                    itemBuilder: (context, index) {
                      final item = filteredAlerts[index];
                      final isSelected = _selectedAlertIds.contains(item.id);

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Checkbox(
                            value: isSelected,
                            activeColor: colors.primary,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedAlertIds.add(item.id);
                                } else {
                                  _selectedAlertIds.remove(item.id);
                                }
                              });
                            },
                          ),
                          title: Text(item.symbol,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  color: colors.textPrimary)),
                          subtitle: Text(
                              'Trigger: ${item.triggerPrice.toStringAsFixed(2)} • ${item.createdTime}',
                              style: GoogleFonts.inter(
                                  color: colors.textSecondary, fontSize: 12)),
                          trailing: Switch(
                            value: item.isActive,
                            activeTrackColor: colors.primary.withValues(alpha: 0.5),
                            activeThumbColor: colors.primary,
                            onChanged: (val) =>
                                setState(() => item.isActive = val),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
