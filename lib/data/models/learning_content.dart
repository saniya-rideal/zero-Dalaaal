import 'package:flutter/foundation.dart';

enum LearningCategory {
  ALL,
  BASICS,
  RISK_MANAGEMENT,
  MARGIN_LEVERAGE,
  INTRADAY,
  FNO,
  COMMODITY_FOREX,
}

enum DifficultyLevel {
  BEGINNER,
  INTERMEDIATE,
  ADVANCED,
}

@immutable
class LearningSection {
  final String title;
  final String content;
  final List<String> keyTakeaways;
  final String? proTip;

  const LearningSection({
    required this.title,
    required this.content,
    this.keyTakeaways = const [],
    this.proTip,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'keyTakeaways': keyTakeaways,
    'proTip': proTip,
  };

  factory LearningSection.fromJson(Map<String, dynamic> json) => LearningSection(
    title: json['title'] as String,
    content: json['content'] as String,
    keyTakeaways: (json['keyTakeaways'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    proTip: json['proTip'] as String?,
  );
}

@immutable
class LearningModule {
  final String id;
  final String title;
  final String description;
  final LearningCategory category;
  final DifficultyLevel level;
  final int readTimeMinutes;
  final List<LearningSection> sections;
  final String iconName;

  const LearningModule({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.level,
    required this.readTimeMinutes,
    required this.sections,
    this.iconName = 'school',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category.name,
    'level': level.name,
    'readTimeMinutes': readTimeMinutes,
    'sections': sections.map((s) => s.toJson()).toList(),
    'iconName': iconName,
  };

  factory LearningModule.fromJson(Map<String, dynamic> json) => LearningModule(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    category: LearningCategory.values.byName(json['category'] as String),
    level: DifficultyLevel.values.byName(json['level'] as String),
    readTimeMinutes: (json['readTimeMinutes'] as num).toInt(),
    sections: (json['sections'] as List<dynamic>)
        .map((e) => LearningSection.fromJson(e as Map<String, dynamic>))
        .toList(),
    iconName: json['iconName'] as String? ?? 'school',
  );
}

@immutable
class GlossaryTerm {
  final String term;
  final LearningCategory category;
  final String definition;
  final String? example;
  final String? formula;

  const GlossaryTerm({
    required this.term,
    required this.category,
    required this.definition,
    this.example,
    this.formula,
  });

  Map<String, dynamic> toJson() => {
    'term': term,
    'category': category.name,
    'definition': definition,
    'example': example,
    'formula': formula,
  };

  factory GlossaryTerm.fromJson(Map<String, dynamic> json) => GlossaryTerm(
    term: json['term'] as String,
    category: LearningCategory.values.byName(json['category'] as String),
    definition: json['definition'] as String,
    example: json['example'] as String?,
    formula: json['formula'] as String?,
  );
}
