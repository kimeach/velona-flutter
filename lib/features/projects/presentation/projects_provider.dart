import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/project_model.dart';
import '../data/project_repository.dart';
import '../../../core/network/dio_client.dart';

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => ProjectRepository(ref.watch(dioProvider)),
);

final projectsProvider = FutureProvider<List<ProjectModel>>((ref) async {
  return ref.watch(projectRepositoryProvider).getProjects();
});

final projectDetailProvider =
    FutureProvider.family<ProjectModel, int>((ref, projectId) async {
  return ref.watch(projectRepositoryProvider).getProject(projectId);
});
