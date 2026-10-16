import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/response_reader.dart';
import '../../../data/models/news_article.dart';

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return NewsRepository(client);
});

class NewsRepository {
  final ApiClient _client;

  NewsRepository(this._client);

  Future<List<NewsArticle>> getArticles({
    String? category,
    String? symbol,
    int page = 1,
    int limit = 20,
  }) async {
    final query = {
      if (category != null && category.isNotEmpty && category != 'ALL')
        'category': category,
      if (symbol != null && symbol.isNotEmpty) 'symbol': symbol,
      'page': page,
      'limit': limit,
    };
    final response = await _client.get(ApiPaths.news, queryParameters: query);
    final data = ResponseReader.unwrap(response);
    final list = ResponseReader.asList(data);
    return list
        .whereType<Map<String, dynamic>>()
        .map(NewsArticle.fromJson)
        .toList();
  }

  Future<NewsArticle> getArticle(String id) async {
    final response = await _client.get(ApiPaths.newsById(id));
    final data = ResponseReader.unwrap(response);
    final map = ResponseReader.asMap(data);
    return NewsArticle.fromJson(map);
  }
}
