import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';

// Pastikan semua path ini sudah benar sesuai struktur folder Anda
import 'services/sprint_provider.dart';
import 'theme.dart';
import 'screens/login_page.dart';

void main() {
  // Memastikan semua binding Flutter siap sebelum menjalankan aplikasi
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // DevicePreview untuk melihat tampilan di berbagai perangkat
    DevicePreview(
      enabled: true, // Ganti menjadi 'false' saat rilis aplikasi
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Menyediakan SprintProvider ke seluruh aplikasi
    return ChangeNotifierProvider(
      create: (context) => SprintProvider(),
      child: MaterialApp(
        // Konfigurasi untuk DevicePreview
        useInheritedMediaQuery: true,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,

        title: 'Project Manager Demo',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,

        // Halaman awal aplikasi adalah LoginPage
        home: const LoginPage(),
      ),
    );
  }
}