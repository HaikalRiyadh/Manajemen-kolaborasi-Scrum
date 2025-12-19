import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

import '../services/sprint_provider.dart';
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
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama Pengguna dan password tidak boleh kosong")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String baseUrl = kIsWeb ? 'http://localhost/project_ppl' : 'http://10.0.2.2/project_ppl';
    final url = Uri.parse('$baseUrl/login.php');

    try {
      final response = await http.post(
        url,
        body: {
          'username': username,
          'password': password,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          // --- SIMPAN DATA USER LENGKAP ---
          final int userId = int.parse(data['data']['id'].toString());
          final String username = data['data']['username'];
          final String fullName = data['data']['full_name'];
          
          // Simpan ke SprintProvider agar bisa dipakai di halaman Account
          Provider.of<SprintProvider>(context, listen: false).setUserData(userId, username, fullName);

          // Navigasi ke halaman utama
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Login gagal")),
          );
        }
      }
      else if (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 404) {
        try {
          final Map<String, dynamic> data = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Autentikasi gagal.")),
          );
        } catch (_) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Username atau password salah.")),
          );
        }
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal terhubung ke server: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
