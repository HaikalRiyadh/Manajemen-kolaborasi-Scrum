
import 'package:flutter/material.dart';

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
            Card(child: ListTile(title: const Text('Account'), subtitle: const Text('Manage account details'), trailing: Icon(Icons.chevron_right))),
            const SizedBox(height: 8),
            Card(child: ListTile(title: const Text('Roles & Permissions'), subtitle: const Text('Manage team roles'), trailing: Icon(Icons.chevron_right))),
            const SizedBox(height: 8),
            Card(child: ListTile(title: const Text('Logout'), trailing: Icon(Icons.logout), onTap: () {})),
          ],
        ),
      ),
    );
  }
}
