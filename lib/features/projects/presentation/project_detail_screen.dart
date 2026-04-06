import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../generate/data/generate_repository.dart';
import '../domain/project_model.dart';
import 'projects_provider.dart';

final _genRepoProvider = Provider((ref) => GenerateRepository(ref.watch(dioProvider)));

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final int projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;
  WebViewController? _webCtrl;
  Timer? _pollTimer;
  bool _videoInitialized = false;
  bool _downloading = false;
  double _downloadProgress = 0;

  // 렌더 설정
  String _renderVoice = 'ko-KR-InJoonNeural';
  int _renderDuration = 60;
  bool _renderBgm = true;
  double _bgmVolume = 0.3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollTimer?.cancel();
    _chewieCtrl?.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  Future<void> _downloadAndShare(String videoUrl, String title) async {
    setState(() { _downloading = true; _downloadProgress = 0; });
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/velona_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await Dio().download(
        videoUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'video/mp4')],
        text: title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다운로드 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _downloading = false; _downloadProgress = 0; });
    }
  }

  void _initVideo(String url) async {
    if (_videoInitialized) return;
    _videoInitialized = true;
    _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoCtrl!.initialize();
    _chewieCtrl = ChewieController(
      videoPlayerController: _videoCtrl!,
      aspectRatio: 9 / 16,
      autoPlay: false,
      looping: false,
    );
    if (mounted) setState(() {});
  }

  void _initWebView(String url) {
    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));
  }

  void _startPolling() {
    _pollTimer ??= Timer.periodic(const Duration(seconds: 10), (_) {
      ref.invalidate(projectDetailProvider(widget.projectId));
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ─── 렌더 설정 모달 ─────────────────────────────────────────────────────

  Future<void> _showRenderSettings(ProjectModel project) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('렌더 설정',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // TTS 목소리
                const Text('TTS 목소리',
                    style: TextStyle(color: AppColors.textSecond, fontSize: 13)),
                const SizedBox(height: 6),
                ...([
                  ('ko-KR-InJoonNeural', '남성 (InJoon)'),
                  ('ko-KR-SunHiNeural', '여성 (SunHi)'),
                  ('ko-KR-HyunsuMultilingualNeural', '남성 다국어 (Hyunsu)'),
                ].map((v) => RadioListTile<String>(
                  value: v.$1,
                  groupValue: _renderVoice,
                  title: Text(v.$2,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onChanged: (val) => setModal(() => _renderVoice = val!),
                ))),
                const SizedBox(height: 16),

                // 목표 길이
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('목표 길이',
                        style: TextStyle(color: AppColors.textSecond, fontSize: 13)),
                    Text('$_renderDuration 초',
                        style: const TextStyle(color: AppColors.accent)),
                  ],
                ),
                Slider(
                  value: _renderDuration.toDouble(),
                  min: 30,
                  max: 180,
                  divisions: 10,
                  activeColor: AppColors.accent,
                  onChanged: (v) => setModal(() => _renderDuration = v.round()),
                ),
                const SizedBox(height: 16),

                // BGM
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('BGM',
                        style: TextStyle(color: AppColors.textSecond, fontSize: 13)),
                    Switch(
                      value: _renderBgm,
                      activeColor: AppColors.accent,
                      onChanged: (v) => setModal(() => _renderBgm = v),
                    ),
                  ],
                ),
                if (_renderBgm) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('BGM 볼륨',
                          style: TextStyle(color: AppColors.textSecond, fontSize: 13)),
                      Text('${(_bgmVolume * 100).round()}%',
                          style: const TextStyle(color: AppColors.accent)),
                    ],
                  ),
                  Slider(
                    value: _bgmVolume,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    activeColor: AppColors.accent,
                    onChanged: (v) => setModal(() => _bgmVolume = v),
                  ),
                ],
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _rerender(project);
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('렌더링 시작', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _rerender(ProjectModel project) async {
    try {
      await ref.read(_genRepoProvider).rerender(
        project.projectId,
        renderOptions: {
          'voice': _renderVoice,
          'target_duration': _renderDuration,
          'bgm': _renderBgm,
          'bgm_volume': _bgmVolume,
        },
      );
      ref.invalidate(projectDetailProvider(widget.projectId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('렌더링이 시작되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('렌더링 실패: $e')),
        );
      }
    }
  }

  // ─── 내보내기 ─────────────────────────────────────────────────────────

  Future<void> _export(String type, int projectId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${type.toUpperCase()} 내보내기 중...')),
    );
    try {
      final url = type == 'pdf'
          ? await ref.read(_genRepoProvider).exportPdf(projectId)
          : await ref.read(_genRepoProvider).exportPptx(projectId);

      if (!mounted) return;
      if (url.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.toUpperCase()} 준비 완료'),
            action: SnackBarAction(
              label: '공유',
              onPressed: () async {
                final dir = await getTemporaryDirectory();
                final file = File('${dir.path}/export.${type}');
                await Dio().download(url, file.path);
                await Share.shareXFiles([XFile(file.path)]);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('내보내기 실패: $e')),
        );
      }
    }
  }

  // ─── 제목 편집 ────────────────────────────────────────────────────────

  Future<void> _editTitle(ProjectModel project) async {
    final ctrl = TextEditingController(text: project.title);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('제목 편집',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: '프로젝트 제목'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null && result.isNotEmpty) {
      try {
        await ref.read(projectRepositoryProvider).updateTitle(project.projectId, result);
        ref.invalidate(projectDetailProvider(widget.projectId));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('제목 변경 실패: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectDetailProvider(widget.projectId));

    return projectAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('오류')),
        body: Center(child: Text(e.toString())),
      ),
      data: (project) {
        if (project.isProcessing) {
          _startPolling();
        } else {
          _stopPolling();
        }
        if (project.hasVideo && !_videoInitialized) {
          _initVideo(project.videoUrl!);
        }
        if (project.hasSlide && _webCtrl == null) {
          _initWebView(project.htmlUrl!);
        }

        final hasMultipleTabs = project.hasSlide && project.hasVideo;

        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: () => _editTitle(project),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      project.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, size: 14, color: AppColors.textSecond),
                ],
              ),
            ),
            actions: [
              // 공유 버튼 (영상 있을 때)
              if (project.hasVideo)
                _downloading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: _downloadProgress > 0 ? _downloadProgress : null,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.share),
                        tooltip: '공유/다운로드',
                        onPressed: () =>
                            _downloadAndShare(project.videoUrl!, project.title),
                      ),

              // 더보기 메뉴
              PopupMenuButton<String>(
                onSelected: (v) async {
                  switch (v) {
                    case 'script':
                      context.push('/projects/${widget.projectId}/script');
                      break;
                    case 'subtitle':
                      context.push('/projects/${widget.projectId}/subtitle',
                          extra: project.hasVideo);
                      break;
                    case 'render':
                      _showRenderSettings(project);
                      break;
                    case 'export_pdf':
                      _export('pdf', project.projectId);
                      break;
                    case 'export_pptx':
                      _export('pptx', project.projectId);
                      break;
                    case 'clone':
                      try {
                        final cloned = await ref
                            .read(projectRepositoryProvider)
                            .cloneProject(project.projectId);
                        ref.invalidate(projectsProvider);
                        if (mounted) {
                          context.push('/projects/${cloned.projectId}');
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('복제 실패: $e')),
                          );
                        }
                      }
                      break;
                  }
                },
                itemBuilder: (_) => [
                  if (project.hasSlide) ...[
                    const PopupMenuItem(
                      value: 'script',
                      child: Row(children: [
                        Icon(Icons.edit_note, size: 16),
                        SizedBox(width: 8),
                        Text('대본 편집'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'subtitle',
                      child: Row(children: [
                        Icon(Icons.subtitles_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('자막 편집'),
                      ]),
                    ),
                    const PopupMenuDivider(),
                  ],
                  const PopupMenuItem(
                    value: 'render',
                    child: Row(children: [
                      Icon(Icons.settings_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('렌더 설정'),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  if (project.outputType != 'video') ...[
                    const PopupMenuItem(
                      value: 'export_pdf',
                      child: Row(children: [
                        Icon(Icons.picture_as_pdf, size: 16),
                        SizedBox(width: 8),
                        Text('PDF 내보내기'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'export_pptx',
                      child: Row(children: [
                        Icon(Icons.slideshow, size: 16),
                        SizedBox(width: 8),
                        Text('PPTX 내보내기'),
                      ]),
                    ),
                    const PopupMenuDivider(),
                  ],
                  const PopupMenuItem(
                    value: 'clone',
                    child: Row(children: [
                      Icon(Icons.copy_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('프로젝트 복제'),
                    ]),
                  ),
                ],
              ),
            ],
            bottom: hasMultipleTabs
                ? TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: '슬라이드'),
                      Tab(text: '영상'),
                    ],
                  )
                : null,
          ),
          floatingActionButton: !project.isProcessing
              ? FloatingActionButton.extended(
                  backgroundColor: AppColors.accent,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(project.hasSlide ? '재생성' : '영상 생성'),
                  onPressed: () =>
                      context.push('/projects/${widget.projectId}/generate'),
                )
              : null,
          body: hasMultipleTabs
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _SlideTab(webCtrl: _webCtrl),
                    _VideoTab(project: project, chewieCtrl: _chewieCtrl),
                  ],
                )
              : project.hasSlide
                  ? _SlideTab(webCtrl: _webCtrl)
                  : _VideoTab(project: project, chewieCtrl: _chewieCtrl),
        );
      },
    );
  }
}

class _SlideTab extends StatelessWidget {
  final WebViewController? webCtrl;
  const _SlideTab({this.webCtrl});

  @override
  Widget build(BuildContext context) {
    if (webCtrl == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return WebViewWidget(controller: webCtrl!);
  }
}

class _VideoTab extends StatelessWidget {
  final ProjectModel project;
  final ChewieController? chewieCtrl;
  const _VideoTab({required this.project, this.chewieCtrl});

  @override
  Widget build(BuildContext context) {
    if (project.isProcessing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('콘텐츠 생성 중...', style: TextStyle(color: AppColors.textSecond)),
          ],
        ),
      );
    }
    if (project.isDraft || !project.hasVideo) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library_outlined, size: 48, color: AppColors.textSecond),
            const SizedBox(height: 16),
            Text(
              project.isDraft
                  ? '아직 생성된 콘텐츠가 없습니다.\n아래 버튼으로 생성을 시작하세요.'
                  : '영상이 없습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecond),
            ),
          ],
        ),
      );
    }
    if (chewieCtrl == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Chewie(controller: chewieCtrl!),
      ),
    );
  }
}
