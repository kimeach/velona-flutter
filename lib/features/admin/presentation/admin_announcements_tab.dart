import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/admin_models.dart';
import 'admin_screen.dart';

final _announcementsProvider = FutureProvider<List<Announcement>>((ref) {
  return ref.read(adminRepoProvider).getAnnouncements();
});

class AdminAnnouncementsTab extends ConsumerStatefulWidget {
  const AdminAnnouncementsTab({super.key});

  @override
  ConsumerState<AdminAnnouncementsTab> createState() => _AdminAnnouncementsTabState();
}

class _AdminAnnouncementsTabState extends ConsumerState<AdminAnnouncementsTab> {
  bool _sending = false;

  Future<void> _showSendDialog() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('공지 발송',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: '공지 제목',
                labelText: '제목',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '공지 내용을 입력하세요...',
                labelText: '내용',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('전체 발송'),
          ),
        ],
      ),
    );

    if (result == true &&
        titleCtrl.text.trim().isNotEmpty &&
        bodyCtrl.text.trim().isNotEmpty) {
      setState(() => _sending = true);
      try {
        await ref.read(adminRepoProvider).sendAnnouncement(
          title: titleCtrl.text.trim(),
          body: bodyCtrl.text.trim(),
        );
        ref.invalidate(_announcementsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('공지가 발송되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('발송 실패: $e')));
        }
      } finally {
        if (mounted) setState(() => _sending = false);
      }
    }
    titleCtrl.dispose();
    bodyCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(_announcementsProvider);

    return Column(
      children: [
        // 발송 버튼
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _showSendDialog,
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.campaign),
              label: const Text('전체 사용자에게 공지 발송'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('발송 히스토리',
                style: TextStyle(
                    color: AppColors.textSecond,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: announcementsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(e.toString(),
                  style: const TextStyle(color: AppColors.error)),
            ),
            data: (announcements) {
              if (announcements.isEmpty) {
                return const Center(
                  child: Text('발송 내역이 없습니다.',
                      style: TextStyle(color: AppColors.textSecond)),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(_announcementsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: announcements.length,
                  itemBuilder: (_, i) {
                    final a = announcements[i];
                    final dt = a.createdAt;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.notifications_outlined,
                            color: AppColors.accent),
                        title: Text(a.title,
                            style: const TextStyle(color: AppColors.textPrimary)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.body,
                              style: const TextStyle(
                                  color: AppColors.textSecond, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  color: AppColors.textSecond, fontSize: 11),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${a.sentCount}명',
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold),
                            ),
                            const Text('발송',
                                style: TextStyle(
                                    color: AppColors.textSecond, fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
