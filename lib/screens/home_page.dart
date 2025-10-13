import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'projects_page.dart';
import 'scrum_page.dart';
import 'notifications_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    ProjectsPage(),
    NotificationsPage(),
    SettingsPage(),
  ];

  final List<BottomNavigationBarItem> _items = const [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.folder_open), label: 'Projects'),
    BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifs'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: _items,
        selectedItemColor: Colors.blue, // warna icon/text saat aktif
        unselectedItemColor: Colors.grey, // warna icon/text saat nonaktif
        showUnselectedLabels: true, // tampilkan label walau nonaktif
      ),
    );
  }
}
