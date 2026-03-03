import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import '../services/sprint_provider.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  // Fungsi untuk handle logout
  void _logout(BuildContext context) {
    // Hapus data user dari provider dengan mengirim ID 0 dan string kosong
    Provider.of<SprintProvider>(context, listen: false).setUserData(0, '', '');
    
    // Navigasi ke halaman Login dan hapus semua halaman sebelumnya
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data user dari SprintProvider
    // Kita gunakan context.watch agar halaman terupdate jika data berubah (misal nanti ada fitur edit profil)
    final provider = context.watch<SprintProvider>();
    final username = provider.username ?? "Tidak diketahui";
    final fullName = provider.fullName ?? "Tidak diketahui";
    final role = provider.role;
    final roleDisplay = role == 'scrum_master' ? 'Scrum Master' : 'Developer';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: role == 'scrum_master' ? Colors.orange : Colors.blue,
                  child: Icon(
                    role == 'scrum_master' ? Icons.admin_panel_settings : Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: role == 'scrum_master' ? Colors.orange.shade100 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleDisplay,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: role == 'scrum_master' ? Colors.orange.shade800 : Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Nama Pengguna'),
              subtitle: Text(username), // Data asli
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Nama Lengkap'),
              subtitle: Text(fullName), // Data asli
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Role'),
              subtitle: Text(roleDisplay),
              trailing: Icon(
                role == 'scrum_master' ? Icons.star : Icons.code,
                color: role == 'scrum_master' ? Colors.orange : Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (provider.isScrumMaster)
            Card(
              color: Colors.orange.shade50,
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hak Akses Scrum Master:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('• Membuat proyek baru'),
                    Text('• Mengelola tim & roles'),
                    Text('• Melihat semua daily scrum log'),
                    Text('• Mengatur sprint planning'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => _logout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
