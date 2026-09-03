class UserProfile {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String pan;
  final String bankName;
  final String bankAccountNumber;
  final bool equitySegment;
  final bool fnoSegment;
  final bool commoditySegment;
  final bool currencySegment;
  final bool biometricEnabled;
  final String kycStatus;

  const UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.pan,
    required this.bankName,
    required this.bankAccountNumber,
    this.equitySegment = true,
    this.fnoSegment = true,
    this.commoditySegment = true,
    this.currencySegment = false,
    this.biometricEnabled = false,
    this.kycStatus = 'VERIFIED',
  });

  UserProfile copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? pan,
    String? bankName,
    String? bankAccountNumber,
    bool? equitySegment,
    bool? fnoSegment,
    bool? commoditySegment,
    bool? currencySegment,
    bool? biometricEnabled,
    String? kycStatus,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      pan: pan ?? this.pan,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      equitySegment: equitySegment ?? this.equitySegment,
      fnoSegment: fnoSegment ?? this.fnoSegment,
      commoditySegment: commoditySegment ?? this.commoditySegment,
      currencySegment: currencySegment ?? this.currencySegment,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      kycStatus: kycStatus ?? this.kycStatus,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'email': email,
    'phone': phone,
    'pan': pan,
    'bankName': bankName,
    'bankAccountNumber': bankAccountNumber,
    'equitySegment': equitySegment,
    'fnoSegment': fnoSegment,
    'commoditySegment': commoditySegment,
    'currencySegment': currencySegment,
    'biometricEnabled': biometricEnabled,
    'kycStatus': kycStatus,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    userId: json['userId'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
    pan: json['pan'] as String,
    bankName: json['bankName'] as String,
    bankAccountNumber: json['bankAccountNumber'] as String,
    equitySegment: json['equitySegment'] as bool? ?? true,
    fnoSegment: json['fnoSegment'] as bool? ?? true,
    commoditySegment: json['commoditySegment'] as bool? ?? true,
    currencySegment: json['currencySegment'] as bool? ?? false,
    biometricEnabled: json['biometricEnabled'] as bool? ?? false,
    kycStatus: json['kycStatus'] as String? ?? 'VERIFIED',
  );
}

class Session {
  final String token;
  final UserProfile profile;
  final DateTime loggedInAt;
  final DateTime expiresAt;

  const Session({
    required this.token,
    required this.profile,
    required this.loggedInAt,
    required this.expiresAt,
  });

  bool get isValid => DateTime.now().isBefore(expiresAt);

  Map<String, dynamic> toJson() => {
    'token': token,
    'profile': profile.toJson(),
    'loggedInAt': loggedInAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    token: json['token'] as String,
    profile: UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
    loggedInAt: DateTime.parse(json['loggedInAt'] as String),
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );
}
