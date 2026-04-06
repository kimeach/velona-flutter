import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/admin_models.dart';
import 'admin_screen.dart';

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  List<AdminUser> _users = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load([String? query]) async {
    setState(() { _loading = true; _error = null; });
    try {
      final users = await ref.read(adminRepoProvider).getUsers(query: query);
      setState(() { _users = users; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showUserDetail(AdminUser user) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (_) => _UserDetailSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 검색
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '이메일 또는 닉네임 검색',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecond),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textSecond),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                        _load();
                      },
                    )
                  : null,
            ),
            onChanged: (v) {
              setState(() => _query = v);
              if (v.length >= 2 || v.isEmpty) _load(v.isEmpty ? null : v);
            },
          ),
        ),

        // 목록
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
                          ElevatedButton(
                            onPressed: () => _load(),
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    )
                  : _users.isEmpty
                      ? const Center(
                          child: Text('사용자가 없습니다.',
                              style: TextStyle(color: AppColors.textSecond)),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _load(_query.isEmpty ? null : _query),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _users.length,
                            itemBuilder: (_, i) {
                              final u = _users[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.accent.withOpacity(0.2),
                                    child: Text(
                                      u.displayName.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(color: AppColors.accent),
                                    ),
                                  ),
                                  title: Text(u.displayName,
                                      style: const TextStyle(color: AppColors.textPrimary)),
                                  subtitle: Text(
                                    '${u.email} · 프로젝트 ${u.projectCount}개',
                                    style: const TextStyle(
                                        color: AppColors.textSecond, fontSize: 12),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: u.plan == 'premium'
                                          ? AppColors.warning.withOpacity(0.2)
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: u.plan == 'premium'
                                            ? AppColors.warning
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      u.plan.toUpperCase(),
                                      style: TextStyle(
                                        color: u.plan == 'premium'
                                            ? AppColors.warning
                                            : AppColors.textSecond,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  onTap: () => _showUserDetail(u),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

class _UserDetailSheet extends ConsumerWidget {
  final AdminUser user;
  const _UserDetailSheet({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = FutureProvider<Map<String, dynamic>>((ref) {
      return ref.read(adminRepoProvider).getUserDetail(user.memberId);
    });
    final asyncVal = ref.watch(detailAsync);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accent.withOpacity(0.2),
                  child: Text(
                    user.displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: AppColors.accent, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text(user.email,
                          style: const TextStyle(
                              color: AppColors.textSecond, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow('플랜', user.plan.toUpperCase()),
            _InfoRow('프로젝트', '${user.projectCount}개'),
            _InfoRow('가입일',
                '${user.createdAt.year}.${user.createdAt.month}.${user.createdAt.day}'),
            const SizedBox(height: 16),
            const Text('최근 프로젝트',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: asyncVal.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(e.toString(),
                    style: const TextStyle(color: AppColors.error)),
                data: (detail) {
                  final projects =
                      detail['projects'] as List<dynamic>? ?? [];
                  if (projects.isEmpty) {
                    return const Text('프로젝트 없음',
                        style: TextStyle(color: AppColors.textSecond));
                  }
                  return ListView.builder(
                    controller: ctrl,
                    itemCount: projects.length,
                    itemBuilder: (_, i) {
                      final p = projects[i] as Map<String, dynamic>;
                      return ListTile(
                        dense: true,
                        title: Text(p['title'] as String? ?? '-',
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 13)),
                        trailing: Text(p['status'] as String? ?? '-',
                            style: const TextStyle(
                                color: AppColors.textSecond, fontSize: 11)),
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecond, fontSize: 13)),
          ),
          Text(value,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }
}
