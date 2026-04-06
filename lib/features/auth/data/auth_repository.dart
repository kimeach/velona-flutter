import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/member_model.dart';
import '../../../core/error/app_exception.dart';

class AuthRepository {
  final Dio _dio;
  final _googleSignIn = GoogleSignIn();

  AuthRepository(this._dio);

  Future<MemberModel> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw const AppException('로그인이 취소되었습니다.');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);

    // Crown API에 Firebase 토큰으로 회원 정보 요청 (자동 가입 포함)
    final res = await _dio.get('/api/member/me');
    return MemberModel.fromJson(res.data as Map<String, dynamic>);
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
      return MemberModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      throw NetworkException();
    }
  }
}
