import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/custom_input.dart';
import '../screens/login_page.dart';
import 'home_page.dart'; // Tambahkan jika Anda ingin navigasi ke home setelah login

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // nameController akan digunakan untuk full_name (nama lengkap)
  final TextEditingController nameController = TextEditingController();
  // emailController akan digunakan untuk username, sesuai dengan kebutuhan skrip
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> register() async {
    // Ambil nilai dari controller
    final username = usernameController.text.trim();
    final password = passwordController.text; // TIDAK di trim
    final full_name = nameController.text.trim();

    // Validasi di sisi client
    if (full_name.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua field harus diisi")),
      );
      return;
    }

    if (password != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password dan konfirmasi password tidak sama")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // === PERBAIKAN URL UNTUK EMULATOR ===
    // Menggunakan IP 10.0.2.2 untuk terhubung ke Laragon (localhost)
    final url = Uri.parse('http://localhost/project_ppl/register.php');

    try {
      final response = await http.post(
        url,
        body: {
          // === PERBAIKAN MAPPING DATA (SESUAIKAN DENGAN register.php) ===
          'username': username,          // Mengirim username
          'password': password,          // Mengirim password
          'full_name': full_name,        // Mengirim full_name (dari nameController)
        },
      );

      if (!mounted) return;

      // Penanganan kode status
      if (response.statusCode == 200 || response.statusCode == 400 || response.statusCode == 409) {
        final responseData = jsonDecode(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );

        if (responseData['status'] == 'success') {
          // Kembali ke halaman login setelah registrasi berhasil
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}. Cek file db_connect.php.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        // Memberikan pesan error yang lebih spesifik jika gagal fetch
        SnackBar(content: Text("Gagal terhubung ke server (Network Error): ${e.toString()}. Cek Firewall & Cleartext Traffic.")),
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
      appBar: AppBar(
        // Tombol kembali otomatis
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Register"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mengubah peran controller
              CustomInput(controller: nameController, hint: "Nama Lengkap", icon: Icons.person),
              const SizedBox(height: 20),
              CustomInput(controller: usernameController, hint: "Nama Pengguna (Username)", icon: Icons.email),
              const SizedBox(height: 20),
              CustomInput(controller: passwordController, hint: "Password", icon: Icons.lock, obscure: true),
              const SizedBox(height: 20),
              CustomInput(controller: confirmPasswordController, hint: "Konfirmasi Password", icon: Icons.lock, obscure: true),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text("Register"),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Sudah punya akun?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text("Login"),
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