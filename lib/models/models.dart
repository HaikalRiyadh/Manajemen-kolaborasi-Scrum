// Berkas: lib/models/models.dart
import 'dart:math';

enum TaskStatus { backlog, toDo, inProgress, done }

class ScrumTask {
  final String id;
  String title;
  TaskStatus status;
  final int storyPoints;
  int? completionDay;
  int? assignedSprint;

  ScrumTask({
    required this.id,
    required this.title,
    this.status = TaskStatus.backlog,
    required this.storyPoints,
    this.completionDay,
    this.assignedSprint,
  });

  factory ScrumTask.fromJson(Map<String, dynamic> json) {
    TaskStatus status = TaskStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == json['status'].toString().toLowerCase(),
      orElse: () => TaskStatus.backlog,
    );
    return ScrumTask(
      id: json['id'].toString(),
      title: json['title'],
      status: status,
      storyPoints: int.tryParse(json['story_points'].toString()) ?? 0,
      completionDay: json['completion_sprint'] != null
          ? int.tryParse(json['completion_sprint'].toString())
          : null,
      assignedSprint: json['assigned_sprint'] != null
          ? int.tryParse(json['assigned_sprint'].toString())
          : null,
    );
  }
}

class Project {
  final int id;
  final String name;
  final int sprint;
  List<ScrumTask> tasks;

  Project({
    required this.id,
    required this.name,
    required this.sprint,
    this.tasks = const [],
  });

  int get currentSprint {
    if (tasks.isEmpty) return 1;
    final highestSprint = tasks
        .map((task) => task.assignedSprint ?? 0)
        .fold(0, (prev, current) => max(prev, current));
    return highestSprint > 0 ? highestSprint : 1;
  }

  // Mengubah perhitungan progress agar konsisten dengan burndown chart
  int get progress {
    if (tasks.isEmpty) return 0;

    final totalStoryPoints = tasks.fold<int>(0, (sum, task) => sum + task.storyPoints);
    if (totalStoryPoints == 0) {
      return tasks.every((task) => task.status == TaskStatus.done) ? 100 : 0;
    }

    // Hitung story points dari tugas yang sudah berstatus 'done'
    final doneStoryPoints = tasks
        .where((task) => task.status == TaskStatus.done)
        .fold<int>(0, (sum, task) => sum + task.storyPoints);

    // Kembalikan persentase progress
    return ((doneStoryPoints / totalStoryPoints) * 100).round();
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    var taskList = json['tasks'] as List? ?? [];
    List<ScrumTask> tasksData = taskList.map((t) => ScrumTask.fromJson(t)).toList();
    return Project(
      id: int.parse(json['id'].toString()),
      name: json['name'],
      sprint: int.parse(json['sprint'].toString()),
      tasks: tasksData,
    );
  }
}

class BurndownData {
  final int sprint;
  final int estimated;
  final int actual;

  BurndownData({required this.sprint, required this.estimated, required this.actual});
}
