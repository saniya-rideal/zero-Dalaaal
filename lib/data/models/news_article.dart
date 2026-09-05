import 'package:flutter/foundation.dart';

enum NewsCategory {
  ALL,
  EQUITIES,
  FNO,
  COMMODITIES,
  FOREX,
  ECONOMY,
}

enum NewsSentiment {
  BULLISH,
  BEARISH,
  NEUTRAL,
}

@immutable
class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String fullContent;
  final DateTime timestamp;
  final String source;
  final String? sourceUrl;
  final NewsCategory category;
  final NewsSentiment sentiment;
  final List<String> relatedTokens;
  final List<String> relatedSymbols;
  final int readTimeMinutes;
  final String? imageUrl;
  final List<String> keyTakeaways;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.fullContent,
    required this.timestamp,
    required this.source,
    this.sourceUrl,
    required this.category,
    this.sentiment = NewsSentiment.NEUTRAL,
    this.relatedTokens = const [],
    this.relatedSymbols = const [],
    this.readTimeMinutes = 3,
    this.imageUrl,
    this.keyTakeaways = const [],
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'fullContent': fullContent,
    'timestamp': timestamp.toIso8601String(),
    'source': source,
    'sourceUrl': sourceUrl,
    'category': category.name,
    'sentiment': sentiment.name,
    'relatedTokens': relatedTokens,
    'relatedSymbols': relatedSymbols,
    'readTimeMinutes': readTimeMinutes,
    'imageUrl': imageUrl,
    'keyTakeaways': keyTakeaways,
  };

  factory NewsArticle.fromJson(Map<String, dynamic> json) => NewsArticle(
    id: json['id'] as String,
    title: json['title'] as String,
    summary: json['summary'] as String,
    fullContent: json['fullContent'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    source: json['source'] as String,
    sourceUrl: json['sourceUrl'] as String?,
    category: NewsCategory.values.byName(json['category'] as String),
    sentiment: json['sentiment'] != null
        ? NewsSentiment.values.byName(json['sentiment'] as String)
        : NewsSentiment.NEUTRAL,
    relatedTokens: (json['relatedTokens'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    relatedSymbols: (json['relatedSymbols'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    readTimeMinutes: (json['readTimeMinutes'] as num?)?.toInt() ?? 3,
    imageUrl: json['imageUrl'] as String?,
    keyTakeaways: (json['keyTakeaways'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
  );

  NewsArticle copyWith({
    String? id,
    String? title,
    String? summary,
    String? fullContent,
    DateTime? timestamp,
    String? source,
    String? sourceUrl,
    NewsCategory? category,
    NewsSentiment? sentiment,
    List<String>? relatedTokens,
    List<String>? relatedSymbols,
    int? readTimeMinutes,
    String? imageUrl,
    List<String>? keyTakeaways,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      fullContent: fullContent ?? this.fullContent,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      category: category ?? this.category,
      sentiment: sentiment ?? this.sentiment,
      relatedTokens: relatedTokens ?? this.relatedTokens,
      relatedSymbols: relatedSymbols ?? this.relatedSymbols,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
      imageUrl: imageUrl ?? this.imageUrl,
      keyTakeaways: keyTakeaways ?? this.keyTakeaways,
    );
  }
}
