import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/models.dart';

class PinnedInstrumentsRepository {
  final ApiClient _apiClient;

  PinnedInstrumentsRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<List<String>> getPinnedSymbols() async {
    final data = await _apiClient.get(ApiPaths.pinnedInstruments);
    final list = ResponseReader.list(data, 'symbols');
    if (list.isNotEmpty) {
      return list.map((e) => e.toString()).toList();
    }
    final obj = ResponseReader.object(data);
    if (obj.containsKey('symbols') && obj['symbols'] is List) {
      return (obj['symbols'] as List).map((e) => e.toString()).toList();
    }
    return const [];
  }

  Future<List<String>> updatePinnedSymbols(List<String> symbols) async {
    final limited = symbols.take(4).toList();
    final data = await _apiClient.put(
      ApiPaths.pinnedInstruments,
      data: {'symbols': limited},
    );
    final list = ResponseReader.list(data, 'symbols');
    if (list.isNotEmpty) {
      return list.map((e) => e.toString()).toList();
    }
    return limited;
  }
}

final pinnedInstrumentsRepositoryProvider =
    Provider<PinnedInstrumentsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PinnedInstrumentsRepository(apiClient: apiClient);
});

final pinnedInstrumentsProvider =
    FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(pinnedInstrumentsRepositoryProvider);
  return repo.getPinnedSymbols();
});

class PinnedScriptsState {
  final Instrument? leftScript;
  final Instrument? rightScript;

  const PinnedScriptsState({
    this.leftScript,
    this.rightScript,
  });

  PinnedScriptsState copyWith({
    Instrument? leftScript,
    Instrument? rightScript,
    bool clearLeft = false,
    bool clearRight = false,
  }) {
    return PinnedScriptsState(
      leftScript: clearLeft ? null : (leftScript ?? this.leftScript),
      rightScript: clearRight ? null : (rightScript ?? this.rightScript),
    );
  }
}

class PinnedScriptsNotifier extends StateNotifier<PinnedScriptsState> {
  final Ref _ref;

  PinnedScriptsNotifier(this._ref) : super(const PinnedScriptsState());

  void setLeftScript(Instrument? script) {
    if (script == null) {
      state = state.copyWith(clearLeft: true);
    } else {
      state = state.copyWith(leftScript: script);
      _persistPinned();
    }
  }

  void setRightScript(Instrument? script) {
    if (script == null) {
      state = state.copyWith(clearRight: true);
    } else {
      state = state.copyWith(rightScript: script);
      _persistPinned();
    }
  }

  void clearSlot(bool isLeft) {
    if (isLeft) {
      state = state.copyWith(clearLeft: true);
    } else {
      state = state.copyWith(clearRight: true);
    }
    _persistPinned();
  }

  void _persistPinned() {
    final symbols = <String>[];
    if (state.leftScript != null) symbols.add(state.leftScript!.symbol);
    if (state.rightScript != null) symbols.add(state.rightScript!.symbol);
    if (symbols.isNotEmpty) {
      _ref.read(pinnedInstrumentsRepositoryProvider).updatePinnedSymbols(symbols);
    }
  }
}

final pinnedScriptsProvider =
    StateNotifierProvider<PinnedScriptsNotifier, PinnedScriptsState>((ref) {
  return PinnedScriptsNotifier(ref);
});

