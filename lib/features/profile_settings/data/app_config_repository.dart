import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';

class SystemAppConfig {
  final bool isUnderMaintenance;
  final String maintenanceMessage;
  final String minSupportedVersion;
  final String latestVersion;
  final String? forceUpdateUrl;

  const SystemAppConfig({
    this.isUnderMaintenance = false,
    this.maintenanceMessage = '',
    this.minSupportedVersion = '1.0.0',
    this.latestVersion = '1.0.0',
    this.forceUpdateUrl,
  });

  factory SystemAppConfig.fromJson(Map<String, dynamic> json) {
    return SystemAppConfig(
      isUnderMaintenance: json['isUnderMaintenance'] as bool? ?? false,
      maintenanceMessage: json['maintenanceMessage']?.toString() ?? '',
      minSupportedVersion: json['minSupportedVersion']?.toString() ?? '1.0.0',
      latestVersion: json['latestVersion']?.toString() ?? '1.0.0',
      forceUpdateUrl: json['forceUpdateUrl']?.toString(),
    );
  }
}

class AppConfigRepository {
  final ApiClient _apiClient;

  AppConfigRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<SystemAppConfig> getSystemAppConfig() async {
    final data = await _apiClient.get(ApiPaths.appConfig);
    final obj = ResponseReader.object(data);
    return SystemAppConfig.fromJson(obj);
  }

  Future<String> getLegalDocument(String slug) async {
    final data = await _apiClient.get(ApiPaths.legal(slug));
    if (data is Map<String, dynamic>) {
      return (data['content'] ?? data['document'] ?? data['text'] ?? '').toString();
    }
    if (data is String) return data;
    return '';
  }
}

final appConfigRepositoryProvider = Provider<AppConfigRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AppConfigRepository(apiClient: apiClient);
});

final systemAppConfigProvider = FutureProvider<SystemAppConfig>((ref) async {
  final repo = ref.watch(appConfigRepositoryProvider);
  return repo.getSystemAppConfig();
});

final legalDocumentProvider = FutureProvider.family<String, String>((ref, slug) async {
  final repo = ref.watch(appConfigRepositoryProvider);
  return repo.getLegalDocument(slug);
});

final fundsLegalDisclaimerProvider = FutureProvider<String>((ref) async {
  final repo = ref.watch(appConfigRepositoryProvider);
  try {
    final doc = await repo.getLegalDocument('disclaimer');
    if (doc.trim().isNotEmpty) return doc.trim();
  } catch (_) {}
  try {
    final terms = await repo.getLegalDocument('terms-and-conditions');
    final firstLine = terms.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    if (firstLine.isNotEmpty) return firstLine;
  } catch (_) {}
  return 'Regulatory disclosure unavailable';
});
