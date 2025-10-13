
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      'New comment on Task #12',
      'Milestone approved for Project X',
      'New user joined team'
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) => Card(child: ListTile(title: Text(items[i]))),
            ))
          ],
        ),
      ),
    );
  }
}
