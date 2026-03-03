
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/screens/login_page.dart';
import 'package:project/services/sprint_provider.dart';
import 'account_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<SprintProvider>(
          builder: (context, provider, child) {
            final roleDisplay = provider.isScrumMaster ? 'Scrum Master' : 'Developer';
            return Column(
              children: [
                const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.blue),
                    title: const Text('Account'), 
                    subtitle: const Text('Manage account details'), 
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AccountPage()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.security,
                      color: provider.isScrumMaster ? Colors.orange : Colors.blue,
                    ),
                    title: const Text('Roles & Permissions'),
                    subtitle: Text('Current role: $roleDisplay'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showRolesDialog(context, provider);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      provider.setUserData(0, '', '');
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showRolesDialog(BuildContext context, SprintProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Roles & Permissions'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRoleSection(
                  'Scrum Master',
                  Icons.admin_panel_settings,
                  Colors.orange,
                  provider.isScrumMaster,
                  [
                    'Membuat dan menghapus proyek',
                    'Mengelola sprint planning',
                    'Assign tugas ke anggota tim',
                    'Melihat semua daily scrum log',
                    'Melihat burndown chart & analytics',
                  ],
                ),
                const SizedBox(height: 16),
                _buildRoleSection(
                  'Developer',
                  Icons.code,
                  Colors.blue,
                  provider.isDeveloper && !provider.isScrumMaster,
                  [
                    'Update status tugas (drag & drop)',
                    'Submit daily scrum log',
                    'Melihat burndown chart',
                    'Menerima notifikasi tugas',
                    'Melihat detail proyek',
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoleSection(
    String title,
    IconData icon,
    Color color,
    bool isActive,
    List<String> permissions,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: color, width: 2) : Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
              const Spacer(),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Aktif', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...permissions.map((p) => Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 14, color: isActive ? color : Colors.grey),
                const SizedBox(width: 6),
                Expanded(child: Text(p, style: TextStyle(fontSize: 13, color: isActive ? Colors.black87 : Colors.grey))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
