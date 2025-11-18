import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/sprint_provider.dart';

class ScrumPage extends StatefulWidget {
  final int projectId;

  const ScrumPage({super.key, required this.projectId});

  @override
  State<ScrumPage> createState() => _ScrumPageState();
}

class _ScrumPageState extends State<ScrumPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SprintProvider>(context, listen: false).fetchProjectDetails(widget.projectId);
    });
  }

  void _showAddTaskDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final pointsController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Mencegah dialog ditutup saat proses loading
      builder: (context) {
        // Gunakan StatefulBuilder agar bisa update state (loading) di dalam dialog
        return StatefulBuilder(
          builder: (context, setState) {
            bool isAdding = false;

            return AlertDialog(
              title: const Text('Add New Task'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Task Title', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: pointsController,
                      decoration: const InputDecoration(labelText: 'Story Points', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Story Points are required';
                        if (int.tryParse(value) == null) return 'Must be a number';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  // Nonaktifkan tombol saat loading
                  onPressed: isAdding ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isAdding = true); // Mulai loading

                      final provider = Provider.of<SprintProvider>(context, listen: false);
                      // Tunggu (await) sampai proses addTask selesai
                      await provider.addTask(
                        widget.projectId,
                        titleController.text,
                        int.parse(pointsController.text),
                      );
                      
                      // Tutup dialog setelah semuanya selesai
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: isAdding 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Add Task'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog konfirmasi untuk menghapus task
  void _showDeleteConfirmationDialog(BuildContext context, ScrumTask task) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text('Are you sure you want to delete "${task.title}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                Provider.of<SprintProvider>(context, listen: false).deleteTask(task.id, widget.projectId);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<SprintProvider>(
          builder: (context, provider, child) {
            final project = provider.projects.firstWhere((p) => p.id == widget.projectId, orElse: () => Project(id: 0, name: "Loading...", duration: 0));
            return Text('Scrum Board: ${project.name}');
          },
        ),
      ),
      body: Consumer<SprintProvider>(
        builder: (context, provider, child) {
          // --- PENANGANAN ERROR DENGAN SNACKBAR ---
          if (provider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
              provider.clearError(); // Reset error setelah ditampilkan
            });
          }

          if (provider.isLoading && provider.projects.indexWhere((p) => p.id == widget.projectId) == -1) {
            return const Center(child: CircularProgressIndicator());
          }

          final project = provider.projects.firstWhere((p) => p.id == widget.projectId, orElse: () => Project(id: 0, name: "Unknown", duration: 0));
          if (project.id == 0) {
            return const Center(child: Text('Project not found.'));
          }

          final Map<TaskStatus, List<ScrumTask>> tasksByStatus = {
            TaskStatus.backlog: [],
            TaskStatus.toDo: [],
            TaskStatus.inProgress: [],
            TaskStatus.done: [],
          };

          for (var task in project.tasks) {
            tasksByStatus[task.status]!.add(task);
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: tasksByStatus.length,
            itemBuilder: (context, index) {
              TaskStatus status = tasksByStatus.keys.elementAt(index);
              List<ScrumTask> tasks = tasksByStatus[status]!;
              return _buildTaskColumn(context, status, tasks);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskColumn(BuildContext context, TaskStatus status, List<ScrumTask> tasks) {
    return DragTarget<ScrumTask>(
      onWillAccept: (task) => task?.status != status,
      onAccept: (task) {
        Provider.of<SprintProvider>(context, listen: false).updateTaskStatus(task, status, widget.projectId);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 280,
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? Colors.lightBlue[50] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: candidateData.isNotEmpty ? Colors.blueAccent : Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  status.name.toUpperCase().replaceAll('_', ' '),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Draggable<ScrumTask>(
                      data: task,
                      feedback: _buildTaskCard(task, isDragging: true),
                      childWhenDragging: Opacity(opacity: 0.5, child: _buildTaskCard(task)),
                      child: _buildTaskCard(task),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(ScrumTask task, {bool isDragging = false}) {
    return Card(
      elevation: isDragging ? 8 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _showDeleteConfirmationDialog(context, task),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text('${task.storyPoints} Story Points'),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              labelStyle: const TextStyle(fontSize: 12),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          ],
        ),
      ),
    );
  }
}
