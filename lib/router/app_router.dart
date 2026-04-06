import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/projects/presentation/project_list_screen.dart';
import '../features/projects/presentation/project_detail_screen.dart';
import '../features/generate/presentation/generate_screen.dart';
import '../features/generate/presentation/script_editor_screen.dart';
import '../features/subtitle/presentation/subtitle_editor_screen.dart';
import '../features/voice/presentation/voice_list_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/inquiry/presentation/inquiry_screen.dart';
import '../features/admin/presentation/admin_screen.dart';
import '../core/constants/app_constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/projects',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      if (authState is AsyncLoading) return null;
      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';
      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/projects';
      return null;
    },
    refreshListenable: _AuthStateNotifier(ref),
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),

      // ─── 프로젝트 ─────────────────────────────────────────────────────
      GoRoute(
        path: '/projects',
        builder: (_, __) => const ProjectListScreen(),
        routes: [
          GoRoute(
            path: ':projectId',
            builder: (_, state) => ProjectDetailScreen(
              projectId: int.parse(state.pathParameters['projectId']!),
            ),
            routes: [
              GoRoute(
                path: 'generate',
                builder: (_, state) => GenerateScreen(
                  projectId: int.parse(state.pathParameters['projectId']!),
                ),
              ),
              GoRoute(
                path: 'script',
                builder: (_, state) => ScriptEditorScreen(
                  projectId: int.parse(state.pathParameters['projectId']!),
                ),
              ),
              GoRoute(
                path: 'subtitle',
                builder: (_, state) {
                  final projectId = int.parse(state.pathParameters['projectId']!);
                  final hasVideo = state.extra as bool? ?? false;
                  return SubtitleEditorScreen(
                    projectId: projectId,
                    hasVideo: hasVideo,
                  );
                },
              ),
            ],
          ),
        ],
      ),

      // ─── 설정 ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),

      // ─── 문의 ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/inquiry',
        builder: (_, __) => const InquiryScreen(),
      ),

      // ─── 목소리 관리 ──────────────────────────────────────────────────
      GoRoute(
        path: '/voices',
        builder: (_, __) => const VoiceListScreen(),
      ),

      // ─── 어드민 ───────────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        redirect: (context, state) {
          final authState = ref.read(authStateProvider);
          final member = authState.valueOrNull;
          if (member == null || !AppConfig.isAdmin(member.email)) {
            return '/projects';
          }
          return null;
        },
        builder: (_, __) => const AdminScreen(),
      ),
    ],
  );
});

class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
