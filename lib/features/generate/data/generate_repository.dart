import 'package:dio/dio.dart';
import '../../projects/domain/project_model.dart';
import '../domain/question_model.dart';
import '../domain/script_history_model.dart';
import '../domain/ai_result_models.dart';
import '../../../core/error/app_exception.dart';

class GenerateRepository {
  final Dio _dio;
  GenerateRepository(this._dio);

  Map<String, dynamic> _unwrap(Response res) {
    final body = res.data as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  List<dynamic> _unwrapList(Response res) {
    final body = res.data as Map<String, dynamic>;
    return body['data'] as List<dynamic>;
  }

  ServerException _serverErr(DioException e, String fallback) {
    final msg = (e.response?.data as Map?)?['message'] as String?;
    return ServerException(msg ?? fallback);
  }

  // ─── 생성 ───────────────────────────────────────────────────────────────

  /// 카테고리 + 옵션 기반 프로젝트 생성
  Future<ProjectModel> generate({
    required String category,
    required Map<String, dynamic> options,
    String templateId = 'dark_blue',
  }) async {
    try {
      final res = await _dio.post(
        '/api/shorts/projects/generate',
        data: {
          'category': category,
          'template_id': templateId,
          'options': options,
        },
      );
      return ProjectModel.fromJson(_unwrap(res));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      if (e.response?.statusCode == 402) throw _serverErr(e, '월 사용량을 초과했습니다.');
      throw _serverErr(e, '생성 요청 실패');
    }
  }

  /// 주식 영상 생성 (하위 호환)
  Future<ProjectModel> generateStock({
    required String ticker,
    String? voice,
    int? targetDuration,
    String templateId = 'dark_blue',
  }) async {
    return generate(
      category: 'stock',
      options: {
        'ticker': ticker,
        if (voice != null) 'voice': voice,
        if (targetDuration != null) 'target_duration': targetDuration,
      },
      templateId: templateId,
    );
  }

  // ─── 설문 질문 ─────────────────────────────────────────────────────────

  Future<List<QuestionModel>> getQuestions(String category) async {
    try {
      final res = await _dio.get(
        '/api/shorts/questions',
        queryParameters: {'category': category},
      );
      final list = _unwrapList(res);
      return list
          .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  // ─── 트렌딩 토픽 ───────────────────────────────────────────────────────

  Future<List<TrendingTopicModel>> getTrendingTopics() async {
    try {
      final res = await _dio.get('/api/shorts/trending/topics');
      final list = _unwrapList(res);
      return list
          .map((e) => TrendingTopicModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  // ─── 렌더링 ────────────────────────────────────────────────────────────

  Future<ProjectModel> rerender(int projectId, {Map<String, dynamic>? renderOptions}) async {
    try {
      final res = await _dio.post(
        '/api/shorts/projects/$projectId/render',
        data: renderOptions,
      );
      return ProjectModel.fromJson(_unwrap(res));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      if (e.response?.statusCode == 402) throw _serverErr(e, '월 사용량을 초과했습니다.');
      throw NetworkException();
    }
  }

  // ─── 스크립트 ──────────────────────────────────────────────────────────

  Future<void> updateScript(int projectId, Map<String, String> script) async {
    try {
      await _dio.put('/api/shorts/projects/$projectId/script', data: script);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  Future<Map<String, String>> getScript(int projectId) async {
    try {
      final res = await _dio.get('/api/shorts/projects/$projectId');
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final raw = data['script'];
      if (raw == null) return {};
      return (raw as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  // ─── 스크립트 히스토리 ─────────────────────────────────────────────────

  Future<List<ScriptHistoryModel>> getScriptHistory(int projectId) async {
    try {
      final res = await _dio.get('/api/shorts/projects/$projectId/script/history');
      final list = _unwrapList(res);
      return list
          .map((e) => ScriptHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw NetworkException();
    }
  }

  Future<Map<String, String>> restoreScriptHistory(int projectId, int historyId) async {
    try {
      final res = await _dio.post(
        '/api/shorts/projects/$projectId/script/history/$historyId/restore',
      );
      final data = _unwrap(res);
      final raw = data['script'] as Map? ?? {};
      return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const UnauthorizedException();
      throw _serverErr(e, '히스토리 복원 실패');
    }
  }

  // ─── TTS ───────────────────────────────────────────────────────────────

  Future<List<int>> getTtsBytes({required String text, required String voice}) async {
    try {
      final res = await _dio.post(
        '/api/shorts/tts-preview',
        data: {'text': text, 'voice': voice},
        options: Options(responseType: ResponseType.bytes),
      );
      return res.data as List<int>;
    } on DioException catch (e) {
      throw _serverErr(e, 'TTS 생성 실패');
    }
  }

  // ─── AI 기능 ───────────────────────────────────────────────────────────

  Future<String> aiRewrite({
    required int projectId,
    required String text,
    required String style,
    String? instruction,
  }) async {
    try {
      final res = await _dio.post(
        '/api/shorts/projects/$projectId/ai/rewrite',
        data: {
          'text': text,
          'style': style,
          if (instruction != null) 'instruction': instruction,
        },
      );
      final body = res.data as Map<String, dynamic>;
      return body['data'] as String;
    } on DioException catch (e) {
      throw _serverErr(e, 'AI 재작성 실패');
    }
  }

  Future<String> aiTranslate({
    required int projectId,
    required String text,
    required String targetLang,
  }) async {
    try {
      final res = await _dio.post(
        '/api/shorts/projects/$projectId/ai/translate',
        data: {'text': text, 'targetLang': targetLang},
      );
      final body = res.data as Map<String, dynamic>;
      return body['data'] as String;
    } on DioException catch (e) {
      throw _serverErr(e, '번역 실패');
    }
  }

  Future<List<String>> aiHashtags(int projectId) async {
    try {
      final res = await _dio.post(
        '/api/shorts/projects/$projectId/ai/hashtags',
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'];
      if (data is List) return data.map((e) => e.toString()).toList();
      return [];
    } on DioException catch (e) {
      throw _serverErr(e, '해시태그 생성 실패');
    }
  }

  Future<SeoResultModel> aiSeo(int projectId) async {
    try {
      final res = await _dio.post('/api/shorts/projects/$projectId/ai/seo');
      return SeoResultModel.fromJson(_unwrap(res));
    } on DioException catch (e) {
      throw _serverErr(e, 'SEO 생성 실패');
    }
  }

  Future<QualityResultModel> aiQuality(int projectId) async {
    try {
      final res = await _dio.post('/api/shorts/projects/$projectId/ai/quality');
      return QualityResultModel.fromJson(_unwrap(res));
    } on DioException catch (e) {
      throw _serverErr(e, '품질 분석 실패');
    }
  }

  // ─── 자막 ──────────────────────────────────────────────────────────────

  Future<String> generateSubtitleFromScript(int projectId) async {
    try {
      final res = await _dio.post(
        '/api/shorts/projects/$projectId/subtitle/script',
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'];
      return data is String ? data : (data as Map?)?['srt']?.toString() ?? '';
    } on DioException catch (e) {
      throw _serverErr(e, '자막 생성 실패');
    }
  }

  Future<String> generateSubtitleFromVideo(int projectId) async {
    try {
      final res = await _dio.post(
        '/api/shorts/projects/$projectId/subtitle/video',
      );
      final body = res.data as Map<String, dynamic>;
      final data = body['data'];
      return data is String ? data : (data as Map?)?['srt']?.toString() ?? '';
    } on DioException catch (e) {
      throw _serverErr(e, '영상 자막 추출 실패');
    }
  }

  // ─── 내보내기 ──────────────────────────────────────────────────────────

  Future<String> exportPdf(int projectId) async {
    try {
      final res = await _dio.post('/api/shorts/projects/$projectId/export/pdf');
      final body = res.data as Map<String, dynamic>;
      final data = body['data'];
      return data is String ? data : (data as Map?)?['url']?.toString() ?? '';
    } on DioException catch (e) {
      throw _serverErr(e, 'PDF 내보내기 실패');
    }
  }

  Future<String> exportPptx(int projectId) async {
    try {
      final res = await _dio.post('/api/shorts/projects/$projectId/export/pptx');
      final body = res.data as Map<String, dynamic>;
      final data = body['data'];
      return data is String ? data : (data as Map?)?['url']?.toString() ?? '';
    } on DioException catch (e) {
      throw _serverErr(e, 'PPTX 내보내기 실패');
    }
  }
}
