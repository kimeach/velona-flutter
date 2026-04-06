import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/projects/presentation/project_list_screen.dart';
import '../features/projects/presentation/project_detail_screen.dart';
import '../features/generate/presentation/generate_screen.dart';
import '../features/generate/presentation/script_editor_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/inquiry/presentation/inquiry_screen.dart';

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
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/inquiry',
        builder: (_, __) => const InquiryScreen(),
      ),
    ],
  );
});

class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
