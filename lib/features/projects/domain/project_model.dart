class ProjectModel {
  final int projectId;
  final String title;
  final String status; // draft, generating, done, error
  final String? htmlUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String outputType; // video, ppt, pdf
  final String category; // stock, crypto, korea, macro_news, blank
  final Map<String, dynamic> options;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProjectModel({
    required this.projectId,
    required this.title,
    required this.status,
    this.htmlUrl,
    this.videoUrl,
    this.thumbnailUrl,
    required this.outputType,
    required this.category,
    required this.options,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final options = json['options'] as Map<String, dynamic>? ?? {};
    return ProjectModel(
      projectId: (json['projectId'] as num).toInt(),
      title: json['title'] as String? ?? '제목 없음',
      status: json['status'] as String? ?? 'draft',
      htmlUrl: json['htmlUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      outputType: options['output_type'] as String? ?? 'video',
      category: json['category'] as String? ?? 'blank',
      options: options,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  bool get isCompleted => status == 'done';
  bool get isProcessing => status == 'generating';
  bool get isDraft => status == 'draft';
  bool get isFailed => status == 'error';
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasSlide => htmlUrl != null && htmlUrl!.isNotEmpty;

  String get categoryLabel {
    switch (category) {
      case 'stock': return '미국 주식';
      case 'crypto': return '암호화폐';
      case 'korea': return '한국 주식';
      case 'macro_news': return '매크로 뉴스';
      default: return '기타';
    }
  }
}
