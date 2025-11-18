import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sprint_provider.dart'; // Sesuaikan path
import 'scrum_page.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Panggil fetchProjects saat halaman pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SprintProvider>(context, listen: false).fetchProjects();
    });
  }

  // Fungsi untuk memanggil provider saat tombol ditekan
  Future<void> _addProject() async {
    if (_formKey.currentState!.validate()) {
      // Ambil provider
      final provider = Provider.of<SprintProvider>(context, listen: false);

      // Pastikan durasi adalah angka yang valid dan positif
      final duration = int.tryParse(_durationController.text);
      if (duration == null || duration <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Durasi Sprint harus berupa angka positif."), backgroundColor: Colors.red),
        );
        return;
      }

      // Panggil fungsi addProject. Duration dikonversi kembali ke String untuk consistency
      // Durasi ini sekarang mewakili durasi sprint awal atau target
      await provider.addProject(_nameController.text.trim(), duration.toString());

      if (!mounted) return;

      // Penanganan pesan sukses atau error setelah proses
      if (provider.errorMessage == null) {
        // Berhasil
        _nameController.clear();
        _durationController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Proyek baru berhasil ditambahkan!"), backgroundColor: Colors.green),
        );
      } else {
        // Gagal (menampilkan error dari provider, misalnya kegagalan server)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menambahkan proyek: ${provider.errorMessage}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
      ),
      body: Column(
        children: [
          // Form untuk menambah proyek baru
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Project Name', border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Masukkan nama proyek';
                        }
                        return null;
                      }
                  ),
                  const SizedBox(height: 12),
                  // 🔥 Perubahan 1: Mengubah label input dari 'Duration (days)' menjadi 'Sprint '
                  TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(labelText: 'Sprint', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Masukkan durasi sprint';
                        }
                        // Validasi tambahan untuk memastikan input adalah angka
                        if (int.tryParse(value) == null) {
                          return 'Durasi harus berupa angka';
                        }
                        if (int.tryParse(value)! <= 0) {
                          return 'Durasi harus lebih dari 0 hari';
                        }
                        return null;
                      }
                  ),
                  const SizedBox(height: 16),
                  Consumer<SprintProvider>( // Bungkus tombol dengan Consumer
                    builder: (context, provider, child) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        // Nonaktifkan tombol saat loading
                        onPressed: provider.isLoading ? null : _addProject,
                        child: provider.isLoading
                            ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white
                            )
                        )
                            : const Text('Create Project'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Daftar proyek dari database
          Expanded(
            child: Consumer<SprintProvider>(
              builder: (context, provider, child) {
                // Tampilkan loading indicator saat data diambil
                if (provider.isLoading && provider.projects.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Tampilkan pesan error jika ada
                if (provider.errorMessage != null && provider.projects.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Error memuat proyek: ${provider.errorMessage}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                // Tampilkan pesan jika tidak ada proyek
                if (provider.projects.isEmpty) {
                  return const Center(child: Text('Belum ada proyek. Silakan buat yang baru.'));
                }

                // Tampilkan daftar proyek
                return RefreshIndicator(
                  onRefresh: () => provider.fetchProjects(),
                  child: ListView.builder(
                    itemCount: provider.projects.length,
                    itemBuilder: (context, index) {
                      final project = provider.projects[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          // 🔥 Perubahan 2: Mengubah subtitle dari 'Durasi' menjadi 'Sprint'
                          subtitle: Text('Sprint: ${project.duration} | Progres: ${project.progress}%'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ScrumPage(
                                  projectId: project.id,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}
