import 'package:dio/dio.dart';
import '../domain/admin_models.dart';
import '../../../core/error/app_exception.dart';

class AdminRepository {
  final Dio _dio;
  AdminRepository(this._dio);

  Map<String, dynamic> _unwrap(Response res) {
    final body = res.data as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  List<dynamic> _unwrapList(Response res) {
    final body = res.data as Map<String, dynamic>;
    return body['data'] as List<dynamic>;
  }

  // ─── Dashboard ─────────────────────────────────────────────────────────

  Future<DashboardMetrics> getDashboard({int days = 7}) async {
    try {
      final res = await _dio.get(
        '/api/admin/dashboard',
        queryParameters: {'days': days},
      );
      return DashboardMetrics.fromJson(_unwrap(res));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  // ─── Users ─────────────────────────────────────────────────────────────

  Future<List<AdminUser>> getUsers({String? query}) async {
    try {
      final res = await _dio.get(
        '/api/admin/users',
        queryParameters: (query != null && query.isNotEmpty) ? {'q': query} : null,
      );
      final list = _unwrapList(res);
      return list
          .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  Future<Map<String, dynamic>> getUserDetail(int memberId) async {
    try {
      final res = await _dio.get('/api/admin/users/$memberId');
      return _unwrap(res);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  // ─── Projects ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProjects() async {
    try {
      final res = await _dio.get('/api/admin/projects');
      final list = _unwrapList(res);
      return list.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  Future<void> deleteProject(int projectId) async {
    try {
      await _dio.delete('/api/admin/projects/$projectId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  // ─── Errors ────────────────────────────────────────────────────────────

  Future<List<ErrorLog>> getErrors({String? level, String? source}) async {
    try {
      final res = await _dio.get(
        '/api/admin/errors',
        queryParameters: {
          if (level != null) 'level': level,
          if (source != null) 'source': source,
        },
      );
      final list = _unwrapList(res);
      return list
          .map((e) => ErrorLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  Future<void> clearErrors({int days = 30}) async {
    try {
      await _dio.delete(
        '/api/admin/errors',
        queryParameters: {'days': days},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  // ─── System ────────────────────────────────────────────────────────────

  Future<SystemStatus> getSystemStatus() async {
    try {
      final res = await _dio.get('/api/admin/system');
      return SystemStatus.fromJson(_unwrap(res));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  // ─── Announcements ─────────────────────────────────────────────────────

  Future<List<Announcement>> getAnnouncements() async {
    try {
      final res = await _dio.get('/api/admin/announcements');
      final list = _unwrapList(res);
      return list
          .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  Future<void> sendAnnouncement({
    required String title,
    required String body,
  }) async {
    try {
      await _dio.post(
        '/api/admin/announce',
        data: {'title': title, 'body': body},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      final msg = (e.response?.data as Map?)?['message'] as String?;
      throw ServerException(msg ?? '공지 발송 실패');
    }
  }
}
