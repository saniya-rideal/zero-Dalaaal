import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fatca_declaration.dart';

final fatcaRepositoryProvider = Provider<FatcaRepository>((ref) {
  return FatcaRepository();
});

class FatcaNotifier extends StateNotifier<FatcaDeclaration> {
  final FatcaRepository _repo;

  FatcaNotifier(this._repo) : super(_repo.declaration);

  void update(FatcaDeclaration newDeclaration) {
    _repo.updateDeclaration(newDeclaration);
    state = newDeclaration;
  }
}

final fatcaDeclarationProvider =
    StateNotifierProvider<FatcaNotifier, FatcaDeclaration>((ref) {
  final repo = ref.watch(fatcaRepositoryProvider);
  return FatcaNotifier(repo);
});

class FatcaRepository {
  FatcaDeclaration _declaration = FatcaDeclaration.defaultIndianResident();

  FatcaDeclaration get declaration => _declaration;

  void updateDeclaration(FatcaDeclaration updated) {
    _declaration = updated;
  }

  bool get isComplied =>
      _declaration.status == 'VERIFIED' || _declaration.status == 'DECLARED';
}
