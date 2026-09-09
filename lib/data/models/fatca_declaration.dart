/// Strongly typed model representing FATCA / CRS Self-Declaration and PEP compliance.
library;

class FatcaDeclaration {
  final bool isIndianTaxResidentOnly;
  final bool isUsPerson;
  final bool isPoliticallyExposed;
  final bool isRelatedToPoliticallyExposed;
  final String birthCountry;
  final String birthCity;
  final String? taxResidencyCountry;
  final String? taxIdentificationNumber; // TIN or SSN for non-residents
  final String occupation;
  final String grossAnnualIncomeBracket;
  final DateTime declarationTimestamp;
  final String status; // 'VERIFIED', 'DECLARED', 'PENDING'

  const FatcaDeclaration({
    required this.isIndianTaxResidentOnly,
    required this.isUsPerson,
    required this.isPoliticallyExposed,
    required this.isRelatedToPoliticallyExposed,
    required this.birthCountry,
    required this.birthCity,
    this.taxResidencyCountry,
    this.taxIdentificationNumber,
    required this.occupation,
    required this.grossAnnualIncomeBracket,
    required this.declarationTimestamp,
    required this.status,
  });

  /// Standard default declaration for an Indian resident trader
  factory FatcaDeclaration.defaultIndianResident() {
    return FatcaDeclaration(
      isIndianTaxResidentOnly: true,
      isUsPerson: false,
      isPoliticallyExposed: false,
      isRelatedToPoliticallyExposed: false,
      birthCountry: 'India',
      birthCity: 'Mumbai',
      taxResidencyCountry: null,
      taxIdentificationNumber: null,
      occupation: 'Private Sector',
      grossAnnualIncomeBracket: '₹5L - ₹10L',
      declarationTimestamp: DateTime.now(),
      status: 'VERIFIED',
    );
  }

  FatcaDeclaration copyWith({
    bool? isIndianTaxResidentOnly,
    bool? isUsPerson,
    bool? isPoliticallyExposed,
    bool? isRelatedToPoliticallyExposed,
    String? birthCountry,
    String? birthCity,
    String? taxResidencyCountry,
    String? taxIdentificationNumber,
    String? occupation,
    String? grossAnnualIncomeBracket,
    DateTime? declarationTimestamp,
    String? status,
  }) {
    return FatcaDeclaration(
      isIndianTaxResidentOnly:
          isIndianTaxResidentOnly ?? this.isIndianTaxResidentOnly,
      isUsPerson: isUsPerson ?? this.isUsPerson,
      isPoliticallyExposed: isPoliticallyExposed ?? this.isPoliticallyExposed,
      isRelatedToPoliticallyExposed:
          isRelatedToPoliticallyExposed ?? this.isRelatedToPoliticallyExposed,
      birthCountry: birthCountry ?? this.birthCountry,
      birthCity: birthCity ?? this.birthCity,
      taxResidencyCountry: taxResidencyCountry ?? this.taxResidencyCountry,
      taxIdentificationNumber:
          taxIdentificationNumber ?? this.taxIdentificationNumber,
      occupation: occupation ?? this.occupation,
      grossAnnualIncomeBracket:
          grossAnnualIncomeBracket ?? this.grossAnnualIncomeBracket,
      declarationTimestamp: declarationTimestamp ?? this.declarationTimestamp,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'isIndianTaxResidentOnly': isIndianTaxResidentOnly,
        'isUsPerson': isUsPerson,
        'isPoliticallyExposed': isPoliticallyExposed,
        'isRelatedToPoliticallyExposed': isRelatedToPoliticallyExposed,
        'birthCountry': birthCountry,
        'birthCity': birthCity,
        'taxResidencyCountry': taxResidencyCountry,
        'taxIdentificationNumber': taxIdentificationNumber,
        'occupation': occupation,
        'grossAnnualIncomeBracket': grossAnnualIncomeBracket,
        'declarationTimestamp': declarationTimestamp.toIso8601String(),
        'status': status,
      };

  factory FatcaDeclaration.fromJson(Map<String, dynamic> json) =>
      FatcaDeclaration(
        isIndianTaxResidentOnly: json['isIndianTaxResidentOnly'] as bool,
        isUsPerson: json['isUsPerson'] as bool,
        isPoliticallyExposed: json['isPoliticallyExposed'] as bool,
        isRelatedToPoliticallyExposed:
            json['isRelatedToPoliticallyExposed'] as bool,
        birthCountry: json['birthCountry'] as String,
        birthCity: json['birthCity'] as String,
        taxResidencyCountry: json['taxResidencyCountry'] as String?,
        taxIdentificationNumber: json['taxIdentificationNumber'] as String?,
        occupation: json['occupation'] as String,
        grossAnnualIncomeBracket: json['grossAnnualIncomeBracket'] as String,
        declarationTimestamp:
            DateTime.parse(json['declarationTimestamp'] as String),
        status: json['status'] as String,
      );
}
