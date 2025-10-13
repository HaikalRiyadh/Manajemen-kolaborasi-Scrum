import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import package http
import 'dart:convert'; // Import untuk jsonDecode

import '../screens/register_page.dart';
import 'home_page.dart';
import '../widgets/custom_input.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Ganti nama controller agar sesuai dengan database
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false; // State untuk loading indicator

  Future<void> login() async {
    // Validasi input di sisi client
    if (nameController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama Pengguna dan password tidak boleh kosong")),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Mulai loading
    });

    // URL ke API Anda. Ganti 'localhost' dengan IP address Anda jika menjalankan di HP fisik.
    // Gunakan 10.0.2.2 untuk emulator Android
    final url = Uri.parse('http://localhost/project_ppl/login.php');

    try {
      final response = await http.post(
        url,
        body: {
          'username': nameController.text,
          'password': passwordController.text,
        },
      );

      // Pastikan widget masih ada di tree sebelum memanipulasi context
      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          // Jika sukses, navigasi ke HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          // Jika gagal, tampilkan pesan error dari server
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'])),
          );
        }
      } else {
        // Error pada server
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal terhubung ke server.")),
        );
      }
    } catch (e) {
      // Error koneksi (misal tidak ada internet)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hentikan loading
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
              const Text("Login", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              // Sesuaikan controller dan hint text
              CustomInput(controller: nameController, hint: "Nama Pengguna", icon: Icons.person),
              const SizedBox(height: 20),
              CustomInput(controller: passwordController, hint: "Password", icon: Icons.lock, obscure: true),
              const SizedBox(height: 30),
              // Tampilkan loading indicator atau tombol
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
              )
            ],
          ),
        ),
      ),
    );
  }
}