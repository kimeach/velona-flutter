import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../generate/data/generate_repository.dart';
import '../domain/subtitle_entry_model.dart';

final _subtitleRepoProvider = Provider(
  (ref) => GenerateRepository(ref.watch(dioProvider)),
);

class SubtitleEditorScreen extends ConsumerStatefulWidget {
  final int projectId;
  final bool hasVideo;

  const SubtitleEditorScreen({
    super.key,
    required this.projectId,
    this.hasVideo = false,
  });

  @override
  ConsumerState<SubtitleEditorScreen> createState() => _SubtitleEditorScreenState();
}

class _SubtitleEditorScreenState extends ConsumerState<SubtitleEditorScreen> {
  List<SubtitleEntryModel> _entries = [];
  List<TextEditingController> _textCtrls = [];
  List<TextEditingController> _startCtrls = [];
  List<TextEditingController> _endCtrls = [];

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _textCtrls) c.dispose();
    for (final c in _startCtrls) c.dispose();
    for (final c in _endCtrls) c.dispose();
    super.dispose();
  }

  void _setEntries(List<SubtitleEntryModel> entries) {
    for (final c in _textCtrls) c.dispose();
    for (final c in _startCtrls) c.dispose();
    for (final c in _endCtrls) c.dispose();

    _textCtrls = entries.map((e) => TextEditingController(text: e.text)).toList();
    _startCtrls = entries.map((e) => TextEditingController(text: _durToStr(e.start))).toList();
    _endCtrls = entries.map((e) => TextEditingController(text: _durToStr(e.end))).toList();
    setState(() { _entries = entries; _error = null; });
  }

  String _durToStr(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$h:$m:$s,$ms';
  }

  Duration _strToDur(String s) {
    try {
      final cleaned = s.replaceAll(',', '.');
      final parts = cleaned.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final secMs = parts[2].split('.');
      final sec = int.parse(secMs[0]);
      final ms = int.parse((secMs.length > 1 ? secMs[1] : '000').padRight(3, '0').substring(0, 3));
      return Duration(hours: h, minutes: m, seconds: sec, milliseconds: ms);
    } catch (_) {
      return Duration.zero;
    }
  }

  Future<void> _generateFromScript() async {
    setState(() { _loading = true; _error = null; });
    try {
      final srt = await ref.read(_subtitleRepoProvider).generateSubtitleFromScript(widget.projectId);
      _setEntries(SubtitleEntryModel.parseSrt(srt));
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generateFromVideo() async {
    setState(() { _loading = true; _error = null; });
    try {
      final srt = await ref.read(_subtitleRepoProvider).generateSubtitleFromVideo(widget.projectId);
      _setEntries(SubtitleEntryModel.parseSrt(srt));
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<SubtitleEntryModel> _buildCurrentEntries() {
    final updated = <SubtitleEntryModel>[];
    for (int i = 0; i < _entries.length; i++) {
      updated.add(_entries[i].copyWith(
        text: _textCtrls[i].text,
        start: _strToDur(_startCtrls[i].text),
        end: _strToDur(_endCtrls[i].text),
      ));
    }
    return updated;
  }

  void _copySrt() {
    final entries = _buildCurrentEntries();
    final srt = SubtitleEntryModel.toSrtString(entries);
    // Use Clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SRT가 준비됩니다. 복사하려면 텍스트를 선택하세요.')),
    );
    _showSrtDialog(srt);
  }

  void _showSrtDialog(String srt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('SRT 전체 보기',
            style: TextStyle(color: AppColors.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              srt,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('자막 편집'),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.code),
              tooltip: 'SRT 보기',
              onPressed: _copySrt,
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: '자막 생성',
            onSelected: (v) {
              if (v == 'script') _generateFromScript();
              if (v == 'video') _generateFromVideo();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'script',
                child: Row(children: [
                  Icon(Icons.description_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('대본에서 생성'),
                ]),
              ),
              if (widget.hasVideo)
                const PopupMenuItem(
                  value: 'video',
                  child: Row(children: [
                    Icon(Icons.video_file_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('영상에서 추출'),
                  ]),
                ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('자막 생성 중...', style: TextStyle(color: AppColors.textSecond)),
              ],
            ))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _generateFromScript,
                        child: const Text('대본으로 다시 시도'),
                      ),
                    ],
                  ),
                )
              : _entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.subtitles_outlined,
                              size: 48, color: AppColors.textSecond),
                          const SizedBox(height: 16),
                          const Text(
                            '자막이 없습니다.\n오른쪽 상단 버튼으로 생성하세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecond),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _generateFromScript,
                            icon: const Icon(Icons.description_outlined),
                            label: const Text('대본에서 자막 생성'),
                          ),
                          if (widget.hasVideo) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _generateFromVideo,
                              icon: const Icon(Icons.video_file_outlined),
                              label: const Text('영상에서 자막 추출'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _entries.length,
                      itemBuilder: (_, i) => _SubtitleCard(
                        index: i,
                        textCtrl: _textCtrls[i],
                        startCtrl: _startCtrls[i],
                        endCtrl: _endCtrls[i],
                      ),
                    ),
    );
  }
}

class _SubtitleCard extends StatelessWidget {
  final int index;
  final TextEditingController textCtrl;
  final TextEditingController startCtrl;
  final TextEditingController endCtrl;

  const _SubtitleCard({
    required this.index,
    required this.textCtrl,
    required this.startCtrl,
    required this.endCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 번호 + 타이밍
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${index + 1}',
                      style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeField(ctrl: startCtrl, label: '시작'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('→', style: TextStyle(color: AppColors.textSecond)),
                ),
                Expanded(
                  child: _TimeField(ctrl: endCtrl, label: '종료'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 자막 텍스트
            TextField(
              controller: textCtrl,
              maxLines: null,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '자막 텍스트...',
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;

  const _TimeField({required this.ctrl, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecond, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        isDense: true,
      ),
    );
  }
}
