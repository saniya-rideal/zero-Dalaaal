/// Strongly typed model and scoring logic for SEBI Investor Risk Profiling.
library;

enum RiskCategory {
  conservative,
  moderate,
  aggressive;

  String get label {
    switch (this) {
      case RiskCategory.conservative:
        return 'Conservative';
      case RiskCategory.moderate:
        return 'Moderate';
      case RiskCategory.aggressive:
        return 'Aggressive';
    }
  }

  String get badgeText {
    switch (this) {
      case RiskCategory.conservative:
        return 'LOW RISK';
      case RiskCategory.moderate:
        return 'BALANCED';
      case RiskCategory.aggressive:
        return 'HIGH RISK';
    }
  }

  String get description {
    switch (this) {
      case RiskCategory.conservative:
        return 'Focus on capital preservation and steady dividend yields. Minimal tolerance for capital drawdown.';
      case RiskCategory.moderate:
        return 'Balanced growth seeking capital appreciation with moderate market volatility tolerance.';
      case RiskCategory.aggressive:
        return 'High risk appetite seeking exponential returns through leveraged equity, derivatives (F&O), and intraday volatility.';
    }
  }

  List<String> get suitableProducts {
    switch (this) {
      case RiskCategory.conservative:
        return ['Government Sovereign Bonds', 'Liquid ETFs', 'Large-Cap Bluechips', 'Fixed Income Assets'];
      case RiskCategory.moderate:
        return ['Diversified Equity Index', 'Mid-Cap Equities', 'Thematic ETFs', 'Covered Equity Swings'];
      case RiskCategory.aggressive:
        return ['Futures & Options (F&O)', 'Intraday Equity Margins (5x)', 'Commodity Derivatives', 'Small & Micro-caps'];
    }
  }
}

class RiskOption {
  final String text;
  final int points;

  const RiskOption({required this.text, required this.points});

  Map<String, dynamic> toJson() => {'text': text, 'points': points};

  factory RiskOption.fromJson(Map<String, dynamic> json) => RiskOption(
        text: json['text'] as String,
        points: json['points'] as int,
      );
}

class RiskQuestion {
  final int id;
  final String title;
  final String description;
  final List<RiskOption> options;

  const RiskQuestion({
    required this.id,
    required this.title,
    required this.description,
    required this.options,
  });
}

const List<RiskQuestion> kRiskQuestions = [
  RiskQuestion(
    id: 1,
    title: 'What is your current age bracket?',
    description: 'Investment horizon and risk capacity vary significantly across different life stages.',
    options: [
      RiskOption(text: 'Under 30 years (Long investment horizon)', points: 5),
      RiskOption(text: '30 to 45 years (Prime earning & wealth accumulation)', points: 4),
      RiskOption(text: '46 to 60 years (Pre-retirement capital preservation)', points: 2),
      RiskOption(text: 'Above 60 years (Retirement & income security)', points: 1),
    ],
  ),
  RiskQuestion(
    id: 2,
    title: 'What is your primary investment objective?',
    description: 'Defines your expected return vs downside tolerance preference.',
    options: [
      RiskOption(text: 'Capital Protection: Safety of principal with modest interest', points: 1),
      RiskOption(text: 'Steady Growth: Beat inflation with balanced market exposure', points: 3),
      RiskOption(text: 'Aggressive Wealth Creation: Maximize gains accepting high volatility', points: 5),
    ],
  ),
  RiskQuestion(
    id: 3,
    title: 'What is your prior trading / stock market experience?',
    description: 'Knowledge of order types, stop-losses, and derivatives volatility.',
    options: [
      RiskOption(text: 'Beginner: Less than 1 year, new to capital markets', points: 1),
      RiskOption(text: 'Intermediate: 1 to 3 years, invested in equities & mutual funds', points: 3),
      RiskOption(text: 'Experienced: Over 3 years, actively trade equities & derivatives', points: 5),
    ],
  ),
  RiskQuestion(
    id: 4,
    title: 'If your portfolio drops 20% during a sharp market correction, how would you react?',
    description: 'Emotional discipline under market drawdowns.',
    options: [
      RiskOption(text: 'Panic & Sell: Exit all holdings immediately to prevent further loss', points: 1),
      RiskOption(text: 'Hold & Wait: Stay invested until the market stabilizes and recovers', points: 3),
      RiskOption(text: 'Buy More: View the drop as an opportunity and accumulate at discounts', points: 5),
    ],
  ),
  RiskQuestion(
    id: 5,
    title: 'What percentage of your total savings do you allocate to active trading / equities?',
    description: 'Portfolio concentration and financial dependency.',
    options: [
      RiskOption(text: 'Less than 10% (Discretionary exploratory funds)', points: 2),
      RiskOption(text: '10% to 30% (Standard core-satellite allocation)', points: 4),
      RiskOption(text: 'Over 30% (Significant portion of overall net worth)', points: 5),
    ],
  ),
];

