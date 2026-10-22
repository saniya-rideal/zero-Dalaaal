import '../../../data/models/models.dart';

class LoginResult {
  final bool requiresPin;
  final bool requiresPinSetup;
  final String tempToken;
  final String message;

  const LoginResult({
    required this.requiresPin,
    required this.requiresPinSetup,
    required this.tempToken,
    this.message = '',
  });
}

class RegisterResult {
  final String clientId;
  final Session session;

  const RegisterResult({
    required this.clientId,
    required this.session,
  });
}

abstract class AuthRepository {
  Future<LoginResult> login(String identifier, String password);
  Future<LoginResult> loginWithGoogle(String idToken);
  Future<Session> verifyPin({required String tempToken, required String pin});
  Future<Session> setPin({required String tempToken, required String pin});
  Future<bool> verifyAppPin(String pin);
  Future<bool> changePin({required String currentPin, required String newPin});
  Future<void> sendOtp({required String identifier, String type = 'REGISTER'});
  Future<bool> verifyOtp({required String identifier, required String otp, String type = 'REGISTER'});
  Future<RegisterResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String pin,
  });
  Future<void> forgotPassword(String identifier);
  Future<void> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  });
  Future<UserProfile> getProfile();
  Future<UserProfile> updateProfile(Map<String, dynamic> changedFields);
  Future<bool> hasSavedSession();
  Future<Session?> getSavedSession();
  Future<void> logout();
}
