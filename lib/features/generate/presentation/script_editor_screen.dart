import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../data/generate_repository.dart';
import '../domain/script_history_model.dart';
import '../domain/ai_result_models.dart';

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

  // AI
  int? _rewritingIndex;
  bool _aiLoading = false; // for global AI tasks

  // 목소리
  static const _voices = [
    ('ko-KR-InJoonNeural', '남성 InJoon'),
    ('ko-KR-SunHiNeural', '여성 SunHi'),
    ('ko-KR-HyunsuMultilingualNeural', '남성 다국어 Hyunsu'),
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
      final scriptMap = await ref.read(_repoProvider).getScript(widget.projectId);
      final clips = scriptMap.entries
          .map((e) => {'key': e.key, 'text': e.value})
          .toList();
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
      final updated = <String, String>{};
      for (int i = 0; i < _clips.length; i++) {
        final key = _clips[i]['key'] as String? ?? 'slide_${i + 1}';
        updated[key] = _controllers[i].text;
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
    if (_playingIndex == index) {
      await _player.stop();
      setState(() => _playingIndex = null);
      return;
    }
    setState(() { _ttsLoading = true; _playingIndex = index; });
    try {
      await _player.stop();
      final bytes = await ref.read(_repoProvider).getTtsBytes(text: text, voice: _voice);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tts_preview.mp3');
      await file.writeAsBytes(bytes);
      await _player.setFilePath(file.path);
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

  Future<void> _aiTranslate(int index) async {
    final text = _controllers[index].text.trim();
    if (text.isEmpty) return;

    final lang = await _showLanguagePicker();
    if (lang == null) return;

    setState(() => _rewritingIndex = index);
    try {
      final result = await ref.read(_repoProvider).aiTranslate(
        projectId: widget.projectId,
        text: text,
        targetLang: lang,
      );
      _controllers[index].text = result;
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('번역 오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _rewritingIndex = null);
    }
  }

  Future<String?> _showLanguagePicker() async {
    const langs = [
      ('ko', '한국어'),
      ('en', '영어'),
      ('ja', '일본어'),
      ('zh', '중국어'),
      ('es', '스페인어'),
      ('fr', '프랑스어'),
    ];
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('번역 언어 선택',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
          ...langs.map((l) => ListTile(
            title: Text(l.$2, style: const TextStyle(color: AppColors.textPrimary)),
            trailing: Text(l.$1, style: const TextStyle(color: AppColors.textSecond)),
            onTap: () => Navigator.pop(context, l.$1),
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── 전체 AI 기능 ───────────────────────────────────────────────────────

  Future<void> _showHashtags() async {
    setState(() => _aiLoading = true);
    try {
      final tags = await ref.read(_repoProvider).aiHashtags(widget.projectId);
      if (!mounted) return;
      final text = tags.join(' ');
      await showDialog(
        context: context,
        builder: (_) => _CopyDialog(
          title: '추천 해시태그',
          content: text,
          hint: '${tags.length}개 생성됨',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('해시태그 오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _showSeo() async {
    setState(() => _aiLoading = true);
    try {
      final seo = await ref.read(_repoProvider).aiSeo(widget.projectId);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => _SeoDialog(result: seo),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('SEO 오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _showQuality() async {
    setState(() => _aiLoading = true);
    try {
      final quality = await ref.read(_repoProvider).aiQuality(widget.projectId);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => _QualityDialog(result: quality),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('품질 분석 오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _showHistory() async {
    List<ScriptHistoryModel> history = [];
    bool loading = true;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          if (loading) {
            ref.read(_repoProvider).getScriptHistory(widget.projectId).then((list) {
              setModalState(() { history = list; loading = false; });
            }).catchError((_) {
              setModalState(() => loading = false);
            });
          }
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            builder: (_, ctrl) => Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('대본 히스토리',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : history.isEmpty
                          ? const Center(
                              child: Text('히스토리가 없습니다.',
                                  style: TextStyle(color: AppColors.textSecond)))
                          : ListView.builder(
                              controller: ctrl,
                              itemCount: history.length,
                              itemBuilder: (_, i) {
                                final h = history[i];
                                final dt = h.createdAt;
                                return ListTile(
                                  title: Text(
                                    '${dt.year}.${dt.month.toString().padLeft(2,'0')}.${dt.day.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}',
                                    style: const TextStyle(color: AppColors.textPrimary),
                                  ),
                                  subtitle: Text('${h.script.length}개 씬',
                                      style: const TextStyle(color: AppColors.textSecond, fontSize: 12)),
                                  trailing: TextButton(
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      await _restoreHistory(h.historyId);
                                    },
                                    child: const Text('복원'),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _restoreHistory(int historyId) async {
    try {
      final script = await ref.read(_repoProvider)
          .restoreScriptHistory(widget.projectId, historyId);
      final clips = script.entries
          .map((e) => {'key': e.key, 'text': e.value})
          .toList();
      for (final c in _controllers) c.dispose();
      final controllers = clips
          .map((c) => TextEditingController(text: c['text'] as String? ?? ''))
          .toList();
      setState(() { _clips = clips; _controllers = controllers; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('대본이 복원되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('복원 오류: $e')));
      }
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
            itemBuilder: (_) => _voices.map((v) => PopupMenuItem(
              value: v.$1,
              child: Row(children: [
                if (_voice == v.$1)
                  const Icon(Icons.check, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(v.$2, style: const TextStyle(fontSize: 13)),
              ]),
            )).toList(),
          ),

          // AI 기능 메뉴
          if (_aiLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'AI 기능',
              onSelected: (v) {
                switch (v) {
                  case 'hashtags': _showHashtags(); break;
                  case 'seo': _showSeo(); break;
                  case 'quality': _showQuality(); break;
                  case 'history': _showHistory(); break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'hashtags', child: Row(children: [
                  Icon(Icons.tag, size: 16), SizedBox(width: 8), Text('해시태그 생성'),
                ])),
                PopupMenuItem(value: 'seo', child: Row(children: [
                  Icon(Icons.search, size: 16), SizedBox(width: 8), Text('SEO 최적화'),
                ])),
                PopupMenuItem(value: 'quality', child: Row(children: [
                  Icon(Icons.star_outline, size: 16), SizedBox(width: 8), Text('품질 분석'),
                ])),
                PopupMenuDivider(),
                PopupMenuItem(value: 'history', child: Row(children: [
                  Icon(Icons.history, size: 16), SizedBox(width: 8), Text('히스토리'),
                ])),
              ],
            ),

          // 저장
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('저장', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : _clips.isEmpty
                  ? const Center(
                      child: Text('대본이 없습니다.',
                          style: TextStyle(color: AppColors.textSecond)))
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
                          key: ValueKey(_clips[index]['key'] ?? index),
                          index: index,
                          controller: _controllers[index],
                          clip: _clips[index],
                          isPlaying: isPlaying,
                          isRewriting: isRewriting,
                          ttsLoading: _ttsLoading && isPlaying,
                          onPlayTts: () => _playTts(index),
                          onAiRewrite: () => _aiRewrite(index),
                          onAiTranslate: () => _aiTranslate(index),
                          onChanged: () => setState(() {}),
                        );
                      },
                    ),
    );
  }
}

// ─── ClipCard ──────────────────────────────────────────────────────────────

class _ClipCard extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final Map<String, dynamic> clip;
  final bool isPlaying;
  final bool isRewriting;
  final bool ttsLoading;
  final VoidCallback onPlayTts;
  final VoidCallback onAiRewrite;
  final VoidCallback onAiTranslate;
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
    required this.onAiTranslate,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('씬 ${index + 1}',
                      style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                ),
                const Spacer(),

                // TTS 미리듣기
                IconButton(
                  icon: ttsLoading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(
                          isPlaying ? Icons.stop : Icons.play_arrow,
                          color: isPlaying ? AppColors.accent : AppColors.textSecond,
                          size: 20,
                        ),
                  tooltip: 'TTS 미리 듣기',
                  onPressed: onPlayTts,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),

                // AI 메뉴
                isRewriting
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : PopupMenuButton<String>(
                        icon: const Icon(Icons.auto_awesome,
                            color: AppColors.textSecond, size: 18),
                        padding: EdgeInsets.zero,
                        onSelected: (v) {
                          if (v == 'rewrite') onAiRewrite();
                          if (v == 'translate') onAiTranslate();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'rewrite', child: Text('AI 재작성')),
                          PopupMenuItem(value: 'translate', child: Text('번역')),
                        ],
                      ),
                const SizedBox(width: 8),
                const Icon(Icons.drag_handle, color: AppColors.textSecond, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: null,
              onChanged: (_) => onChanged(),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '대본을 입력하세요...',
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 4),
            Text('예상 ${estSec}초',
                style: const TextStyle(color: AppColors.textSecond, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─── AI 결과 다이얼로그 ────────────────────────────────────────────────────

class _CopyDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? hint;

  const _CopyDialog({required this.title, required this.content, this.hint});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hint != null)
            Text(hint!, style: const TextStyle(color: AppColors.textSecond, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              content,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: content));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('클립보드에 복사됨')),
            );
          },
          child: const Text('복사'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

class _SeoDialog extends StatelessWidget {
  final SeoResultModel result;
  const _SeoDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('SEO 최적화',
          style: TextStyle(color: AppColors.textPrimary)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _seoSection('제목', result.title),
            const SizedBox(height: 12),
            _seoSection('설명', result.description),
            const SizedBox(height: 12),
            _seoSection('태그', result.tags.join(', ')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final all = '제목: ${result.title}\n\n설명: ${result.description}\n\n태그: ${result.tags.join(', ')}';
            Clipboard.setData(ClipboardData(text: all));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('클립보드에 복사됨')),
            );
          },
          child: const Text('전체 복사'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  Widget _seoSection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecond, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(6),
          ),
          child: SelectableText(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _QualityDialog extends StatelessWidget {
  final QualityResultModel result;
  const _QualityDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    final scoreColor = result.score >= 80
        ? AppColors.success
        : result.score >= 60
            ? AppColors.warning
            : AppColors.error;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('품질 분석',
          style: TextStyle(color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  '${result.score}',
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('/ 100', style: TextStyle(color: scoreColor, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (result.feedback.isNotEmpty) ...[
            const Text('피드백',
                style: TextStyle(color: AppColors.textSecond, fontSize: 12)),
            const SizedBox(height: 4),
            Text(result.feedback,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ],
          if (result.suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('개선 제안',
                style: TextStyle(color: AppColors.textSecond, fontSize: 12)),
            const SizedBox(height: 4),
            ...result.suggestions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.accent)),
                  Expanded(child: Text(s,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                ],
              ),
            )),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