class InvestorRiskProfile {
  final RiskCategory category;
  final int score;
  final Map<int, int> answers; // question id -> option index
  final DateTime? lastAssessed;
  final bool isFnoSuitable;
  final String suitabilityAdvisory;

  const InvestorRiskProfile({
    required this.category,
    required this.score,
    required this.answers,
    this.lastAssessed,
    required this.isFnoSuitable,
    required this.suitabilityAdvisory,
  });

  static RiskCategory determineCategory(int totalScore) {
    if (totalScore <= 10) {
      return RiskCategory.conservative;
    } else if (totalScore <= 18) {
      return RiskCategory.moderate;
    } else {
      return RiskCategory.aggressive;
    }
  }

  static int calculateScoreFromAnswers(Map<int, int> answers) {
    int sum = 0;
    for (final q in kRiskQuestions) {
      final selectedIdx = answers[q.id];
      if (selectedIdx != null && selectedIdx >= 0 && selectedIdx < q.options.length) {
        sum += q.options[selectedIdx].points;
      } else {
        sum += 1; // baseline fallback
      }
    }
    return sum;
  }

  factory InvestorRiskProfile.fromAnswers(Map<int, int> answers) {
    final score = calculateScoreFromAnswers(answers);
    final category = determineCategory(score);
    final isFno = category == RiskCategory.moderate || category == RiskCategory.aggressive;

    final advisory = isFno
        ? 'Suitability Verified: Profile aligns with leveraged equity & SEBI F&O derivatives trading.'
        : 'Statutory Advisory: Profile indicates Conservative risk tolerance. Derivative trading (F&O) involves substantial risk of capital loss.';

    return InvestorRiskProfile(
      category: category,
      score: score,
      answers: answers,
      lastAssessed: DateTime.now(),
      isFnoSuitable: isFno,
      suitabilityAdvisory: advisory,
    );
  }

  /// Empty initial state before questionnaire is taken
  factory InvestorRiskProfile.empty() {
    return const InvestorRiskProfile(
      category: RiskCategory.conservative,
      score: 0,
      answers: {},
      isFnoSuitable: false,
      suitabilityAdvisory: 'Risk profile not yet assessed. Complete the questionnaire to determine SEBI suitability.',
    );
  }

  InvestorRiskProfile copyWith({
    RiskCategory? category,
    int? score,
    Map<int, int>? answers,
    DateTime? lastAssessed,
    bool? isFnoSuitable,
    String? suitabilityAdvisory,
  }) {
    return InvestorRiskProfile(
      category: category ?? this.category,
      score: score ?? this.score,
      answers: answers ?? this.answers,
      lastAssessed: lastAssessed ?? this.lastAssessed,
      isFnoSuitable: isFnoSuitable ?? this.isFnoSuitable,
      suitabilityAdvisory: suitabilityAdvisory ?? this.suitabilityAdvisory,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'score': score,
        'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
        'lastAssessed': lastAssessed?.toIso8601String(),
        'isFnoSuitable': isFnoSuitable,
        'suitabilityAdvisory': suitabilityAdvisory,
      };

  factory InvestorRiskProfile.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as Map<String, dynamic>? ?? {};
    final parsedAnswers = <int, int>{};
    rawAnswers.forEach((k, v) {
      parsedAnswers[int.tryParse(k) ?? 0] = (v as num).toInt();
    });

    final categoryName = json['category'] as String? ?? 'moderate';
    final category = RiskCategory.values.firstWhere(
      (e) => e.name == categoryName,
      orElse: () => RiskCategory.moderate,
    );

    return InvestorRiskProfile(
      category: category,
      score: json['score'] as int? ?? 15,
      answers: parsedAnswers,
      lastAssessed: json['lastAssessed'] != null
          ? DateTime.parse(json['lastAssessed'] as String)
          : DateTime.now(),
      isFnoSuitable: json['isFnoSuitable'] as bool? ?? true,
      suitabilityAdvisory: json['suitabilityAdvisory'] as String? ?? '',
    );
  }
}
