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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
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
