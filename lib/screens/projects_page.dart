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
      // Panggil fungsi addProject
      await provider.addProject(_nameController.text, _durationController.text);

      // Reset form setelah berhasil
      if (provider.errorMessage == null) {
        _nameController.clear();
        _durationController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Proyek baru berhasil ditambahkan!"), backgroundColor: Colors.green),
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
                    validator: (value) => value == null || value.isEmpty ? 'Masukkan nama proyek' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(labelText: 'Duration (days)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Masukkan durasi' : null,
                  ),
                  const SizedBox(height: 16),
                  Consumer<SprintProvider>( // Bungkus tombol dengan Consumer
                    builder: (context, provider, child) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        // Nonaktifkan tombol saat loading
                        onPressed: provider.isLoading ? null : _addProject,
                        child: provider.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : const Text('Create Project'),
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
                  return Center(child: Text('Error: ${provider.errorMessage}'));
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
                          subtitle: Text('Durasi: ${project.duration} hari | Progres: ${project.progress}%'),
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