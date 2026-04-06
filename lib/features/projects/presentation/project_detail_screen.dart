import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/project_model.dart';
import 'projects_provider.dart';

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
        // 폴링 관리
        if (project.isProcessing) {
          _startPolling();
        } else {
          _stopPolling();
        }
        // 비디오 초기화
        if (project.hasVideo && !_videoInitialized) {
          _initVideo(project.videoUrl!);
        }
        // 슬라이드 웹뷰 초기화
        if (project.hasSlide && _webCtrl == null) {
          _initWebView(project.htmlUrl!);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(project.title),
            actions: [
              if (project.hasSlide)
                IconButton(
                  icon: const Icon(Icons.edit_note),
                  tooltip: '대본 편집',
                  onPressed: () =>
                      context.push('/projects/${widget.projectId}/script'),
                ),
            ],
            bottom: project.hasSlide
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
          body: project.hasSlide
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _SlideTab(webCtrl: _webCtrl),
                    _VideoTab(
                      project: project,
                      chewieCtrl: _chewieCtrl,
                    ),
                  ],
                )
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
            Text('영상 생성 중...', style: TextStyle(color: AppColors.textSecond)),
          ],
        ),
      );
    }
    if (!project.hasVideo) {
      return const Center(
        child: Text('영상이 없습니다.', style: TextStyle(color: AppColors.textSecond)),
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
