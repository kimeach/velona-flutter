class VoiceModel {
  final int voiceId;
  final String name;
  final String voiceKey;
  final DateTime createdAt;

  const VoiceModel({
    required this.voiceId,
    required this.name,
    required this.voiceKey,
    required this.createdAt,
  });

  factory VoiceModel.fromJson(Map<String, dynamic> json) {
    return VoiceModel(
      voiceId: (json['voiceId'] as num).toInt(),
      name: json['name'] as String? ?? '',
      voiceKey: json['voiceKey'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
