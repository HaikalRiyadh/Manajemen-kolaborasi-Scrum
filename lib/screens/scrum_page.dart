import 'package:flutter/material.dart';
import 'package:project/models/models.dart';
import 'package:project/services/sprint_provider.dart';
import 'package:provider/provider.dart';

class ScrumPage extends StatefulWidget {
  final int projectId;
  const ScrumPage({super.key, required this.projectId});

  @override
  State<ScrumPage> createState() => _ScrumPageState();
}

class _ScrumPageState extends State<ScrumPage> {
  final TextEditingController _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SprintProvider>(context, listen: false);
      provider.clearError();
      provider.fetchProjects();
    });
  }

  void _addItem() {
    final storyPointsController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    _taskController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambahkan Tugas Baru ke Perencanaan Sprint'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _taskController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Judul Tugas'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Judul tidak boleh kosong.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: storyPointsController,
                  decoration: const InputDecoration(labelText: 'Poin Cerita'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Silakan masukkan poin cerita.';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Silakan masukkan nomor yang valid.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Tambah'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final provider = Provider.of<SprintProvider>(context, listen: false);
                  final storyPoints = int.parse(storyPointsController.text);
                  provider.addTask(widget.projectId, _taskController.text.trim(), storyPoints);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(String taskId) {
    Provider.of<SprintProvider>(context, listen: false).deleteTask(taskId, widget.projectId);
  }

  Widget _buildTaskCard({required ScrumTask task}) {
    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    softWrap: true,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text('${task.storyPoints} Poin Cerita'),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    labelStyle: const TextStyle(fontSize: 12),
                    backgroundColor: Colors.blueGrey[50],
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (task.status == TaskStatus.done && task.completionDay != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Selesai di Sprint ${task.completionDay}',
                        style: TextStyle(fontSize: 11, color: Colors.green[800], fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: () => _deleteItem(task.id),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableTaskItem(ScrumTask task) {
    final taskCard = _buildTaskCard(task: task);
    return Draggable<ScrumTask>(
      data: task,
      feedback: Material(elevation: 4.0, child: SizedBox(width: 260, child: taskCard)),
      childWhenDragging: Opacity(opacity: 0.4, child: taskCard),
      child: taskCard,
    );
  }

  Widget _buildSprintSubColumn({ 
    required String title, 
    required List<ScrumTask> tasks, 
    required TaskStatus status, 
    required int sprintNumber
  }) {
    final provider = Provider.of<SprintProvider>(context, listen: false);

    return Expanded(
      child: DragTarget<ScrumTask>(
        onWillAccept: (task) {
          if (task == null) return false;

          bool isFromAnotherSprint = task.assignedSprint != sprintNumber;
          bool isFromSameSprint = task.assignedSprint == sprintNumber;
          bool isFromBacklog = task.status == TaskStatus.backlog;

          // Kolom 'To Do' adalah titik masuk utama.
          if (status == TaskStatus.toDo) {
            // Terima dari backlog ATAU dari sprint lain.
            return isFromBacklog || isFromAnotherSprint;
          }

          // 'In Progress' dan 'Done' hanya menerima tugas dari dalam sprint yang sama.
          return isFromSameSprint && task.status != status;
        },
        onAccept: (task) {
            TaskStatus newStatus = status;
            // Jika tugas berasal dari sprint lain, statusnya diatur ulang menjadi 'To Do'.
            if (task.assignedSprint != sprintNumber) {
                newStatus = TaskStatus.toDo;
            }
            provider.updateTaskStatus(task, newStatus, widget.projectId, sprintNumber);
        },
        builder: (context, candidateData, rejectedData) {
            final isDraggingOver = candidateData.isNotEmpty;
            return Container(
              decoration: BoxDecoration(
                color: isDraggingOver ? Colors.lightBlue.shade50 : Colors.grey[100],
                border: isDraggingOver ? Border.all(color: Colors.blue, width: 2) : null,
              ),
              padding: const EdgeInsets.all(4.0),
              child: Column(
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  Expanded(
                    child: tasks.isEmpty
                        ? Center(child: Text('Kosong', style: TextStyle(color: Colors.grey[400])))
                        : ListView.builder(
                            itemCount: tasks.length,
                            itemBuilder: (context, index) => _buildDraggableTaskItem(tasks[index]),
                          ),
                  ),
                ],
              ),
            );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Papan Scrum - Proyek #${widget.projectId}")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Consumer<SprintProvider>(
            builder: (context, sprintProvider, child) {
              final project = sprintProvider.projects.firstWhere(
                (p) => p.id == widget.projectId,
                orElse: () => Project(id: 0, name: 'Memuat...', sprint: 0, tasks: []),
              );

              if (sprintProvider.isLoading && project.id == 0) {
                return const Center(child: CircularProgressIndicator());
              }

              if (sprintProvider.errorMessage != null) {
                return Center(child: Text("Error: ${sprintProvider.errorMessage}"));
              }

              if (project.id == 0 && !sprintProvider.isLoading) {
                return const Center(child: Text("Proyek tidak ditemukan..."));
              }

              final List<String> mainColumns = ['Perencanaan Sprint', 'Sprint 1', 'Sprint 2', 'Sprint 3'];

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: mainColumns.map((title) {
                    final parts = title.split(' ');
                    final isSprintColumn = parts.first == 'Sprint' && parts.length > 1 && int.tryParse(parts.last) != null;

                    if (isSprintColumn) {
                      final sprintNumber = int.parse(parts.last);
                      final sprintTasks = project.tasks.where((t) => t.assignedSprint == sprintNumber).toList();
                      
                      return Container(
                          width: 800,
                          margin: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Card(
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                  ),
                                  const Divider(),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _buildSprintSubColumn(title: 'To Do', tasks: sprintTasks.where((t) => t.status == TaskStatus.toDo).toList(), status: TaskStatus.toDo, sprintNumber: sprintNumber),
                                        const VerticalDivider(width: 1, thickness: 1),
                                        _buildSprintSubColumn(title: 'In Progress', tasks: sprintTasks.where((t) => t.status == TaskStatus.inProgress).toList(), status: TaskStatus.inProgress, sprintNumber: sprintNumber),
                                        const VerticalDivider(width: 1, thickness: 1),
                                        _buildSprintSubColumn(title: 'Done', tasks: sprintTasks.where((t) => t.status == TaskStatus.done).toList(), status: TaskStatus.done, sprintNumber: sprintNumber),
                                      ],
                                    ),
                                  ) 
                                ],
                              ),
                            ),
                          ),
                        );
                    } else { // Kolom Perencanaan Sprint
                      final items = project.tasks.where((t) => t.status == TaskStatus.backlog).toList();
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Card(
                          color: Colors.white, 
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('Perencanaan Sprint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                const Divider(),
                                if (sprintProvider.isLoading) const LinearProgressIndicator(),
                                Expanded(
                                  child: items.isEmpty
                                  ? Center(child: Text('Kosong', style: TextStyle(color: Colors.grey[400])))
                                  : ListView.builder(
                                      itemCount: items.length,
                                      itemBuilder: (context, index) => _buildDraggableTaskItem(items[index]),
                                    ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        tooltip: 'Tambah Tugas',
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}
