class ProjectModel {
  final int projectId;
  final String title;
  final String status; // PENDING, PROCESSING, COMPLETED, FAILED
  final String? htmlUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String outputType; // video, ppt, pdf
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
    required this.createdAt,
    this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final options = json['options'] as Map<String, dynamic>? ?? {};
    return ProjectModel(
      projectId: json['projectId'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
      htmlUrl: json['htmlUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      outputType: options['output_type'] as String? ?? 'video',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  bool get isCompleted => status == 'COMPLETED';
  bool get isProcessing => status == 'PROCESSING' || status == 'PENDING';
  bool get isFailed => status == 'FAILED';
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasSlide => htmlUrl != null && htmlUrl!.isNotEmpty;
}
