import 'package:flutter/material.dart';
import 'projects_page.dart';

class ScrumWrapperPage extends StatelessWidget {
  const ScrumWrapperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scrum Board"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.folder_open_outlined,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Pilih Proyek Terlebih Dahulu',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Untuk melihat papan tugas, Anda harus memilih salah satu proyek dari halaman "Projects".',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('Buka Halaman Proyek'),
                onPressed: () {
                  // Tombol ini akan mengarahkan pengguna ke halaman yang benar
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProjectsPage()),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}