import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../data/generate_repository.dart';

final _repoProvider = Provider((ref) => GenerateRepository(ref.watch(dioProvider)));

class ScriptEditorScreen extends ConsumerStatefulWidget {
  final int projectId;
  const ScriptEditorScreen({super.key, required this.projectId});

  @override
  ConsumerState<ScriptEditorScreen> createState() => _ScriptEditorScreenState();
}

class _ScriptEditorScreenState extends ConsumerState<ScriptEditorScreen> {
  List<Map<String, dynamic>> _clips = [];
  List<TextEditingController> _controllers = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  // TTS
  final _player = AudioPlayer();
  int? _playingIndex;
  bool _ttsLoading = false;

  // AI 재작성
  int? _rewritingIndex;

  static const _voices = [
    'ko-KR-InJoonNeural',
    'ko-KR-SunHiNeural',
    'ko-KR-HyunsuMultilingualNeural',
  ];
  String _voice = 'ko-KR-InJoonNeural';

  @override
  void initState() {
    super.initState();
    _loadScript();
  }

  @override
  void dispose() {
    _player.dispose();
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  Future<void> _loadScript() async {
    try {
      final clips = await ref.read(_repoProvider).getScript(widget.projectId);
      _controllers = clips
          .map((c) => TextEditingController(text: c['text'] as String? ?? ''))
          .toList();
      setState(() { _clips = clips; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = List<Map<String, dynamic>>.from(_clips);
      for (int i = 0; i < updated.length; i++) {
        updated[i] = {...updated[i], 'text': _controllers[i].text};
      }
      await ref.read(_repoProvider).updateScript(widget.projectId, updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('대본이 저장되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _playTts(int index) async {
    final text = _controllers[index].text.trim();
    if (text.isEmpty) return;

    // 같은 클립 재클릭 → 정지
    if (_playingIndex == index) {
      await _player.stop();
      setState(() => _playingIndex = null);
      return;
    }

    setState(() { _ttsLoading = true; _playingIndex = index; });
    try {
      await _player.stop();
      final ttsUrl = await ref.read(_repoProvider).getTtsUrl(
        projectId: widget.projectId,
        text: text,
        voice: _voice,
      );
      await _player.setUrl(ttsUrl);
      await _player.play();
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() => _playingIndex = null);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('TTS 오류: $e')));
        setState(() => _playingIndex = null);
      }
    } finally {
      if (mounted) setState(() => _ttsLoading = false);
    }
  }

  Future<void> _aiRewrite(int index) async {
    final text = _controllers[index].text.trim();
    if (text.isEmpty) return;
    setState(() => _rewritingIndex = index);
    try {
      final result = await ref.read(_repoProvider).aiRewrite(
        projectId: widget.projectId,
        text: text,
        style: 'concise',
      );
      _controllers[index].text = result;
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('AI 재작성 오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _rewritingIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('대본 편집'),
        actions: [
          // 목소리 선택
          PopupMenuButton<String>(
            icon: const Icon(Icons.record_voice_over),
            onSelected: (v) => setState(() => _voice = v),
            itemBuilder: (_) => _voices
                .map((v) => PopupMenuItem(
                      value: v,
                      child: Row(children: [
                        if (_voice == v)
                          const Icon(Icons.check, size: 16, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text(v.split('-')[2].replaceAll('Neural', ''),
                            style: const TextStyle(fontSize: 13)),
                      ]),
                    ))
                .toList(),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('저장', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.error)))
              : _clips.isEmpty
                  ? const Center(
                      child: Text('대본이 없습니다.',
                          style: TextStyle(color: AppColors.textSecond)),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _clips.length,
                      onReorder: (oldIdx, newIdx) {
                        setState(() {
                          if (newIdx > oldIdx) newIdx--;
                          final clip = _clips.removeAt(oldIdx);
                          final ctrl = _controllers.removeAt(oldIdx);
                          _clips.insert(newIdx, clip);
                          _controllers.insert(newIdx, ctrl);
                        });
                      },
                      itemBuilder: (context, index) {
                        final isPlaying = _playingIndex == index;
                        final isRewriting = _rewritingIndex == index;
                        return _ClipCard(
                          key: ValueKey(_clips[index]['clipId'] ?? index),
                          index: index,
                          controller: _controllers[index],
                          clip: _clips[index],
                          isPlaying: isPlaying,
                          isRewriting: isRewriting,
                          ttsLoading: _ttsLoading && isPlaying,
                          onPlayTts: () => _playTts(index),
                          onAiRewrite: () => _aiRewrite(index),
                          onChanged: () => setState(() {}),
                        );
                      },
                    ),
    );
  }
}

class _ClipCard extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final Map<String, dynamic> clip;
  final bool isPlaying;
  final bool isRewriting;
  final bool ttsLoading;
  final VoidCallback onPlayTts;
  final VoidCallback onAiRewrite;
  final VoidCallback onChanged;

  const _ClipCard({
    super.key,
    required this.index,
    required this.controller,
    required this.clip,
    required this.isPlaying,
    required this.isRewriting,
    required this.ttsLoading,
    required this.onPlayTts,
    required this.onAiRewrite,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final estSec = ((controller.text.length / 6).ceil()).clamp(1, 999);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('씬 ${index + 1}',
                      style: const TextStyle(
                          color: AppColors.accent, fontSize: 12)),
                ),
                const Spacer(),
                // TTS 미리듣기
                IconButton(
                  icon: ttsLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : Icon(
                          isPlaying ? Icons.stop : Icons.play_arrow,
                          color: isPlaying
                              ? AppColors.accent
                              : AppColors.textSecond,
                          size: 20,
                        ),
                  tooltip: 'TTS 미리 듣기',
                  onPressed: onPlayTts,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                // AI 재작성
                isRewriting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        icon: const Icon(Icons.auto_awesome,
                            color: AppColors.textSecond, size: 18),
                        tooltip: 'AI 재작성',
                        onPressed: onAiRewrite,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                const SizedBox(width: 8),
                const Icon(Icons.drag_handle,
                    color: AppColors.textSecond, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: null,
              onChanged: (_) => onChanged(),
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '대본을 입력하세요...',
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '예상 ${estSec}초',
              style: const TextStyle(
                  color: AppColors.textSecond, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
