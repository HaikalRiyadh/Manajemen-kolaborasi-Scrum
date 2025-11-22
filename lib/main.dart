import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Hapus import device_preview
// import 'package:device_preview/device_preview.dart';

import 'services/sprint_provider.dart';
import 'theme.dart';
import 'screens/login_page.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized(); // Tidak selalu diperlukan untuk aplikasi sederhana

  // Langsung jalankan MyApp
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SprintProvider(),
      child: MaterialApp(
        // Hapus semua konfigurasi yang berhubungan dengan DevicePreview
        // useInheritedMediaQuery: true,
        // locale: DevicePreview.locale(context),
        // builder: DevicePreview.appBuilder,

        title: 'Project Manager Demo',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const LoginPage(),
      ),
    );
  }
}
