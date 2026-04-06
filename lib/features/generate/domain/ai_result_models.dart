class SeoResultModel {
  final String title;
  final String description;
  final List<String> tags;

  const SeoResultModel({
    required this.title,
    required this.description,
    required this.tags,
  });

  factory SeoResultModel.fromJson(Map<String, dynamic> json) {
    return SeoResultModel(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class QualityResultModel {
  final int score; // 0~100
  final String feedback;
  final List<String> suggestions;

  const QualityResultModel({
    required this.score,
    required this.feedback,
    required this.suggestions,
  });

  factory QualityResultModel.fromJson(Map<String, dynamic> json) {
    return QualityResultModel(
      score: (json['score'] as num?)?.toInt() ?? 0,
      feedback: json['feedback'] as String? ?? '',
      suggestions: (json['suggestions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class TrendingTopicModel {
  final String topic;
  final String category;

  const TrendingTopicModel({required this.topic, required this.category});

  factory TrendingTopicModel.fromJson(Map<String, dynamic> json) {
    return TrendingTopicModel(
      topic: json['topic'] as String? ?? json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }
}
