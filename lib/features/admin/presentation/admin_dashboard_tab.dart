import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/admin_models.dart';
import 'admin_screen.dart';

final _dashboardProvider = FutureProvider.family<DashboardMetrics, int>((ref, days) {
  return ref.read(adminRepoProvider).getDashboard(days: days);
});

class AdminDashboardTab extends ConsumerStatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  ConsumerState<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends ConsumerState<AdminDashboardTab> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(_dashboardProvider(_days));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_dashboardProvider(_days)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 기간 선택
            Row(
              children: [
                const Text('기간', style: TextStyle(color: AppColors.textSecond)),
                const SizedBox(width: 12),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7일')),
                    ButtonSegment(value: 14, label: Text('14일')),
                    ButtonSegment(value: 30, label: Text('30일')),
                  ],
                  selected: {_days},
                  onSelectionChanged: (s) => setState(() => _days = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? AppColors.accent
                          : AppColors.surface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            metricsAsync.when(
              loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  )),
              error: (e, _) => Center(
                child: Text('로드 실패: $e',
                    style: const TextStyle(color: AppColors.error)),
              ),
              data: (metrics) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DAU
                  _MetricCard(
                    title: '일별 활성 사용자 (DAU)',
                    data: metrics.dauData.map((e) => _Bar(e.date, e.count.toDouble())).toList(),
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 16),

                  // 요청 수
                  _MetricCard(
                    title: '일별 API 요청',
                    data: metrics.requestData.map((e) => _Bar(e.date, e.count.toDouble())).toList(),
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 16),

                  // 에러 수
                  _MetricCard(
                    title: '일별 에러',
                    data: metrics.errorData.map((e) => _Bar(e.date, e.count.toDouble())).toList(),
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),

                  // 느린 API
                  if (metrics.slowApis.isNotEmpty) ...[
                    const Text('느린 API Top',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...metrics.slowApis.map((api) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          api.endpoint,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${api.avgMs.round()}ms',
                              style: TextStyle(
                                color: api.avgMs > 2000 ? AppColors.error : AppColors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('${api.count}회',
                                style: const TextStyle(
                                    color: AppColors.textSecond, fontSize: 11)),
                          ],
                        ),
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar {
  final String label;
  final double value;
  const _Bar(this.label, this.value);
}

class _MetricCard extends StatelessWidget {
  final String title;
  final List<_Bar> data;
  final Color color;

  const _MetricCard({required this.title, required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxVal = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final total = data.fold<double>(0, (sum, e) => sum + e.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Text('합계: ${total.round()}',
                    style: const TextStyle(color: AppColors.textSecond, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((bar) {
                  final ratio = maxVal > 0 ? bar.value / maxVal : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            bar.value.round().toString(),
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: (80 * ratio).clamp(2.0, 80.0),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.8),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(2)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bar.label.length > 5
                                ? bar.label.substring(bar.label.length - 5)
                                : bar.label,
                            style: const TextStyle(
                                color: AppColors.textSecond, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
