import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/member_model.dart';
import '../../../core/error/app_exception.dart';

class AuthRepository {
  final Dio _dio;
  final _googleSignIn = GoogleSignIn();

  AuthRepository(this._dio);

  MemberModel _unwrapMember(Response res) {
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return MemberModel.fromJson(data);
  }

  Future<MemberModel> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw const AppException('로그인이 취소되었습니다.');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);

    // POST /api/member/login — 최초 가입 또는 프로필 갱신
    final res = await _dio.post('/api/member/login');
    final member = _unwrapMember(res);

    await _registerFcmToken();
    return member;
  }

  Future<void> _registerFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _dio.put('/api/member/fcm-token', data: {'fcmToken': token});
      }
    } catch (_) {}
  }

  Future<void> signOut() async {
    await Future.wait([
      FirebaseAuth.instance.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<MemberModel?> getMe() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final res = await _dio.get('/api/member/me');
      return _unwrapMember(res);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      throw NetworkException();
    }
  }
}
