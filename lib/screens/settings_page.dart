
import 'package:flutter/material.dart';
import 'package:project/screens/login_page.dart';
import 'account_page.dart'; // Import halaman AccountPage

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Account'), 
                subtitle: const Text('Manage account details'), 
                trailing: const Icon(Icons.chevron_right),
                // Tambahkan aksi onTap di sini
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AccountPage()),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            const Card(child: ListTile(title: Text('Roles & Permissions'), subtitle: Text('Manage team roles'), trailing: Icon(Icons.chevron_right))),
            const SizedBox(height: 8),
            Card(child: ListTile(title: const Text('Logout'), trailing: const Icon(Icons.logout), onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            })),
          ],
        ),
      ),
    );
  }
}
