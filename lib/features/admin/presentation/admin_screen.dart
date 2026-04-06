import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../data/admin_repository.dart';
import 'admin_dashboard_tab.dart';
import 'admin_users_tab.dart';
import 'admin_errors_tab.dart';
import 'admin_system_tab.dart';
import 'admin_announcements_tab.dart';

final adminRepoProvider = Provider((ref) => AdminRepository(ref.watch(dioProvider)));

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  static const _tabs = [
    _AdminTab(Icons.dashboard_outlined, '대시보드'),
    _AdminTab(Icons.people_outline, '사용자'),
    _AdminTab(Icons.error_outline, '에러'),
    _AdminTab(Icons.computer_outlined, '시스템'),
    _AdminTab(Icons.campaign_outlined, '공지'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          AdminDashboardTab(),
          AdminUsersTab(),
          AdminErrorsTab(),
          AdminSystemTab(),
          AdminAnnouncementsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _AdminTab {
  final IconData icon;
  final String label;
  const _AdminTab(this.icon, this.label);
}
