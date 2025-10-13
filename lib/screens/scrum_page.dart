import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sprint_provider.dart'; // Sesuaikan path jika berbeda
import '../models/models.dart'; // Pastikan Anda sudah mengimpor ini

class ScrumPage extends StatefulWidget {
  final int projectId;
  const ScrumPage({super.key, required this.projectId});

  @override
  State<ScrumPage> createState() => _ScrumPageState();
}

class _ScrumPageState extends State<ScrumPage> {
  final TextEditingController _taskController = TextEditingController();

  final Map<TaskStatus, String> _statusToTitle = {
    TaskStatus.backlog: 'Backlog',
    TaskStatus.toDo: 'To Do',
    TaskStatus.inProgress: 'In Progress',
    TaskStatus.done: 'Done',
  };

  @override
  void initState() {
    super.initState();
    // Setelah frame pertama selesai, bersihkan error lama dan muat data baru
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SprintProvider>(context, listen: false);
      provider.clearError();
      provider.fetchTasks(widget.projectId);
    });
  }

  // Fungsi untuk menampilkan dialog tambah tugas
  void _addItem(TaskStatus status) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Task to "${_statusToTitle[status]}"'),
          content: TextField(controller: _taskController, autofocus: true, decoration: const InputDecoration(hintText: 'Task title')),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                _taskController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (_taskController.text.isNotEmpty) {
                  Provider.of<SprintProvider>(context, listen: false).addTask(
                    widget.projectId,
                    _taskController.text,
                    status,
                  );
                  _taskController.clear();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk memanggil provider hapus tugas
  void _deleteItem(String taskId) {
    Provider.of<SprintProvider>(context, listen: false).deleteTask(widget.projectId, taskId);
  }

  // Fungsi untuk memanggil provider pindah tugas
  void _moveTask(String taskId, TaskStatus currentStatus, bool forward) {
    final statusList = TaskStatus.values;
    final currentIndex = statusList.indexOf(currentStatus);
    final provider = Provider.of<SprintProvider>(context, listen: false);

    if (forward && currentIndex < statusList.length - 1) {
      provider.updateTaskStatus(widget.projectId, taskId, statusList[currentIndex + 1]);
    } else if (!forward && currentIndex > 0) {
      provider.updateTaskStatus(widget.projectId, taskId, statusList[currentIndex - 1]);
    }
  }

  // Widget untuk membangun setiap kartu tugas
  Widget _buildTaskItem(ScrumTask task) {
    final statusList = TaskStatus.values;
    final currentIndex = statusList.indexOf(task.status);

    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(task.title, softWrap: true, style: const TextStyle(fontSize: 14))),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentIndex > 0)
                  IconButton(icon: const Icon(Icons.arrow_back, size: 20, color: Colors.orange), onPressed: () => _moveTask(task.id, task.status, false)),
                if (currentIndex < statusList.length - 1)
                  IconButton(icon: const Icon(Icons.arrow_forward, size: 20, color: Colors.blue), onPressed: () => _moveTask(task.id, task.status, true)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () => _deleteItem(task.id)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scrum Board - Project #${widget.projectId}")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Consumer<SprintProvider>(
            builder: (context, sprintProvider, child) {
              // 1. Tampilkan loading indicator
              if (sprintProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // 2. Tampilkan pesan error jika ada
              if (sprintProvider.errorMessage != null) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.red.shade50,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 40),
                        const SizedBox(height: 16),
                        const Text("Terjadi Kesalahan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text(
                          sprintProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 3. Tampilkan pesan jika papan tugas kosong
              if (sprintProvider.tasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Papan Tugas Kosong', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Tambahkan tugas baru untuk memulai', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Tugas'),
                        onPressed: () => _addItem(TaskStatus.backlog),
                      )
                    ],
                  ),
                );
              }

              // 4. Tampilkan papan scrum jika ada data
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: TaskStatus.values.map((status) {
                    final items = sprintProvider.tasks.where((t) => t.status == status).toList();
                    final columnTitle = _statusToTitle[status]!;
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Card(
                        color: Colors.grey[100], elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(columnTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _addItem(status)),
                                ],
                              ),
                              const Divider(),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    return _buildTaskItem(items[index]);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}