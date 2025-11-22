import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sprint_provider.dart';
import '../models/models.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SprintProvider>(context, listen: false);
      provider.clearError();
      // Memuat data proyek saat halaman dibuka
      provider.fetchProjects();
    });
  }

  void _addItem(TaskStatus status) {
    final storyPointsController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    _taskController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Task to "${_statusToTitle[status]}"'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _taskController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Task Title'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title cannot be empty.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: storyPointsController,
                  decoration: const InputDecoration(labelText: 'Story Points'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter story points.';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
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

  // [FIXED] Fungsi ini sekarang aman untuk dijalankan
  void _moveTask(ScrumTask task, bool forward) {
    final statusList = TaskStatus.values;
    final currentIndex = statusList.indexOf(task.status);
    final provider = Provider.of<SprintProvider>(context, listen: false);

    final projectIndex = provider.projects.indexWhere((p) => p.id == widget.projectId);
    if (projectIndex == -1) return; // Hentikan jika proyek tidak ditemukan
    final project = provider.projects[projectIndex];

    if (forward && currentIndex < statusList.length - 1) {
      provider.updateTaskStatus(task, statusList[currentIndex + 1], widget.projectId, project.currentSprint);
    } else if (!forward && currentIndex > 0) {
      provider.updateTaskStatus(task, statusList[currentIndex - 1], widget.projectId, project.currentSprint);
    }
  }

  Widget _TaskCard({
    required ScrumTask task,
    required int currentIndex,
    required List<TaskStatus> statusList,
    required Function(ScrumTask, bool) moveTask,
    required Function(String) deleteItem,
  }) {
    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
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
                    label: Text('${task.storyPoints} Story Points'),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    labelStyle: const TextStyle(fontSize: 12),
                    backgroundColor: Colors.blueGrey[50],
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentIndex > 0)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.orange),
                    onPressed: () => moveTask(task, false),
                    visualDensity: VisualDensity.compact,
                  ),
                if (currentIndex < statusList.length - 1)
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                    onPressed: () => moveTask(task, true),
                    visualDensity: VisualDensity.compact,
                  ),
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

  Widget _buildTaskItem(ScrumTask task) {
    final statusList = TaskStatus.values;
    final currentIndex = statusList.indexOf(task.status);
    final taskCard = _TaskCard(
        task: task,
        currentIndex: currentIndex,
        statusList: statusList,
        moveTask: _moveTask,
        deleteItem: _deleteItem);

    return Draggable<ScrumTask>(
      data: task,
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
      childWhenDragging: Opacity(opacity: 0.4, child: taskCard),
      child: taskCard,
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
              final project = sprintProvider.projects.firstWhere((p) => p.id == widget.projectId, orElse: () => Project(id: 0, name: 'Loading...', sprint: 0, currentSprint: 0, tasks: []));

              if (sprintProvider.isLoading && project.id == 0) {
                return const Center(child: CircularProgressIndicator());
              }

              if (sprintProvider.errorMessage != null) {
                return Center(child: Text("Error: ${sprintProvider.errorMessage}"));
              }

              if (project.id != 0 && project.tasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Papan Tugas Kosong', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              }
              
              if (project.id == 0 && !sprintProvider.isLoading){
                 return const Center(child: Text("Project not found or still loading..."));
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: TaskStatus.values.map((status) {
                    final items = project.tasks.where((t) => t.status == status).toList();
                    final columnTitle = _statusToTitle[status]!;

                    return DragTarget<ScrumTask>(
                      onWillAccept: (data) => data != null && data.status != status,
                      onAccept: (task) {
                        Provider.of<SprintProvider>(context, listen: false).updateTaskStatus(
                          task,
                          status,
                          widget.projectId,
                          project.currentSprint,
                        );
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isDraggingOver = candidateData.isNotEmpty;

                        return Container(
                          width: 280,
                          margin: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Card(
                            color: isDraggingOver ? Colors.indigo.shade50 : Colors.white,
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(columnTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                  const Divider(),
                                  if (sprintProvider.isLoading)
                                    const LinearProgressIndicator(),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addItem(TaskStatus.backlog),
        tooltip: 'Add Task',
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
