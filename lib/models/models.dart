// File: lib/models/models.dart

// Enum untuk status tugas
enum TaskStatus { backlog, toDo, inProgress, done }

// Model untuk sebuah tugas (task)
class ScrumTask {
  final String id;
  String title;
  TaskStatus status;
  final int storyPoints;
  int? completionDay;

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
      completionDay: json['completion_day'] != null
          ? int.tryParse(json['completion_day'].toString())
          : null,
    );
  }
}

// Model untuk setiap proyek
class Project {
  final int id;
  final String name;
  final int duration;
  int progress;
  List<ScrumTask> tasks;

  Project({
    required this.id,
    required this.name,
    required this.duration,
    this.progress = 0,
    this.tasks = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    var taskList = json['tasks'] as List? ?? [];
    List<ScrumTask> tasksData = taskList.map((t) => ScrumTask.fromJson(t)).toList();
    return Project(
      id: int.parse(json['id'].toString()),
      name: json['name'],
      duration: int.parse(json['duration'].toString()),
      progress: int.parse(json['progress'].toString()),
      tasks: tasksData,
    );
  }
}