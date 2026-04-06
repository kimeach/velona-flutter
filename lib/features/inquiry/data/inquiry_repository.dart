import 'package:dio/dio.dart';
import '../../../core/error/app_exception.dart';

class InquiryRepository {
  final Dio _dio;
  InquiryRepository(this._dio);

  Future<void> submitInquiry({
    required String title,
    required String content,
  }) async {
    try {
      await _dio.post('/api/inquiry', data: {'title': title, 'content': content});
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  Future<void> submitGuestInquiry({
    required String email,
    required String title,
    required String content,
  }) async {
    try {
      await _dio.post('/api/inquiry/guest', data: {
        'email': email,
        'title': title,
        'content': content,
      });
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw ServerException(msg ?? '문의 전송 실패');
    }
  }
}
