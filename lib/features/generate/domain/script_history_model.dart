class ScriptHistoryModel {
  final int historyId;
  final int projectId;
  final Map<String, String> script;
  final DateTime createdAt;

  const ScriptHistoryModel({
    required this.historyId,
    required this.projectId,
    required this.script,
    required this.createdAt,
  });

  factory ScriptHistoryModel.fromJson(Map<String, dynamic> json) {
    final rawScript = json['script'] as Map<String, dynamic>? ?? {};
    return ScriptHistoryModel(
      historyId: (json['historyId'] as num).toInt(),
      projectId: (json['projectId'] as num).toInt(),
      script: rawScript.map((k, v) => MapEntry(k, v.toString())),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
