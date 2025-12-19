import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Diperlukan untuk kIsWeb
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/custom_input.dart';
import '../screens/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> register() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;
    final full_name = nameController.text.trim();

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

    final String baseUrl = kIsWeb ? 'http://localhost/project_ppl' : 'http://10.0.2.2/project_ppl';
    final url = Uri.parse('$baseUrl/register.php');

    try {
      final response = await http.post(
        url,
        body: {
          'username': username,
          'password': password,
          'full_name': full_name,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
           final responseData = jsonDecode(response.body);
           
           if (responseData['status'] == 'success') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Registrasi berhasil! Silakan login.")),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
           } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(responseData['message'] ?? "Registrasi gagal.")),
              );
           }
        } catch (e) {
           // TAMPILKAN PESAN ERROR DARI SERVER LANGSUNG KE PENGGUNA UNTUK DEBUGGING
           // Ambil 200 karakter pertama dari respons untuk ditampilkan
           String serverError = response.body.length > 200 
               ? response.body.substring(0, 200) + "..." 
               : response.body;
           
           if (serverError.isEmpty) serverError = "Respon kosong dari server.";

           showDialog(
             context: context,
             builder: (ctx) => AlertDialog(
               title: const Text("Format Respons Server Salah"),
               content: SingleChildScrollView(
                 child: Text("Server tidak mengembalikan JSON yang valid.\n\nIsi respons:\n$serverError"),
               ),
               actions: [
                 TextButton(
                   onPressed: () => Navigator.of(ctx).pop(),
                   child: const Text("Tutup"),
                 )
               ],
             ),
           );
        }
      } 
      else if (response.statusCode == 400 || response.statusCode == 409) {
        try {
          final responseData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? "Data tidak valid atau sudah ada.")),
          );
        } catch (_) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Error ${response.statusCode}: ${response.body}")),
           );
        }
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}.")),
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
      appBar: AppBar(
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
              CustomInput(
                controller: nameController, 
                hint: "Nama Lengkap", 
                icon: Icons.badge
              ),
              const SizedBox(height: 20),
              CustomInput(
                controller: usernameController, 
                hint: "Nama Pengguna (Username)", 
                icon: Icons.person
              ),
              const SizedBox(height: 20),
              CustomInput(
                controller: passwordController, 
                hint: "Password", 
                icon: Icons.lock, 
                obscure: true
              ),
              const SizedBox(height: 20),
              CustomInput(
                controller: confirmPasswordController, 
                hint: "Konfirmasi Password", 
                icon: Icons.lock_outline, 
                obscure: true
              ),
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
