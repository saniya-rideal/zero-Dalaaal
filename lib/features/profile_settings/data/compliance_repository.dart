import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/fatca_declaration.dart';
import '../../../data/models/investor_risk_profile.dart';

class ComplianceRepository {
  final ApiClient _apiClient;

  ComplianceRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // --- Risk Profiling (Section 3.5) ---
  Future<InvestorRiskProfile> getRiskProfile() async {
    final data = await _apiClient.get(ApiPaths.riskProfile);
    final obj = ResponseReader.object(data);
    return InvestorRiskProfile.fromJson(obj);
  }

  Future<InvestorRiskProfile> submitRiskProfile({
    required String investmentHorizon,
    required String experienceLevel,
    required String lossTolerance,
    required List<Map<String, dynamic>> answers,
  }) async {
    final data = await _apiClient.post(
      ApiPaths.riskProfile,
      data: {
        'investmentHorizon': investmentHorizon,
        'experienceLevel': experienceLevel,
        'lossTolerance': lossTolerance,
        'answers': answers,
      },
    );
    final obj = ResponseReader.object(data);
    return InvestorRiskProfile.fromJson(obj);
  }

  // --- FATCA Declaration (Section 3.6) ---
  Future<FatcaDeclaration> getFatcaDeclaration() async {
    final data = await _apiClient.get(ApiPaths.fatca);
    final obj = ResponseReader.object(data);
    return FatcaDeclaration.fromJson(obj);
  }

  Future<FatcaDeclaration> submitFatcaDeclaration(Map<String, dynamic> fatcaData) async {
    final data = await _apiClient.post(
      ApiPaths.fatca,
      data: fatcaData,
    );
    final obj = ResponseReader.object(data);
    return FatcaDeclaration.fromJson(obj);
  }

  // --- Nominee Management (Section 3.7) ---
  Future<List<dynamic>> getNominees() async {
    final data = await _apiClient.get(ApiPaths.nominees);
    final items = ResponseReader.list(data, 'nominees');
    return items.isNotEmpty ? items : ResponseReader.list(data);
  }

  Future<List<dynamic>> saveNominees(List<Map<String, dynamic>> nominees) async {
    final data = await _apiClient.post(
      ApiPaths.nominees,
      data: {'nominees': nominees},
    );
    final items = ResponseReader.list(data, 'nominees');
    return items.isNotEmpty ? items : ResponseReader.list(data);
  }
}

final complianceRepositoryProvider = Provider<ComplianceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ComplianceRepository(apiClient: apiClient);
});

class RiskProfileNotifier extends StateNotifier<InvestorRiskProfile> {
  final ComplianceRepository _repo;

  RiskProfileNotifier(this._repo) : super(InvestorRiskProfile.empty()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final remote = await _repo.getRiskProfile();
      state = remote;
    } catch (_) {}
  }

  Future<void> updateProfile(InvestorRiskProfile updated) async {
    state = updated;
    try {
      await _repo.submitRiskProfile(
        investmentHorizon: 'MEDIUM_TERM',
        experienceLevel: 'INTERMEDIATE',
        lossTolerance: updated.category.name.toUpperCase(),
        answers: updated.answers.entries
            .map((e) => {'questionId': 'q${e.key}', 'answer': 'option_${e.value}'})
            .toList(),
      );
    } catch (_) {}
  }

  Future<void> submitAnswers(Map<int, int> answers) async {
    final updated = InvestorRiskProfile.fromAnswers(answers);
    state = updated;
    try {
      final remote = await _repo.submitRiskProfile(
        investmentHorizon: 'MEDIUM_TERM',
        experienceLevel: 'INTERMEDIATE',
        lossTolerance: updated.category.name.toUpperCase(),
        answers: answers.entries
            .map((e) => {'questionId': 'q${e.key}', 'answer': 'option_${e.value}'})
            .toList(),
      );
      state = remote;
    } catch (_) {}
  }
}

final riskProfileProvider =
    StateNotifierProvider<RiskProfileNotifier, InvestorRiskProfile>((ref) {
  final repo = ref.watch(complianceRepositoryProvider);
  return RiskProfileNotifier(repo);
});

class FatcaNotifier extends StateNotifier<FatcaDeclaration> {
  final ComplianceRepository _repo;

  FatcaNotifier(this._repo) : super(FatcaDeclaration.defaultIndianResident()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final remote = await _repo.getFatcaDeclaration();
      state = remote;
    } catch (_) {}
  }

  Future<void> update(FatcaDeclaration newDeclaration) async {
    state = newDeclaration;
    try {
      final remote = await _repo.submitFatcaDeclaration(newDeclaration.toJson());
      state = remote;
    } catch (_) {}
  }
}

final fatcaDeclarationProvider =
    StateNotifierProvider<FatcaNotifier, FatcaDeclaration>((ref) {
  final repo = ref.watch(complianceRepositoryProvider);
  return FatcaNotifier(repo);
});

final nomineesProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(complianceRepositoryProvider);
  return repo.getNominees();
});
