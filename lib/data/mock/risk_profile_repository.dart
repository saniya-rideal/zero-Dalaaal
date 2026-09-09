import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/investor_risk_profile.dart';

final riskProfileRepositoryProvider = Provider<RiskProfileRepository>((ref) {
  return RiskProfileRepository();
});

class RiskProfileNotifier extends StateNotifier<InvestorRiskProfile> {
  final RiskProfileRepository _repo;

  RiskProfileNotifier(this._repo) : super(_repo.profile);

  void updateProfile(InvestorRiskProfile updated) {
    _repo.updateProfile(updated);
    state = updated;
  }

  void submitAnswers(Map<int, int> answers) {
    final updated = InvestorRiskProfile.fromAnswers(answers);
    _repo.updateProfile(updated);
    state = updated;
  }
}

final riskProfileProvider =
    StateNotifierProvider<RiskProfileNotifier, InvestorRiskProfile>((ref) {
  final repo = ref.watch(riskProfileRepositoryProvider);
  return RiskProfileNotifier(repo);
});

class RiskProfileRepository {
  InvestorRiskProfile _profile = InvestorRiskProfile.defaultModerate();

  InvestorRiskProfile get profile => _profile;

  void updateProfile(InvestorRiskProfile updated) {
    _profile = updated;
  }
}
