import 'dart:convert';

class QuestionModel {
  final int questionId;
  final String category;
  final String groupName;
  final String type; // text, single, multi, number
  final String keyName;
  final String label;
  final String? description;
  final List<QuestionOption> options;
  final String? defaultVal;
  final double? minVal;
  final double? maxVal;
  final int sortOrder;
  final bool required;

  const QuestionModel({
    required this.questionId,
    required this.category,
    required this.groupName,
    required this.type,
    required this.keyName,
    required this.label,
    this.description,
    required this.options,
    this.defaultVal,
    this.minVal,
    this.maxVal,
    required this.sortOrder,
    required this.required,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    List<QuestionOption> opts = [];
    final optsRaw = json['optionsJson'];
    if (optsRaw is String && optsRaw.isNotEmpty) {
      try {
        final parsed = jsonDecode(optsRaw) as List<dynamic>;
        opts = parsed
            .map((e) => QuestionOption.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    } else if (optsRaw is List) {
      opts = (optsRaw as List)
          .map((e) => QuestionOption.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return QuestionModel(
      questionId: (json['questionId'] as num).toInt(),
      category: json['category'] as String? ?? '',
      groupName: json['groupName'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      keyName: json['keyName'] as String? ?? '',
      label: json['label'] as String? ?? '',
      description: json['description'] as String?,
      options: opts,
      defaultVal: json['defaultVal'] as String?,
      minVal:
          json['minVal'] != null ? (json['minVal'] as num).toDouble() : null,
      maxVal:
          json['maxVal'] != null ? (json['maxVal'] as num).toDouble() : null,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      required: json['required'] as bool? ?? false,
    );
  }
}

class QuestionOption {
  final String value;
  final String label;

  const QuestionOption({required this.value, required this.label});

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}
