import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/ipo.dart';

final ipoRepositoryProvider = Provider<IpoRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return IpoRepository(client);
});

class IpoRepository {
  final ApiClient _client;

  IpoRepository(this._client);

  Future<List<IpoListing>> getIpos({String? status}) async {
    final query = status != null ? {'status': status} : null;
    final response = await _client.get(ApiPaths.ipo, queryParameters: query);
    final data = ResponseReader.unwrap(response);
    final list = ResponseReader.asList(data);
    return list
        .whereType<Map<String, dynamic>>()
        .map(IpoListing.fromJson)
        .toList();
  }

  Future<IpoListing> getIpoDetail(String id) async {
    final response = await _client.get(ApiPaths.ipoById(id));
    final data = ResponseReader.unwrap(response);
    final map = ResponseReader.asMap(data);
    return IpoListing.fromJson(map);
  }

  Future<IpoApplication> applyIpo({
    required String id,
    required int lots,
    required double bidPrice,
    required String upiId,
  }) async {
    final payload = {
      'lots': lots,
      'bidPrice': bidPrice,
      'upiId': upiId,
    };
    final response = await _client.post(ApiPaths.ipoApply(id), data: payload);
    final data = ResponseReader.unwrap(response);
    final map = ResponseReader.asMap(data);
    return IpoApplication.fromJson(map);
  }

  Future<List<IpoApplication>> getApplications() async {
    final response = await _client.get(ApiPaths.ipoApplications);
    final data = ResponseReader.unwrap(response);
    final list = ResponseReader.asList(data);
    return list
        .whereType<Map<String, dynamic>>()
        .map(IpoApplication.fromJson)
        .toList();
  }

  Future<void> cancelApplication(String id) async {
    await _client.delete(ApiPaths.ipoApplicationById(id));
  }
}
