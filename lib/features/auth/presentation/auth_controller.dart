import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../data/real_auth_repository.dart';
import '../domain/auth_repository.dart';

class AuthState {
  final bool isLoading;
  final Session? session;
  final String? errorMessage;
  final bool isAuthenticated;
  final bool requiresPinUnlock;
  final String? tempToken;
  final bool requiresPinSetup;
  final String? lastRegisteredClientId;

  const AuthState({
    this.isLoading = false,
    this.session,
    this.errorMessage,
    this.isAuthenticated = false,
    this.requiresPinUnlock = false,
    this.tempToken,
    this.requiresPinSetup = false,
    this.lastRegisteredClientId,
  });

  AuthState copyWith({
    bool? isLoading,
    Session? session,
    String? errorMessage,
    bool? isAuthenticated,
    bool? requiresPinUnlock,
    String? tempToken,
    bool? requiresPinSetup,
    String? lastRegisteredClientId,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      session: session ?? this.session,
      errorMessage: errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      requiresPinUnlock: requiresPinUnlock ?? this.requiresPinUnlock,
      tempToken: tempToken ?? this.tempToken,
      requiresPinSetup: requiresPinSetup ?? this.requiresPinSetup,
      lastRegisteredClientId: lastRegisteredClientId ?? this.lastRegisteredClientId,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(const AuthState());

  Future<void> checkInitialSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final session = await _repo.getSavedSession();
      if (session != null) {
        state = state.copyWith(
          isLoading: false,
          session: session,
          isAuthenticated: true,
          requiresPinUnlock: false,
        );
        return;
      }
    } catch (_) {}
    state = state.copyWith(
      isLoading: false,
      session: null,
      isAuthenticated: false,
      requiresPinUnlock: false,
    );
  }

  Future<LoginResult?> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repo.login(identifier, password);
      state = state.copyWith(
        isLoading: false,
        tempToken: result.tempToken,
        requiresPinSetup: result.requiresPinSetup,
      );
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<bool> verifyPin(String pin) async {
    final tempToken = state.tempToken;
    if (tempToken == null || tempToken.isEmpty) {
      state = state.copyWith(errorMessage: 'Session expired. Please log in again.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final session = await _repo.verifyPin(tempToken: tempToken, pin: pin);
      state = state.copyWith(
        isLoading: false,
        session: session,
        isAuthenticated: true,
        requiresPinUnlock: false,
        tempToken: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> setPin(String pin) async {
    final tempToken = state.tempToken;
    if (tempToken == null || tempToken.isEmpty) {
      state = state.copyWith(errorMessage: 'Session expired. Please log in again.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final session = await _repo.setPin(tempToken: tempToken, pin: pin);
      state = state.copyWith(
        isLoading: false,
        session: session,
        isAuthenticated: true,
        requiresPinUnlock: false,
        tempToken: null,
        requiresPinSetup: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> verifyAppPin(String pin) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final valid = await _repo.verifyAppPin(pin);
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

  Future<RegisterResult?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String pin,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repo.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        pin: pin,
      );
      state = state.copyWith(
        isLoading: false,
        session: result.session,
        isAuthenticated: true,
        lastRegisteredClientId: result.clientId,
      );
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<bool> forgotPassword(String identifier) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.forgotPassword(identifier);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.resetPassword(
        identifier: identifier,
        otp: otp,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> changedFields) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedProfile = await _repo.updateProfile(changedFields);
      if (state.session != null) {
        final updatedSession = Session(
          token: state.session!.token,
          profile: updatedProfile,
          loggedInAt: state.session!.loggedInAt,
          expiresAt: state.session!.expiresAt,
        );
        state = state.copyWith(isLoading: false, session: updatedSession);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
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
