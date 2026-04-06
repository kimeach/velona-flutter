class SubtitleEntryModel {
  final int index;
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleEntryModel({
    required this.index,
    required this.start,
    required this.end,
    required this.text,
  });

  SubtitleEntryModel copyWith({
    int? index,
    Duration? start,
    Duration? end,
    String? text,
  }) {
    return SubtitleEntryModel(
      index: index ?? this.index,
      start: start ?? this.start,
      end: end ?? this.end,
      text: text ?? this.text,
    );
  }

  /// Parse full SRT string into list of entries
  static List<SubtitleEntryModel> parseSrt(String srt) {
    final entries = <SubtitleEntryModel>[];
    final blocks = srt.trim().split(RegExp(r'\n\s*\n'));
    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 3) continue;
      try {
        final idx = int.tryParse(lines[0].trim()) ?? 0;
        final timeLine = lines[1].trim();
        final parts = timeLine.split(' --> ');
        if (parts.length != 2) continue;
        final start = _parseSrtTime(parts[0].trim());
        final end = _parseSrtTime(parts[1].trim());
        final text = lines.sublist(2).join('\n').trim();
        entries.add(SubtitleEntryModel(
          index: idx,
          start: start,
          end: end,
          text: text,
        ));
      } catch (_) {}
    }
    return entries;
  }

  static Duration _parseSrtTime(String t) {
    // HH:MM:SS,mmm
    final cleaned = t.replaceAll(',', '.');
    final segments = cleaned.split(':');
    if (segments.length != 3) return Duration.zero;
    final hours = int.tryParse(segments[0]) ?? 0;
    final minutes = int.tryParse(segments[1]) ?? 0;
    final secMs = segments[2].split('.');
    final seconds = int.tryParse(secMs[0]) ?? 0;
    final ms = int.tryParse(secMs.length > 1 ? secMs[1].padRight(3, '0').substring(0, 3) : '0') ?? 0;
    return Duration(hours: hours, minutes: minutes, seconds: seconds, milliseconds: ms);
  }

  String toSrtBlock() {
    return '$index\n${_formatTime(start)} --> ${_formatTime(end)}\n$text';
  }

  static String _formatTime(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$h:$m:$s,$ms';
  }

  static String toSrtString(List<SubtitleEntryModel> entries) {
    return entries.map((e) => e.toSrtBlock()).join('\n\n');
  }
}
