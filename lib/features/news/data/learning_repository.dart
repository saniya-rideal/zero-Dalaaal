import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/learning_content.dart';

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return LearningRepository(client);
});

class LearningRepository {
  final ApiClient _client;

  LearningRepository(this._client);

  Future<List<LearningModule>> getModules() async {
    final response = await _client.get(ApiPaths.learningModules);
    final data = ResponseReader.unwrap(response);
    final list = ResponseReader.asList(data);
    return list
        .whereType<Map<String, dynamic>>()
        .map(LearningModule.fromJson)
        .toList();
  }

  Future<LearningModule> getModuleDetail(String id) async {
    final response = await _client.get(ApiPaths.learningModuleDetail(id));
    final data = ResponseReader.unwrap(response);
    final map = ResponseReader.asMap(data);
    return LearningModule.fromJson(map);
  }

  Future<Map<String, dynamic>> submitQuiz({
    required String lessonId,
    required List<dynamic> answers,
  }) async {
    final response = await _client.post(
      ApiPaths.learningQuizSubmit(lessonId),
      data: {'answers': answers},
    );
    final data = ResponseReader.unwrap(response);
    return ResponseReader.asMap(data);
  }
}
