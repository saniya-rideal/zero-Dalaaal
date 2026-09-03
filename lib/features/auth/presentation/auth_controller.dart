import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../data/mock_auth_repository.dart';
import '../domain/auth_repository.dart';

class AuthState {
  final bool isLoading;
  final Session? session;
  final String? errorMessage;
  final bool isAuthenticated;
  final bool requiresPinUnlock;

  const AuthState({
    this.isLoading = false,
    this.session,
    this.errorMessage,
    this.isAuthenticated = false,
    this.requiresPinUnlock = false,
  });

  AuthState copyWith({
    bool? isLoading,
    Session? session,
    String? errorMessage,
    bool? isAuthenticated,
    bool? requiresPinUnlock,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      session: session ?? this.session,
      errorMessage: errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      requiresPinUnlock: requiresPinUnlock ?? this.requiresPinUnlock,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(const AuthState());

  Future<void> checkInitialSession() async {
    state = state.copyWith(isLoading: true);
    final hasSession = await _repo.hasSavedSession();
    if (hasSession) {
      final session = await _repo.getSavedSession();
      if (session != null && session.isValid) {
        state = state.copyWith(
          isLoading: false,
          session: session,
          requiresPinUnlock: true,
        );
        return;
      }
    }
    state = state.copyWith(isLoading: false, requiresPinUnlock: false);
  }

  Future<bool> login(String userId, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final session = await _repo.login(userId, password);
      state = state.copyWith(isLoading: false, session: session);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> verifyTotp(String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final session = await _repo.verifyTotp(code);
      state = state.copyWith(
        isLoading: false,
        session: session,
        isAuthenticated: true,
        requiresPinUnlock: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final valid = await _repo.verifyPin(pin);
      if (valid) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          requiresPinUnlock: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Incorrect PIN. Please try again.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});
