import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/project_card.dart';
import '../../../shared/widgets/shimmer_card.dart';
import '../../../shared/widgets/error_view.dart';
import '../../auth/presentation/auth_provider.dart';
import 'projects_provider.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로젝트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewProjectSheet(context, ref),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add),
        label: const Text('새 프로젝트'),
      ),
      body: projectsAsync.when(
        loading: () => const ShimmerList(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(projectsProvider),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(
              child: Text(
                '프로젝트가 없습니다.\n새 프로젝트를 만들어보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecond),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(projectsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              itemBuilder: (context, index) => ProjectCard(
                project: projects[index],
                onTap: () => context.push('/projects/${projects[index].projectId}'),
                onDelete: () async {
                  await ref
                      .read(projectRepositoryProvider)
                      .deleteProject(projects[index].projectId);
                  ref.invalidate(projectsProvider);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNewProjectSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _NewProjectSheet(ref: ref),
    );
  }
}

class _NewProjectSheet extends StatelessWidget {
  final WidgetRef ref;
  const _NewProjectSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '새 프로젝트 유형',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          for (final type in [
            ('video', Icons.videocam, '영상 (YouTube Shorts)'),
            ('ppt', Icons.slideshow, 'PPT 슬라이드'),
            ('pdf', Icons.picture_as_pdf, 'PDF 문서'),
          ])
            ListTile(
              leading: Icon(type.$2, color: AppColors.accent),
              title: Text(type.$3,
                  style: const TextStyle(color: AppColors.textPrimary)),
              onTap: () async {
                Navigator.pop(context);
                final project = await ref
                    .read(projectRepositoryProvider)
                    .createBlank(outputType: type.$1);
                ref.invalidate(projectsProvider);
                if (context.mounted) {
                  context.push('/projects/${project.projectId}');
                }
              },
            ),
        ],
      ),
    );
  }
}
