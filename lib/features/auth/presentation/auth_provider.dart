import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/member_model.dart';
import '../data/auth_repository.dart';
import '../../../core/network/dio_client.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

// 현재 로그인 사용자 상태
final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<MemberModel?>>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);

class AuthNotifier extends StateNotifier<AsyncValue<MemberModel?>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final member = await _repo.getMe();
      state = AsyncValue.data(member);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final member = await _repo.signInWithGoogle();
      state = AsyncValue.data(member);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncValue.data(null);
  }
}
