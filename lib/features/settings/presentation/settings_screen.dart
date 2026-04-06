import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/presentation/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          // 프로필
          if (member != null)
            _Section(
              title: '계정',
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline, color: AppColors.textSecond),
                  title: Text(member.name ?? member.email,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(member.email,
                      style: const TextStyle(color: AppColors.textSecond, fontSize: 12)),
                ),
              ],
            ),

          // 앱 정보
          _Section(
            title: '앱',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppColors.textSecond),
                title: const Text('버전', style: TextStyle(color: AppColors.textPrimary)),
                trailing: const Text('1.0.0', style: TextStyle(color: AppColors.textSecond)),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: AppColors.textSecond),
                title: const Text('이용약관', style: TextStyle(color: AppColors.textPrimary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecond),
                onTap: () {}, // TODO: webview
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.textSecond),
                title: const Text('개인정보처리방침', style: TextStyle(color: AppColors.textPrimary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecond),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.headset_mic_outlined, color: AppColors.textSecond),
                title: const Text('1:1 문의', style: TextStyle(color: AppColors.textPrimary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecond),
                onTap: () => context.push('/inquiry'),
              ),
            ],
          ),

          // 로그아웃
          _Section(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('로그아웃', style: TextStyle(color: AppColors.error)),
                onTap: () => _confirmLogout(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('로그아웃', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('로그아웃 하시겠습니까?',
            style: TextStyle(color: AppColors.textSecond)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authStateProvider.notifier).signOut();
            },
            child: const Text('로그아웃',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _Section({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Text(
              title!,
              style: const TextStyle(
                color: AppColors.textSecond,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ...children,
        const Divider(height: 1),
      ],
    );
  }
}
