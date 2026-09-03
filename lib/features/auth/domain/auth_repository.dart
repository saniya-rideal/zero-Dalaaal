import '../../../data/models/models.dart';

abstract class AuthRepository {
  Future<Session> login(String userId, String password);
  Future<Session> verifyTotp(String code);
  Future<bool> verifyPin(String pin);
  Future<void> setPin(String pin);
  Future<bool> hasSavedSession();
  Future<Session?> getSavedSession();
  Future<void> logout();
}
