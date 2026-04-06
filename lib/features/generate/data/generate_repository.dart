import 'package:dio/dio.dart';
import '../../projects/domain/project_model.dart';
import '../../../core/error/app_exception.dart';

class GenerateRepository {
  final Dio _dio;
  GenerateRepository(this._dio);

  Future<ProjectModel> generateStock({
    required int projectId,
    required String ticker,
    String? voice,
    int? targetDuration,
  }) async {
    try {
      final res = await _dio.post(
        '/api/shorts/projects/$projectId/generate',
        data: {
          'ticker': ticker,
          if (voice != null) 'voice': voice,
          if (targetDuration != null) 'targetDuration': targetDuration,
        },
      );
      return ProjectModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      final msg = e.response?.data?['message'] as String?;
      throw ServerException(msg ?? '생성 요청 실패');
    }
  }

  Future<ProjectModel> rerender(int projectId) async {
    try {
      final res = await _dio.post('/api/shorts/projects/$projectId/render');
      return ProjectModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  Future<void> updateScript(int projectId, List<Map<String, dynamic>> clips) async {
    try {
      await _dio.put(
        '/api/shorts/projects/$projectId/script',
        data: {'clips': clips},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  Future<List<Map<String, dynamic>>> getScript(int projectId) async {
    try {
      final res = await _dio.get('/api/shorts/projects/$projectId/script');
      return (res.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }
}
