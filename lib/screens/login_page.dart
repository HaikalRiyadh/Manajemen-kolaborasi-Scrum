import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../screens/register_page.dart';
import 'home_page.dart';
import '../widgets/custom_input.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> login() async {
    // === PERBAIKAN START ===
    // Username di trim karena umumya tidak boleh mengandung spasi di awal/akhir
    final username = usernameController.text.trim();

    // Password TIDAK di trim, karena spasi adalah bagian dari password
    // Jika di trim, verifikasi password_verify() di PHP akan gagal
    final password = passwordController.text;
    // === PERBAIKAN END ===


    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama Pengguna dan password tidak boleh kosong")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Menggunakan IP Android Emulator untuk koneksi ke Laragon
    final url = Uri.parse('http://localhost/project_ppl/login.php');

    try {
      final response = await http.post(
        url,
        body: {
          'username': username,
          'password': password,
        },
      );

      if (!mounted) return;

      // Cek status code
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          // Navigasi ke halaman utama
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          // Tampilkan pesan error dari PHP
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Login gagal")),
          );
        }
      }
      // Tambahkan penanganan untuk kode error 400 & 401 (dari PHP)
      else if (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 404) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Autentikasi gagal. Coba lagi.")),
        );
      }
      else {
        // Tampilkan error server lainnya (misalnya 500)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Pesan error jika tidak bisa terhubung sama sekali (Network Error)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal terhubung ke server (Cek koneksi & Laragon): $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Login",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              CustomInput(
                controller: usernameController,
                hint: "Nama Pengguna",
                icon: Icons.person,
              ),
              const SizedBox(height: 20),
              CustomInput(
                controller: passwordController,
                hint: "Password",
                icon: Icons.lock,
                obscure: true,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text("Login"),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Belum punya akun?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterPage()),
                      );
                    },
                    child: const Text("Register"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}