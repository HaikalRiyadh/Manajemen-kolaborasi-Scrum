import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sprint_provider.dart'; // Sesuaikan path
import '../models/models.dart'; // Pastikan TaskStatus dan ScrumTask ada di sini

class ScrumPage extends StatefulWidget {
  final int projectId;
  const ScrumPage({super.key, required this.projectId});

  @override
  State<ScrumPage> createState() => _ScrumPageState();
}

class _ScrumPageState extends State<ScrumPage> {
  final TextEditingController _taskController = TextEditingController();

  // Mapping TaskStatus ke judul yang ditampilkan
  final Map<TaskStatus, String> _statusToTitle = {
    TaskStatus.backlog: 'Backlog',
    TaskStatus.toDo: 'To Do',
    TaskStatus.inProgress: 'In Progress',
    TaskStatus.done: 'Done',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SprintProvider>(context, listen: false);
      provider.clearError();
      provider.fetchTasks(widget.projectId);
    });
  }

  // --- FUNGSI UTAMA ---

  // Fungsi untuk menampilkan dialog tambah tugas
  void _addItem(TaskStatus status) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Task to "${_statusToTitle[status]}"'),
          content: TextField(
              controller: _taskController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Task title')),
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
                    _taskController.text.trim(),
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

  // Fungsi untuk memanggil provider pindah tugas (menggunakan tombol panah)
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

  // --- WIDGET KOMPONEN ---

  // Widget terpisah untuk tampilan Card tugas
  Widget _TaskCard({
    required ScrumTask task,
    required int currentIndex,
    required List<TaskStatus> statusList,
    required Function(String, TaskStatus, bool) moveTask,
    required Function(String) deleteItem,
  }) {
    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(task.title, softWrap: true, style: const TextStyle(fontSize: 14))),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tombol Pindah Mundur (ke kiri)
                if (currentIndex > 0)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.orange),
                    onPressed: () => moveTask(task.id, task.status, false),
                    visualDensity: VisualDensity.compact,
                  ),
                // Tombol Pindah Maju (ke kanan)
                if (currentIndex < statusList.length - 1)
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                    onPressed: () => moveTask(task.id, task.status, true),
                    visualDensity: VisualDensity.compact,
                  ),
                // Tombol Hapus
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  onPressed: () => deleteItem(task.id),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  // Widget untuk membangun kartu tugas dengan Draggable
  Widget _buildTaskItem(ScrumTask task) {
    final statusList = TaskStatus.values;
    final currentIndex = statusList.indexOf(task.status);
    final taskCard = _TaskCard(
        task: task,
        currentIndex: currentIndex,
        statusList: statusList,
        moveTask: _moveTask,
        deleteItem: _deleteItem
    );

    // Draggable: Membuat card ini bisa diseret.
    return Draggable<String>(
      data: task.id, // ID tugas yang dibawa saat di-drag
      feedback: Material(
        elevation: 4.0,
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.lightBlue.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            task.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: taskCard,
      ),
      child: taskCard,
    );
  }

  // --- WIDGET BUILDER UTAMA ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scrum Board - Project #${widget.projectId}")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Consumer<SprintProvider>(
            builder: (context, sprintProvider, child) {
              // 1. Loading State
              if (sprintProvider.isLoading && sprintProvider.tasks.isEmpty && sprintProvider.errorMessage == null) {
                return const Center(child: CircularProgressIndicator());
              }

              // 2. Error State
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

              // 3. Empty State (Papan Kosong)
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

              // 4. Scrum Board (Tampilan Utama)
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // Membuat kolom untuk setiap status: Backlog, To Do, In Progress, Done
                  children: TaskStatus.values.map((status) {
                    final items = sprintProvider.tasks.where((t) => t.status == status).toList();
                    final columnTitle = _statusToTitle[status]!;

                    // DragTarget: Tempat jatuhnya tugas yang diseret
                    return DragTarget<String>(
                      onWillAccept: (data) => data != null,
                      onAccept: (taskId) {
                        // Memperbarui status tugas saat Drag & Drop
                        Provider.of<SprintProvider>(context, listen: false).updateTaskStatus(
                          widget.projectId,
                          taskId,
                          status, // Status tujuan
                        );
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isDraggingOver = candidateData.isNotEmpty;

                        return Container(
                          width: 280,
                          margin: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Card(
                            // Efek visual saat drag di atas kolom
                            color: isDraggingOver ? Colors.indigo.shade50 : Colors.white,
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(columnTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      // Tombol Add per kolom
                                      IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.indigo), onPressed: () => _addItem(status), visualDensity: VisualDensity.compact),
                                    ],
                                  ),
                                  const Divider(),
                                  // Loading indicator saat ada pembaruan
                                  if (sprintProvider.isLoading && sprintProvider.isUpdatingTask)
                                    const LinearProgressIndicator(),

                                  // Daftar Tugas di kolom
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
                      },
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