class UserProfile {
  final String userId; // maps to clientId (e.g. ZD482915)
  final String name;
  final String email;
  final String phone;
  final String pan;
  final String bankName;
  final String bankAccountNumber; // already masked (e.g. •••• •••• 1234)
  final bool equitySegment;
  final bool fnoSegment;
  final bool commoditySegment;
  final bool currencySegment;
  final bool biometricEnabled;
  final String kycStatus;
  final String? dob;
  final String? address;
  final bool hasPin;

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
    this.dob,
    this.address,
    this.hasPin = true,
  });

  String get clientId => userId;

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
    String? dob,
    String? address,
    bool? hasPin,
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
      dob: dob ?? this.dob,
      address: address ?? this.address,
      hasPin: hasPin ?? this.hasPin,
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
    'dob': dob,
    'address': address,
    'hasPin': hasPin,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    userId: (json['userId'] ?? json['clientId'] ?? json['id'] ?? json['_id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    phone: (json['phone'] ?? json['mobile'] ?? '').toString(),
    pan: (json['pan'] ?? '').toString(),
    bankName: (json['bankName'] ?? '').toString(),
    bankAccountNumber: (json['bankAccountNumber'] ?? json['bankAccountLast4'] ?? '').toString(),
    equitySegment: json['equitySegment'] as bool? ?? true,
    fnoSegment: json['fnoSegment'] as bool? ?? true,
    commoditySegment: json['commoditySegment'] as bool? ?? true,
    currencySegment: json['currencySegment'] as bool? ?? false,
    biometricEnabled: json['biometricEnabled'] as bool? ?? false,
    kycStatus: (json['kycStatus'] ?? 'NOT_STARTED').toString(),
    dob: json['dob']?.toString(),
    address: json['address']?.toString(),
    hasPin: json['hasPin'] as bool? ?? true,
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
    token: (json['token'] ?? json['accessToken'] ?? '').toString(),
    profile: UserProfile.fromJson(json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : (json['user'] is Map<String, dynamic> ? json['user'] as Map<String, dynamic> : {})),
    loggedInAt: json['loggedInAt'] != null
        ? DateTime.tryParse(json['loggedInAt'].toString()) ?? DateTime.now()
        : DateTime.now(),
    expiresAt: json['expiresAt'] != null
        ? DateTime.tryParse(json['expiresAt'].toString()) ?? DateTime.now().add(const Duration(days: 365))
        : DateTime.now().add(const Duration(days: 365)),
  );
}
