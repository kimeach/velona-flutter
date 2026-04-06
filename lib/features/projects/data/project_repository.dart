import 'package:dio/dio.dart';
import '../domain/project_model.dart';
import '../../../core/error/app_exception.dart';

class ProjectRepository {
  final Dio _dio;

  ProjectRepository(this._dio);

  Map<String, dynamic> _unwrap(Response res) {
    final body = res.data as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  List<dynamic> _unwrapList(Response res) {
    final body = res.data as Map<String, dynamic>;
    return body['data'] as List<dynamic>;
  }

  Future<List<ProjectModel>> getProjects() async {
    try {
      final res = await _dio.get('/api/shorts/projects');
      final list = _unwrapList(res);
      return list
          .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  Future<ProjectModel> getProject(int projectId) async {
    try {
      final res = await _dio.get('/api/shorts/projects/$projectId');
      return ProjectModel.fromJson(_unwrap(res));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  Future<ProjectModel> createBlank({String outputType = 'video'}) async {
    try {
      final res = await _dio.post(
        '/api/shorts/projects/blank',
        data: {'output_type': outputType},
      );
      return ProjectModel.fromJson(_unwrap(res));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  Future<void> deleteProject(int projectId) async {
    try {
      await _dio.delete('/api/shorts/projects/$projectId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  Future<ProjectModel> cloneProject(int projectId) async {
    try {
      final res = await _dio.post('/api/shorts/projects/$projectId/duplicate');
      return ProjectModel.fromJson(_unwrap(res));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  Future<void> updateTitle(int projectId, String title) async {
    try {
      await _dio.patch(
        '/api/shorts/projects/$projectId/title',
        data: {'title': title},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }
}
