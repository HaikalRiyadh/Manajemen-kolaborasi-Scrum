import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/models.dart';

class SprintProvider with ChangeNotifier {
  final String _baseUrl = kIsWeb ? 'http://localhost/project_ppl' : 'http://10.0.2.2/project_ppl';

  List<Project> _projects = [];
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Data User
  int? _userId;
  String? _username;
  String? _fullName;

  List<Project> get projects => _projects;
  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Getter untuk data user
  int? get userId => _userId;
  String? get username => _username;
  String? get fullName => _fullName;

  // Fungsi untuk menyimpan data user saat login
  void setUserData(int id, String username, String fullName) {
    _userId = id;
    _username = username;
    _fullName = fullName;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchProjects() async {
    if (_userId == null) return;
    
    _setLoading(true);
    _setError(null);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/get_all_data.php?user_id=$_userId'));
      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['status'] == 'success') {
            final List<dynamic> projectData = responseData['data'];
            _projects = projectData.map((json) => Project.fromJson(json)).toList();
          } else {
             _projects = [];
          }
        } on FormatException {
          debugPrint('Respon Server (Error): ${response.body}');
          throw Exception('Respons dari server tidak valid.');
        }
      } else {
        throw Exception('Server mengembalikan error: ${response.statusCode}');
      }
    } catch (e) {
      _setError("Gagal memuat proyek: ${e.toString().replaceAll('Exception: ', '')}");
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> fetchNotifications() async {
    if (_userId == null) return;

    try {
      final response = await http.get(Uri.parse('$_baseUrl/get_notifications.php?user_id=$_userId'));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          final List<dynamic> notifData = responseData['data'];
          _notifications = notifData.map((json) => NotificationItem.fromJson(json)).toList();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Gagal memuat notifikasi: $e");
    }
  }

  Future<void> addProject(String name, String sprint) async {
    if (_userId == null) {
      _setError("User belum login");
      return;
    }

    _setLoading(true);
    _setError(null);
    try {
      final response = await http.post(
          Uri.parse('$_baseUrl/add_project.php'), 
          body: {
            'name': name, 
            'sprint': sprint,
            'user_id': _userId.toString()
          }
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          await fetchProjects();
        } else {
          throw Exception(responseData['message'] ?? 'Gagal menambah proyek.');
        }
      } else {
          throw Exception('Gagal menambah proyek (Error: ${response.statusCode}).');
      }
    } catch (e) {
      _setError("Gagal menambah proyek: ${e.toString().replaceAll('Exception: ', '')}");
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> updateTaskStatus(ScrumTask task, TaskStatus newStatus, int projectId, int sprintNumber) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;

    final taskIndex = _projects[projectIndex].tasks.indexWhere((t) => t.id == task.id);
    if (taskIndex == -1) return;

    final targetTask = _projects[projectIndex].tasks[taskIndex];
    final oldStatus = targetTask.status;
    final oldAssignedSprint = targetTask.assignedSprint;
    final oldCompletionDay = targetTask.completionDay;

    targetTask.status = newStatus;
    targetTask.assignedSprint = sprintNumber;

    if (newStatus == TaskStatus.done) {
      targetTask.completionDay = sprintNumber;
    } else {
      targetTask.completionDay = null;
    }

    notifyListeners();
    _setError(null);

    try {
      final body = <String, String>{
        'task_id': task.id,
        'new_status': newStatus.name,
        'assigned_sprint': sprintNumber.toString(),
      };

      if (targetTask.completionDay != null) {
        body['completion_sprint'] = targetTask.completionDay.toString();
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/update_task_status.php'),
        body: body,
      );

      final responseData = json.decode(response.body);
      if (responseData['status'] != 'success') {
        throw Exception(responseData['message'] ?? 'Gagal update di server');
      }
    } catch (e) {
      _setError("Gagal update status: ${e.toString().replaceAll('Exception: ', '')}");
      targetTask.status = oldStatus;
      targetTask.assignedSprint = oldAssignedSprint;
      targetTask.completionDay = oldCompletionDay;
      notifyListeners();
    }
  }

  List<BurndownData> generateBurndownData(Project project) {
    if (project.tasks.isEmpty || project.sprint <= 0) {
      return [];
    }

    final totalStoryPoints = project.tasks.fold<int>(0, (sum, task) => sum + task.storyPoints);
    if (totalStoryPoints == 0) return [];

    final idealPointsPerSprint = totalStoryPoints / project.sprint;

    List<BurndownData> burndownData = [];
    
    for (int sprint = 0; sprint <= project.sprint; sprint++) {
      final estimated = totalStoryPoints - (sprint * idealPointsPerSprint);
      
      int storyPointsDone = 0;
      for (final task in project.tasks) {
        if (task.completionDay != null && task.completionDay! <= sprint) {
          storyPointsDone += task.storyPoints;
        }
      }

      final actual = totalStoryPoints - storyPointsDone;

      burndownData.add(BurndownData(
        sprint: sprint,
        estimated: estimated.round().clamp(0, totalStoryPoints),
        actual: actual.clamp(0, totalStoryPoints),
      ));
    }
    return burndownData;
  }

  Future<void> deleteTask(String taskId, int projectId) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;

    final taskIndex = _projects[projectIndex].tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final taskToRemove = _projects[projectIndex].tasks.removeAt(taskIndex);
    notifyListeners();

    try {
      final response = await http.post(Uri.parse('$_baseUrl/delete_task.php'), body: {
        'task_id': taskId,
      });
      final responseData = json.decode(response.body);
      if (responseData['status'] != 'success') {
        throw Exception('Gagal menghapus tugas di server');
      }
    } catch (e) {
      _setError("Gagal menghapus tugas: ${e.toString().replaceAll('Exception: ', '')}");
      _projects[projectIndex].tasks.insert(taskIndex, taskToRemove);
      notifyListeners();
    }
  }

  Future<void> addTask(int projectId, String title, int storyPoints) async {
    _setError(null);
    try {
      final response = await http.post(Uri.parse('$_baseUrl/add_task.php'), body: {
        'project_id': projectId.toString(),
        'title': title,
        'story_points': storyPoints.toString(),
        'status': TaskStatus.backlog.name,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          await fetchProjects();
          fetchNotifications(); // Update notifikasi setelah menambah task
        } else {
          throw Exception(responseData['message'] ?? 'Gagal menambah tugas di server');
        }
      } else {
        throw Exception('Gagal terhubung ke server (Error: ${response.statusCode})');
      }
    } catch (e) {
      _setError("Gagal menambah tugas: ${e.toString().replaceAll('Exception: ', '')}");
    } 
  }
}
