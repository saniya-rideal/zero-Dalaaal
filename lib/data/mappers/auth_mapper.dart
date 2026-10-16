import '../models/models.dart';

class AuthMapper {
  AuthMapper._();

  /// Maps backend `data.user` to domain `UserProfile`
  static UserProfile userProfileFromJson(Map<String, dynamic> json) {
    final clientId = (json['clientId'] ?? json['userId'] ?? json['id'] ?? json['_id'] ?? '').toString();
    final name = (json['name'] ?? '').toString();
    final email = (json['email'] ?? '').toString();
    final phone = (json['phone'] ?? json['mobile'] ?? '').toString();
    final pan = (json['pan'] ?? '').toString();
    final bankName = (json['bankName'] ?? '').toString();
    final bankAccountNumber = (json['bankAccountNumber'] ?? json['bankAccountLast4'] ?? '').toString();
    final kycStatus = (json['kycStatus'] ?? 'NOT_STARTED').toString();
    final dob = json['dob']?.toString();
    final address = json['address']?.toString();
    final hasPin = json['hasPin'] is bool ? json['hasPin'] as bool : true;

    return UserProfile(
      userId: clientId.isNotEmpty ? clientId : (json['id'] ?? json['_id'] ?? '').toString(),
      name: name,
      email: email,
      phone: phone,
      pan: pan,
      bankName: bankName,
      bankAccountNumber: bankAccountNumber,
      kycStatus: kycStatus,
      dob: dob,
      address: address,
      hasPin: hasPin,
      equitySegment: json['equitySegment'] as bool? ?? true,
      fnoSegment: json['fnoSegment'] as bool? ?? true,
      commoditySegment: json['commoditySegment'] as bool? ?? true,
      currencySegment: json['currencySegment'] as bool? ?? false,
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
    );
  }

  /// Maps backend auth success response `data` (with `user`, `accessToken`, etc.) to `Session`
  static Session sessionFromData(Map<String, dynamic> data) {
    final userMap = data['user'] is Map<String, dynamic> ? data['user'] as Map<String, dynamic> : data;
    final profile = userProfileFromJson(userMap);
    final accessToken = (data['accessToken'] ?? data['token'] ?? '').toString();

    return Session(
      token: accessToken,
      profile: profile,
      loggedInAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 365)), // Expiry handled by token refresh on 401
    );
  }
}
