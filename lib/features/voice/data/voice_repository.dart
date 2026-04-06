import 'package:dio/dio.dart';
import '../domain/voice_model.dart';
import '../../../core/error/app_exception.dart';

class VoiceRepository {
  final Dio _dio;
  VoiceRepository(this._dio);

  List<dynamic> _unwrapList(Response res) {
    final body = res.data as Map<String, dynamic>;
    return body['data'] as List<dynamic>;
  }

  Map<String, dynamic> _unwrap(Response res) {
    final body = res.data as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  Future<List<VoiceModel>> getVoices() async {
    try {
      final res = await _dio.get('/api/shorts/voice/list');
      final list = _unwrapList(res);
      return list
          .map((e) => VoiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  Future<VoiceModel> cloneVoice({
    required String filePath,
    required String name,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'file': await MultipartFile.fromFile(filePath),
      });
      final res = await _dio.post(
        '/api/shorts/voice/clone',
        data: formData,
      );
      return VoiceModel.fromJson(_unwrap(res));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      final msg = (e.response?.data as Map?)?['message'] as String?;
      throw ServerException(msg ?? '목소리 복제 실패');
    }
  }

  Future<void> deleteVoice(int voiceId) async {
    try {
      await _dio.delete('/api/shorts/voice/$voiceId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }
}
