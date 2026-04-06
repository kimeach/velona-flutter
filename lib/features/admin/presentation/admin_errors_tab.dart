import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/admin_models.dart';
import 'admin_screen.dart';

class AdminErrorsTab extends ConsumerStatefulWidget {
  const AdminErrorsTab({super.key});

  @override
  ConsumerState<AdminErrorsTab> createState() => _AdminErrorsTabState();
}

class _AdminErrorsTabState extends ConsumerState<AdminErrorsTab> {
  List<ErrorLog> _errors = [];
  bool _loading = true;
  String? _error;
  String? _levelFilter;
  String? _sourceFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final errors = await ref.read(adminRepoProvider).getErrors(
        level: _levelFilter,
        source: _sourceFilter,
      );
      setState(() { _errors = errors; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _clearOldErrors() async {
    final confirm = await showDialog<int>(
      context: context,
      builder: (_) {
        int days = 30;
        return StatefulBuilder(
          builder: (ctx, setDialog) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('오래된 에러 삭제',
                style: TextStyle(color: AppColors.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('몇 일 이전 에러를 삭제할까요?',
                    style: TextStyle(color: AppColors.textSecond)),
                Slider(
                  value: days.toDouble(),
                  min: 7,
                  max: 90,
                  divisions: 5,
                  activeColor: AppColors.error,
                  onChanged: (v) => setDialog(() => days = v.round()),
                ),
                Text('$days일 이전 에러 삭제',
                    style: const TextStyle(color: AppColors.textPrimary)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, days),
                child: const Text('삭제', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != null) {
      try {
        await ref.read(adminRepoProvider).clearErrors(days: confirm);
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$confirm일 이전 에러가 삭제되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
        }
      }
    }
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'ERROR': return AppColors.error;
      case 'WARN': return AppColors.warning;
      default: return AppColors.textSecond;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 필터 + 삭제
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // 레벨 필터
              DropdownButton<String?>(
                value: _levelFilter,
                dropdownColor: AppColors.surface,
                hint: const Text('레벨', style: TextStyle(color: AppColors.textSecond)),
                items: const [
                  DropdownMenuItem(value: null, child: Text('전체')),
                  DropdownMenuItem(value: 'ERROR', child: Text('ERROR')),
                  DropdownMenuItem(value: 'WARN', child: Text('WARN')),
                  DropdownMenuItem(value: 'INFO', child: Text('INFO')),
                ],
                onChanged: (v) {
                  setState(() => _levelFilter = v);
                  _load();
                },
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
                tooltip: '오래된 에러 삭제',
                onPressed: _clearOldErrors,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _load,
              ),
            ],
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!,
                              style: const TextStyle(color: AppColors.error)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _load, child: const Text('다시 시도')),
                        ],
                      ),
                    )
                  : _errors.isEmpty
                      ? const Center(
                          child: Text('에러 로그가 없습니다.',
                              style: TextStyle(color: AppColors.textSecond)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _errors.length,
                            itemBuilder: (_, i) {
                              final log = _errors[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () => _showErrorDetail(log),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _levelColor(log.level)
                                                    .withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                log.level,
                                                style: TextStyle(
                                                  color: _levelColor(log.level),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              log.source,
                                              style: const TextStyle(
                                                  color: AppColors.textSecond,
                                                  fontSize: 12),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${log.createdAt.month}/${log.createdAt.day} ${log.createdAt.hour}:${log.createdAt.minute.toString().padLeft(2,'0')}',
                                              style: const TextStyle(
                                                  color: AppColors.textSecond,
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          log.message,
                                          style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  void _showErrorDetail(ErrorLog log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _levelColor(log.level).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.level,
                      style: TextStyle(
                        color: _levelColor(log.level),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(log.source,
                      style: const TextStyle(color: AppColors.textSecond)),
                ],
              ),
              const SizedBox(height: 12),
              Text(log.message,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold)),
              if (log.stackTrace != null) ...[
                const SizedBox(height: 12),
                const Text('스택 트레이스',
                    style: TextStyle(color: AppColors.textSecond, fontSize: 12)),
                const SizedBox(height: 4),
                Expanded(
                  child: SingleChildScrollView(
                    controller: ctrl,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SelectableText(
                        log.stackTrace!,
                        style: const TextStyle(
                          color: AppColors.textSecond,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
