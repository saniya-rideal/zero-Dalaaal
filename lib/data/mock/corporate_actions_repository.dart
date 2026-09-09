import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/corporate_action.dart';

final corporateActionsRepositoryProvider =
    Provider<CorporateActionsRepository>((ref) {
  return CorporateActionsRepository();
});

class CorporateActionsFilter {
  final CorporateActionType? type;
  final String searchQuery;
  final bool upcomingOnly;

  const CorporateActionsFilter({
    this.type,
    this.searchQuery = '',
    this.upcomingOnly = false,
  });

  CorporateActionsFilter copyWith({
    CorporateActionType? type,
    String? searchQuery,
    bool? upcomingOnly,
    bool clearType = false,
  }) {
    return CorporateActionsFilter(
      type: clearType ? null : (type ?? this.type),
      searchQuery: searchQuery ?? this.searchQuery,
      upcomingOnly: upcomingOnly ?? this.upcomingOnly,
    );
  }
}

class CorporateActionsFilterNotifier
    extends StateNotifier<CorporateActionsFilter> {
  CorporateActionsFilterNotifier() : super(const CorporateActionsFilter());

  void setType(CorporateActionType? type) {
    state = state.copyWith(type: type, clearType: type == null);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setUpcomingOnly(bool upcoming) {
    state = state.copyWith(upcomingOnly: upcoming);
  }

  void reset() {
    state = const CorporateActionsFilter();
  }
}

final corporateActionsFilterProvider = StateNotifierProvider<
    CorporateActionsFilterNotifier, CorporateActionsFilter>((ref) {
  return CorporateActionsFilterNotifier();
});

final filteredCorporateActionsProvider = Provider<List<CorporateAction>>((ref) {
  final repo = ref.watch(corporateActionsRepositoryProvider);
  final filter = ref.watch(corporateActionsFilterProvider);

  return repo.getActions(
    type: filter.type,
    searchQuery: filter.searchQuery,
    upcomingOnly: filter.upcomingOnly,
  );
});

class CorporateActionsRepository {
  late final List<CorporateAction> _actions;

  CorporateActionsRepository() {
    final now = DateTime.now();
    _actions = [
      // 1. Dividends
      CorporateAction(
        id: 'ca_vedl_div',
        symbol: 'VEDL',
        companyName: 'Vedanta Limited',
        actionType: CorporateActionType.dividend,
        details: 'Interim Dividend of ₹28.50 per equity share',
        exDate: now.add(const Duration(days: 4)),
        recordDate: now.add(const Duration(days: 5)),
        announcementDate: now.subtract(const Duration(days: 10)),
        currentPrice: 432.80,
        dividendYield: 7.2,
        remarks: 'High-yield dividend payout from metals & mining operations.',
      ),
      CorporateAction(
        id: 'ca_coalindia_div',
        symbol: 'COALINDIA',
        companyName: 'Coal India Limited',
        actionType: CorporateActionType.dividend,
        details: 'Interim Dividend of ₹15.25 per equity share',
        exDate: now.add(const Duration(days: 7)),
        recordDate: now.add(const Duration(days: 8)),
        announcementDate: now.subtract(const Duration(days: 7)),
        currentPrice: 488.50,
        dividendYield: 5.8,
        remarks: 'PSU energy dividend with steady quarterly payouts.',
      ),
      CorporateAction(
        id: 'ca_itc_div',
        symbol: 'ITC',
        companyName: 'ITC Limited',
        actionType: CorporateActionType.dividend,
        details: 'Final Dividend of ₹7.50 per equity share',
        exDate: now.add(const Duration(days: 12)),
        recordDate: now.add(const Duration(days: 13)),
        announcementDate: now.subtract(const Duration(days: 15)),
        currentPrice: 502.40,
        dividendYield: 3.4,
        remarks: 'FMCG bluechip dividend announcement.',
      ),
      CorporateAction(
        id: 'ca_tcs_div',
        symbol: 'TCS',
        companyName: 'Tata Consultancy Services',
        actionType: CorporateActionType.dividend,
        details: 'Special Dividend of ₹32.00 per share',
        exDate: now.add(const Duration(days: 18)),
        recordDate: now.add(const Duration(days: 19)),
        announcementDate: now.subtract(const Duration(days: 5)),
        currentPrice: 4215.00,
        dividendYield: 2.3,
        remarks: 'Q2 reward from strong cash reserves.',
      ),
      CorporateAction(
        id: 'ca_infy_div',
        symbol: 'INFY',
        companyName: 'Infosys Limited',
        actionType: CorporateActionType.dividend,
        details: 'Final Dividend of ₹20.00 per equity share',
        exDate: now.add(const Duration(days: 24)),
        recordDate: now.add(const Duration(days: 25)),
        announcementDate: now.subtract(const Duration(days: 12)),
        currentPrice: 1885.30,
        dividendYield: 2.1,
        remarks: 'Annual general meeting approved dividend.',
      ),
      CorporateAction(
        id: 'ca_hdfc_div',
        symbol: 'HDFCBANK',
        companyName: 'HDFC Bank Limited',
        actionType: CorporateActionType.dividend,
        details: 'Annual Dividend of ₹19.50 per equity share',
        exDate: now.add(const Duration(days: 28)),
        recordDate: now.add(const Duration(days: 29)),
        announcementDate: now.subtract(const Duration(days: 8)),
        currentPrice: 1648.20,
        dividendYield: 1.2,
        remarks: 'Banking flagship dividend distribution.',
      ),

      // 2. Stock Splits
      CorporateAction(
        id: 'ca_irctc_split',
        symbol: 'IRCTC',
        companyName: 'Indian Railway Catering & Tourism Corp',
        actionType: CorporateActionType.split,
        details: '1:5 Stock Split (Face Value ₹10 to ₹2 per share)',
        exDate: now.add(const Duration(days: 9)),
        recordDate: now.add(const Duration(days: 10)),
        announcementDate: now.subtract(const Duration(days: 20)),
        currentPrice: 945.00,
        ratio: '1:5',
        remarks: 'Liquidity enhancement for retail market participants.',
      ),
      CorporateAction(
        id: 'ca_tatamotors_split',
        symbol: 'TATAMOTORS',
        companyName: 'Tata Motors Limited',
        actionType: CorporateActionType.split,
        details: '1:2 Demerger & Split into CV & PV listed entities',
        exDate: now.add(const Duration(days: 22)),
        recordDate: now.add(const Duration(days: 23)),
        announcementDate: now.subtract(const Duration(days: 25)),
        currentPrice: 978.40,
        ratio: '1:2',
        remarks: 'Separation of Commercial Vehicle and Passenger/EV businesses.',
      ),

      // 3. Bonus Issues
      CorporateAction(
        id: 'ca_reliance_bonus',
        symbol: 'RELIANCE',
        companyName: 'Reliance Industries Limited',
        actionType: CorporateActionType.bonus,
        details: '1:1 Bonus Issue (1 Free Share for every 1 share held)',
        exDate: now.add(const Duration(days: 14)),
        recordDate: now.add(const Duration(days: 15)),
        announcementDate: now.subtract(const Duration(days: 6)),
        currentPrice: 2985.50,
        ratio: '1:1',
        remarks: 'Reward for long-term shareholders ahead of Diwali festival.',
      ),
      CorporateAction(
        id: 'ca_kpittech_bonus',
        symbol: 'KPITTECH',
        companyName: 'KPIT Technologies Limited',
        actionType: CorporateActionType.bonus,
        details: '1:2 Bonus Issue (1 Free Share for every 2 shares held)',
        exDate: now.add(const Duration(days: 30)),
        recordDate: now.add(const Duration(days: 31)),
        announcementDate: now.subtract(const Duration(days: 14)),
        currentPrice: 1720.00,
        ratio: '1:2',
        remarks: 'Capitalization of general reserves for shareholder value.',
      ),

      // 4. Buybacks
      CorporateAction(
        id: 'ca_wipro_buyback',
        symbol: 'WIPRO',
        companyName: 'Wipro Limited',
        actionType: CorporateActionType.buyback,
        details: 'Tender Offer Buyback at ₹485.00 (CMP ₹420.00, +15.5% Premium)',
        exDate: now.add(const Duration(days: 16)),
        recordDate: now.add(const Duration(days: 17)),
        announcementDate: now.subtract(const Duration(days: 18)),
        currentPrice: 420.00,
        remarks: 'Up to 26.9 crore shares to be extinguished.',
      ),
      CorporateAction(
        id: 'ca_tcs_buyback',
        symbol: 'TCS',
        companyName: 'Tata Consultancy Services',
        actionType: CorporateActionType.buyback,
        details: 'Tender Offer Buyback at ₹4,500.00 per share (CMP ₹4,215.00)',
        exDate: now.add(const Duration(days: 35)),
        recordDate: now.add(const Duration(days: 36)),
        announcementDate: now.subtract(const Duration(days: 10)),
        currentPrice: 4215.00,
        remarks: '₹17,000 Crore mega buyback through proportionate tender.',
      ),

      // 5. Rights Issues
      CorporateAction(
        id: 'ca_bharti_rights',
        symbol: 'BHARTIARTL',
        companyName: 'Bharti Airtel Limited',
        actionType: CorporateActionType.rights,
        details: 'Rights Issue 1:14 @ ₹1,150.00 (CMP ₹1,280.00, 10.1% discount)',
        exDate: now.add(const Duration(days: 20)),
        recordDate: now.add(const Duration(days: 21)),
        announcementDate: now.subtract(const Duration(days: 30)),
        currentPrice: 1280.00,
        ratio: '1:14',
        remarks: 'Capital raising for 5G telecommunication infrastructure.',
      ),
    ];
  }

  List<CorporateAction> getAllActions() => List.unmodifiable(_actions);

  List<CorporateAction> getActions({
    CorporateActionType? type,
    String? searchQuery,
    bool? upcomingOnly,
  }) {
    return _actions.where((action) {
      if (type != null && action.actionType != type) {
        return false;
      }
      if (upcomingOnly == true && action.isExDatePassed) {
        return false;
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final symbolMatch = action.symbol.toLowerCase().contains(q);
        final nameMatch = action.companyName.toLowerCase().contains(q);
        final detailsMatch = action.details.toLowerCase().contains(q);
        if (!symbolMatch && !nameMatch && !detailsMatch) {
          return false;
        }
      }
      return true;
    }).toList()
      ..sort((a, b) => a.exDate.compareTo(b.exDate));
  }

  Map<CorporateActionType, int> getCountsByType() {
    final counts = <CorporateActionType, int>{};
    for (final type in CorporateActionType.values) {
      counts[type] = _actions.where((a) => a.actionType == type).length;
    }
    return counts;
  }
}
