class SoundEffectModel {
  final int id;
  final String name;
  final double durationSec;
  final List<String> tags;
  final String? previewUrl;

  const SoundEffectModel({
    required this.id,
    required this.name,
    required this.durationSec,
    required this.tags,
    this.previewUrl,
  });

  factory SoundEffectModel.fromJson(Map<String, dynamic> json) {
    return SoundEffectModel(
      id: json['id'] as int,
      name: json['name'] as String,
      durationSec: (json['duration'] as num).toDouble(),
      tags: (json['tags'] as List? ?? []).map((e) => e.toString()).toList(),
      previewUrl: json['preview_url'] as String?,
    );
  }
}
