import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sprint_provider.dart';
import '../models/models.dart';
import 'scrum_page.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sprintController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SprintProvider>(context, listen: false).fetchProjects();
    });
  }

  Future<void> _addProject() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<SprintProvider>(context, listen: false);
      final sprint = int.tryParse(_sprintController.text);
      if (sprint == null || sprint <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sprint harus berupa angka positif."), backgroundColor: Colors.red),
        );
        return;
      }

      await provider.addProject(_nameController.text.trim(), sprint.toString());

      if (!mounted) return;

      if (provider.errorMessage == null) {
        _nameController.clear();
        _sprintController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Proyek baru berhasil ditambahkan!"), backgroundColor: Colors.green),
        );
      } else {
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
                      }),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _sprintController,
                      decoration: const InputDecoration(labelText: 'Sprint', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Masukkan jumlah sprint';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Sprint harus berupa angka';
                        }
                        if (int.tryParse(value)! <= 0) {
                          return 'Sprint harus lebih dari 0';
                        }
                        return null;
                      }),
                  const SizedBox(height: 16),
                  Consumer<SprintProvider>(
                    builder: (context, provider, child) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: provider.isLoading ? null : _addProject,
                        child: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                            : const Text('Create Project'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Consumer<SprintProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.projects.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null && provider.projects.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('Error memuat proyek: ${provider.errorMessage}',
                          textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }

                final activeProjects = provider.projects.where((p) => p.progress < 100).toList();

                if (activeProjects.isEmpty) {
                  return const Center(child: Text('Tidak ada proyek aktif.'));
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchProjects(),
                  child: ListView.builder(
                    itemCount: activeProjects.length,
                    itemBuilder: (context, index) {
                      final project = activeProjects[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Sprint: ${project.sprint} | Progres: ${project.progress}%'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          // ================== PERBAIKAN FINAL ==================
                          // Menghapus 'await' dan 'async' yang menyebabkan crash saat navigasi
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ScrumPage(projectId: project.id),
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
    _sprintController.dispose();
    super.dispose();
  }
}
