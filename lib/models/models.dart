// File: lib/models/models.dart

// Enum untuk status tugas
enum TaskStatus { backlog, toDo, inProgress, done }

// Model untuk sebuah tugas (task)
class ScrumTask {
  final String id;
  String title;
  TaskStatus status;
  final int storyPoints;
  int? completionDay; // Menyimpan informasi sprint ke berapa tugas ini selesai

  ScrumTask({
    required this.id,
    required this.title,
    this.status = TaskStatus.backlog,
    required this.storyPoints,
    this.completionDay,
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
      // Backend akan mengirim 'completion_sprint'
      completionDay: json['completion_sprint'] != null
          ? int.tryParse(json['completion_sprint'].toString())
          : null,
    );
  }
}

// Model untuk setiap proyek
class Project {
  final int id;
  final String name;
  final int sprint; // Total durasi sprint
  int currentSprint;  // Sprint yang sedang berjalan
  List<ScrumTask> tasks;

  Project({
    required this.id,
    required this.name,
    required this.sprint,
    required this.currentSprint,
    this.tasks = const [],
  });

  // Getter untuk menghitung progres secara dinamis berdasarkan story points dan status
  int get progress {
    if (tasks.isEmpty) {
      return 0;
    }
    final totalStoryPoints = tasks.fold<int>(0, (sum, task) => sum + task.storyPoints);
    if (totalStoryPoints == 0) {
      return tasks.every((task) => task.status == TaskStatus.done) ? 100 : 0;
    }

    double weightedProgress = 0;
    for (var task in tasks) {
      double statusWeight;
      switch (task.status) {
        case TaskStatus.backlog:
          statusWeight = 0;      // 0%
          break;
        case TaskStatus.toDo:
          statusWeight = 0.25;   // 25%
          break;
        case TaskStatus.inProgress:
          statusWeight = 0.75;   // 75%
          break;
        case TaskStatus.done:
          statusWeight = 1.0;    // 100%
          break;
      }
      weightedProgress += task.storyPoints * statusWeight;
    }

    return ((weightedProgress / totalStoryPoints) * 100).round();
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    var taskList = json['tasks'] as List? ?? [];
    List<ScrumTask> tasksData = taskList.map((t) => ScrumTask.fromJson(t)).toList();
    return Project(
      id: int.parse(json['id'].toString()),
      name: json['name'],
      sprint: int.parse(json['sprint'].toString()),
      // Ambil 'current_sprint' dari JSON, default-nya 1 jika tidak ada
      currentSprint: int.tryParse(json['current_sprint']?.toString() ?? '1') ?? 1,
      tasks: tasksData,
    );
  }
}

// Model untuk data burndown chart
class BurndownData {
  final int sprint;
  final int estimated;
  final int actual;

  BurndownData({required this.sprint, required this.estimated, required this.actual});
}
