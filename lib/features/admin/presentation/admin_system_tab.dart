import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/admin_models.dart';
import 'admin_screen.dart';

final _systemProvider = FutureProvider<SystemStatus>((ref) {
  return ref.read(adminRepoProvider).getSystemStatus();
});

class AdminSystemTab extends ConsumerWidget {
  const AdminSystemTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(_systemProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_systemProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: statusAsync.when(
          loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('로드 실패: $e',
                    style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(_systemProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
          data: (status) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('서비스 상태',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 12),

              _StatusCard(
                icon: Icons.work_outline,
                label: 'Python Worker',
                online: status.workerOnline,
                detail: status.workerVersion != null
                    ? 'v${status.workerVersion}'
                    : null,
              ),
              const SizedBox(height: 8),

              _StatusCard(
                icon: Icons.storage_outlined,
                label: 'Database',
                online: status.dbOnline,
              ),
              const SizedBox(height: 8),

              if (status.queueLength != null) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.queue_outlined,
                        color: AppColors.textSecond),
                    title: const Text('대기 중인 작업',
                        style: TextStyle(color: AppColors.textPrimary)),
                    trailing: Text(
                      '${status.queueLength}개',
                      style: TextStyle(
                        color: status.queueLength! > 10
                            ? AppColors.warning
                            : AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 기타 항목
              if (status.raw.isNotEmpty) ...[
                const Text('상세 정보',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...status.raw.entries
                    .where((e) =>
                        e.key != 'workerOnline' &&
                        e.key != 'dbOnline' &&
                        e.key != 'workerVersion' &&
                        e.key != 'queueLength')
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(e.key,
                                    style: const TextStyle(
                                        color: AppColors.textSecond,
                                        fontSize: 13)),
                              ),
                              Expanded(
                                child: Text(
                                  e.value?.toString() ?? '-',
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool online;
  final String? detail;

  const _StatusCard({
    required this.icon,
    required this.label,
    required this.online,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecond),
        title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
        subtitle: detail != null
            ? Text(detail!,
                style: const TextStyle(color: AppColors.textSecond, fontSize: 12))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: online ? AppColors.success : AppColors.error,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              online ? 'ONLINE' : 'OFFLINE',
              style: TextStyle(
                color: online ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
