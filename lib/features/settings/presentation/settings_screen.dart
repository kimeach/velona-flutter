import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/presentation/auth_provider.dart';

// 기본 TTS 목소리 설정 (전역 provider)
final defaultVoiceProvider = StateProvider<String>((ref) => 'ko-KR-InJoonNeural');

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _voices = [
    ('ko-KR-InJoonNeural', '남성 (InJoon)'),
    ('ko-KR-SunHiNeural', '여성 (SunHi)'),
    ('ko-KR-HyunsuMultilingualNeural', '남성 다국어 (Hyunsu)'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(authStateProvider).valueOrNull;
    final defaultVoice = ref.watch(defaultVoiceProvider);
    final isAdmin = member != null && AppConfig.isAdmin(member.email);

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
                  leading: member.profileImg != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(member.profileImg!),
                          radius: 20,
                        )
                      : const Icon(Icons.person_outline, color: AppColors.textSecond),
                  title: Text(member.displayName,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(member.email,
                      style: const TextStyle(color: AppColors.textSecond, fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: member.plan == 'premium'
                          ? AppColors.warning.withOpacity(0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: member.plan == 'premium'
                            ? AppColors.warning
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      member.plan.toUpperCase(),
                      style: TextStyle(
                        color: member.plan == 'premium'
                            ? AppColors.warning
                            : AppColors.textSecond,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // 콘텐츠 생성 설정
          _Section(
            title: '생성 설정',
            children: [
              // 기본 TTS 목소리
              ExpansionTile(
                leading: const Icon(Icons.record_voice_over_outlined,
                    color: AppColors.textSecond),
                title: const Text('기본 TTS 목소리',
                    style: TextStyle(color: AppColors.textPrimary)),
                subtitle: Text(
                  _voices.firstWhere((v) => v.$1 == defaultVoice,
                      orElse: () => _voices[0]).$2,
                  style: const TextStyle(color: AppColors.textSecond, fontSize: 12),
                ),
                iconColor: AppColors.textSecond,
                collapsedIconColor: AppColors.textSecond,
                children: _voices.map((v) => RadioListTile<String>(
                  value: v.$1,
                  groupValue: defaultVoice,
                  title: Text(v.$2,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  activeColor: AppColors.accent,
                  contentPadding: const EdgeInsets.only(left: 16, right: 8),
                  dense: true,
                  onChanged: (val) =>
                      ref.read(defaultVoiceProvider.notifier).state = val!,
                )).toList(),
              ),

              // 목소리 복제
              ListTile(
                leading: const Icon(Icons.mic_outlined, color: AppColors.textSecond),
                title: const Text('내 목소리 관리',
                    style: TextStyle(color: AppColors.textPrimary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecond),
                onTap: () => context.push('/voices'),
              ),
            ],
          ),

          // 앱 정보
          _Section(
            title: '앱',
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline, color: AppColors.textSecond),
                title: Text('버전', style: TextStyle(color: AppColors.textPrimary)),
                trailing: Text('1.0.0', style: TextStyle(color: AppColors.textSecond)),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: AppColors.textSecond),
                title: const Text('이용약관',
                    style: TextStyle(color: AppColors.textPrimary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecond),
                onTap: () {}, // TODO: WebView
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.textSecond),
                title: const Text('개인정보처리방침',
                    style: TextStyle(color: AppColors.textPrimary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecond),
                onTap: () {}, // TODO: WebView
              ),
              ListTile(
                leading: const Icon(Icons.headset_mic_outlined, color: AppColors.textSecond),
                title: const Text('1:1 문의',
                    style: TextStyle(color: AppColors.textPrimary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecond),
                onTap: () => context.push('/inquiry'),
              ),
            ],
          ),

          // 관리자 (어드민 이메일만 표시)
          if (isAdmin)
            _Section(
              title: '관리자',
              children: [
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined,
                      color: AppColors.error),
                  title: const Text('어드민 대시보드',
                      style: TextStyle(color: AppColors.textPrimary)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecond),
                  onTap: () => context.push('/admin'),
                ),
              ],
            ),

          // 로그아웃
          _Section(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('로그아웃',
                    style: TextStyle(color: AppColors.error)),
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
        title: const Text('로그아웃',
            style: TextStyle(color: AppColors.textPrimary)),
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
