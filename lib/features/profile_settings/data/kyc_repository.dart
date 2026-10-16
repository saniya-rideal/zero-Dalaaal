import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';

class KycStatusData {
  final String status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final List<dynamic> documents;

  const KycStatusData({
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.documents = const [],
  });

  factory KycStatusData.fromJson(Map<String, dynamic> json) {
    return KycStatusData(
      status: (json['status'] ?? json['kycStatus'] ?? 'NOT_STARTED').toString(),
      submittedAt: json['submittedAt'] != null ? DateTime.tryParse(json['submittedAt'].toString()) : null,
      reviewedAt: json['reviewedAt'] != null ? DateTime.tryParse(json['reviewedAt'].toString()) : null,
      rejectionReason: json['rejectionReason']?.toString(),
      documents: json['documents'] is List ? json['documents'] as List : const [],
    );
  }
}

class KycRepository {
  final ApiClient _apiClient;

  KycRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<KycStatusData> getKycStatus() async {
    final data = await _apiClient.get(ApiPaths.kycStatus);
    final obj = ResponseReader.object(data);
    return KycStatusData.fromJson(obj);
  }

  Future<Map<String, dynamic>> uploadDocument({
    required String documentType,
    required String fileName,
    required String fileData,
  }) async {
    final data = await _apiClient.post(
      ApiPaths.kycUpload,
      data: {
        'documentType': documentType,
        'fileName': fileName,
        'fileData': fileData,
      },
    );
    return ResponseReader.object(data);
  }

  Future<KycStatusData> submitKyc({
    required String panNumber,
    required String panDocumentUrl,
    required String aadhaarNumber,
    required String aadhaarDocumentUrl,
    String? fullName,
    String? dob,
    String? address,
    String addressProofType = 'AADHAAR',
    String? addressProofUrl,
  }) async {
    final Map<String, dynamic> payload = {
      'panNumber': panNumber,
      'panDocumentUrl': panDocumentUrl,
      'aadhaarNumber': aadhaarNumber,
      'aadhaarDocumentUrl': aadhaarDocumentUrl,
      'addressProofType': addressProofType,
      'addressProofUrl': addressProofUrl ?? aadhaarDocumentUrl,
    };
    if (fullName != null && fullName.isNotEmpty) payload['fullName'] = fullName;
    if (dob != null && dob.isNotEmpty) payload['dob'] = dob;
    if (address != null && address.isNotEmpty) payload['address'] = address;

    final data = await _apiClient.post(
      ApiPaths.kycSubmit,
      data: payload,
    );
    final obj = ResponseReader.object(data);
    return KycStatusData.fromJson(obj);
  }
}

final kycRepositoryProvider = Provider<KycRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return KycRepository(apiClient: apiClient);
});

final kycStatusProvider = FutureProvider<KycStatusData>((ref) async {
  final repo = ref.watch(kycRepositoryProvider);
  return repo.getKycStatus();
});
