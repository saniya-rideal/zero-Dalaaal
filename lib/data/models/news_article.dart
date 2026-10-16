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

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    final catStr = (json['category'] ?? 'EQUITIES').toString().toUpperCase();
    NewsCategory cat = NewsCategory.EQUITIES;
    if (catStr.contains('FNO') || catStr.contains('DERIV')) {
      cat = NewsCategory.FNO;
    } else if (catStr.contains('COMMOD')) {
      cat = NewsCategory.COMMODITIES;
    } else if (catStr.contains('FOREX') || catStr.contains('CURR')) {
      cat = NewsCategory.FOREX;
    } else if (catStr.contains('ECON')) {
      cat = NewsCategory.ECONOMY;
    }

    final sentStr = (json['sentiment'] ?? 'NEUTRAL').toString().toUpperCase();
    NewsSentiment sent = NewsSentiment.NEUTRAL;
    if (sentStr.contains('BULL')) {
      sent = NewsSentiment.BULLISH;
    } else if (sentStr.contains('BEAR')) {
      sent = NewsSentiment.BEARISH;
    }

    final symbols = <String>[];
    if (json['relatedSymbols'] is List) {
      symbols.addAll((json['relatedSymbols'] as List).map((e) => e.toString()));
    } else if (json['symbols'] is List) {
      symbols.addAll((json['symbols'] as List).map((e) => e.toString()));
    } else if (json['symbol'] != null) {
      symbols.add(json['symbol'].toString());
    }

    return NewsArticle(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? json['description'] ?? '').toString(),
      fullContent: (json['fullContent'] ?? json['content'] ?? json['summary'] ?? json['description'] ?? '').toString(),
      timestamp: DateTime.tryParse((json['timestamp'] ?? json['createdAt'] ?? json['publishedAt'] ?? '').toString()) ?? DateTime.now(),
      source: (json['source'] ?? 'Market News').toString(),
      sourceUrl: json['sourceUrl'] as String? ?? json['url'] as String?,
      category: cat,
      sentiment: sent,
      relatedTokens: (json['relatedTokens'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      relatedSymbols: symbols,
      readTimeMinutes: (json['readTimeMinutes'] as num?)?.toInt() ?? 3,
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
      keyTakeaways: (json['keyTakeaways'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

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
