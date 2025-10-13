import 'package:flutter/material.dart';
// Hapus: import 'theme.dart'; // Ini akan menyebabkan impor sirkular jika ada

class AppTheme {
  static const Color primary = Color(0xFF0B74FF);
  static const Color accent = Color(0xFF00C2A8); // Di ThemeData modern, 'secondary' dalam ColorScheme lebih umum
  // daripada 'accentColor' langsung di ThemeData.
  // Penggunaan Anda dengan .copyWith(secondary: accent) sudah benar.

  static final ThemeData light = ThemeData(
    primaryColor: primary, // Ini oke, tapi ColorScheme lebih diutamakan
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.blue, // Atau buat MaterialColor kustom dari 'primary' jika diinginkan
    ).copyWith(
      primary: primary, // Lebih eksplisit untuk mengatur warna primer di ColorScheme
      secondary: accent, // Ini adalah cara modern untuk warna aksen
      // Anda juga bisa mendefinisikan warna lain di ColorScheme seperti:
      // surface: Colors.white,
      // background: const Color(0xFFF5F7FB),
      // error: Colors.red,
      // onPrimary: Colors.white,
      // onSecondary: Colors.black,
      // onSurface: Colors.black,
      // onBackground: Colors.black,
      // onError: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F7FB),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.white, // Mungkin ingin menggunakan colorScheme.surface atau colorScheme.primary
      foregroundColor: Colors.black, // Mungkin ingin menggunakan colorScheme.onSurface atau colorScheme.onPrimary
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary, // Menggunakan warna primer tema untuk tombol
        foregroundColor: Colors.white, // Teks tombol putih di atas warna primer
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 48),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white, // Mungkin ingin menggunakan colorScheme.surface
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        // borderSide: BorderSide.none, // Jika tidak ingin ada border awal
      ),
      enabledBorder: OutlineInputBorder( // Border saat field aktif tapi tidak error
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder( // Border saat field mendapatkan fokus
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2.0), // Menggunakan warna primer tema
      ),
      // Anda juga bisa mendefinisikan errorBorder, focusedErrorBorder, dll.
    ),
    // Anda mungkin ingin menambahkan tema lain juga:
    // textTheme: TextTheme( ... ),
    // iconTheme: IconThemeData( ... ),
    // tabBarTheme: TabBarTheme ( ... ),
    // dialogTheme: DialogTheme ( ... ),
    useMaterial3: true, // Sebaiknya diaktifkan untuk fitur Material 3 terbaru
  );
}
