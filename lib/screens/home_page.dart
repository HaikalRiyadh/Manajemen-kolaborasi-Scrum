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
    BottomNavigationBarItem(icon: Icon(Icons.folder_open), label: 'Proyek'),
    BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifikasi'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
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
        selectedItemColor: Colors.blue, // warna ikon/teks saat aktif
        unselectedItemColor: Colors.grey, // warna ikon/teks saat tidak aktif
        showUnselectedLabels: true, // tampilkan label meskipun tidak aktif
      ),
    );
  }
}
