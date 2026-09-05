import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/instrument.dart';

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
  PinnedScriptsNotifier() : super(const PinnedScriptsState());

  void setLeftScript(Instrument? script) {
    if (script == null) {
      state = state.copyWith(clearLeft: true);
    } else {
      state = state.copyWith(leftScript: script);
    }
  }

  void setRightScript(Instrument? script) {
    if (script == null) {
      state = state.copyWith(clearRight: true);
    } else {
      state = state.copyWith(rightScript: script);
    }
  }

  void clearSlot(bool isLeft) {
    if (isLeft) {
      state = state.copyWith(clearLeft: true);
    } else {
      state = state.copyWith(clearRight: true);
    }
  }
}

final pinnedScriptsProvider =
    StateNotifierProvider<PinnedScriptsNotifier, PinnedScriptsState>((ref) {
  return PinnedScriptsNotifier();
});
