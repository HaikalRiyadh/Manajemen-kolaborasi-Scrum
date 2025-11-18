import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/models.dart';

class SprintProvider with ChangeNotifier {
  final String _baseUrl = kIsWeb ? 'http://localhost/project_ppl' : 'http://10.0.2.2/project_ppl';

  List<Project> _projects = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
  }

  Future<void> fetchProjects() async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/get_projects.php'));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          final List<dynamic> projectData = responseData['data'];
          _projects = projectData.map((json) => Project.fromJson(json)).toList();
        }
      }
    } catch (e) {
      _setError("Gagal memuat proyek: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addProject(String name, String duration) async {
    _setLoading(true);
    _setError(null);
    try {
      await http.post(Uri.parse('$_baseUrl/add_project.php'), body: {'name': name, 'duration': duration});
      await fetchProjects();
    } catch (e) {
      _setError("Gagal menambah proyek: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchProjectDetails(int projectId) async {
    _setLoading(true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/get_tasks.php?project_id=$projectId'));
      final responseData = json.decode(response.body);

      if (responseData['status'] == 'success') {
        final List<dynamic> taskData = responseData['data'] ?? [];
        final tasks = taskData.map((json) => ScrumTask.fromJson(json)).toList();

        final projectIndex = _projects.indexWhere((p) => p.id == projectId);
        if (projectIndex != -1) {
          final oldProject = _projects[projectIndex];
          final updatedProject = Project(
            id: oldProject.id,
            name: oldProject.name,
            duration: oldProject.duration,
            progress: oldProject.progress,
            tasks: tasks,
          );

          final newProjectsList = List<Project>.from(_projects);
          newProjectsList[projectIndex] = updatedProject;
          _projects = newProjectsList;
        }
      }
    } catch (e) {
      _setError("Gagal memuat detail proyek: ${e.toString()}");
    } finally {
      _setLoading(false);
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

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          await fetchProjectDetails(projectId);
        } else {
          throw Exception(responseData['message'] ?? 'Gagal menambah tugas di server');
        }
      } else {
        throw Exception('Gagal terhubung ke server (Error: ${response.statusCode})');
      }
    } catch (e) {
      // --- DIAGNOSTIC PRINT ---
      debugPrint("Error in addTask: ${e.toString()}");
      _setError("Gagal menambah tugas: ${e.toString()}");
    }
  }

  Future<void> updateTaskStatus(ScrumTask task, TaskStatus newStatus, int projectId) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;
    final taskIndex = _projects[projectIndex].tasks.indexWhere((t) => t.id == task.id);
    if (taskIndex == -1) return;

    final oldStatus = _projects[projectIndex].tasks[taskIndex].status;
    _projects[projectIndex].tasks[taskIndex].status = newStatus;
    notifyListeners();

    _setError(null);
    try {
      final response = await http.post(Uri.parse('$_baseUrl/update_task_status.php'), body: {
        'task_id': task.id,
        'new_status': newStatus.name,
      });
      final responseData = json.decode(response.body);
      if (responseData['status'] != 'success') throw Exception('Gagal update di server');
      await fetchProjectDetails(projectId);
    } catch (e) {
      _setError("Gagal update status: ${e.toString()}");
      _projects[projectIndex].tasks[taskIndex].status = oldStatus;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId, int projectId) async {
    _setError(null);
    try {
      final response = await http.post(Uri.parse('$_baseUrl/delete_task.php'), body: {
        'task_id': taskId,
      });
      final responseData = json.decode(response.body);
      if (responseData['status'] != 'success') {
        throw Exception('Gagal menghapus tugas di server');
      }
      await fetchProjectDetails(projectId);
    } catch (e) {
      _setError("Gagal menghapus tugas: ${e.toString()}");
    }
  }

  List<Project> _projectsWithTasks = [];
  List<Project> get projectsWithTasks => _projectsWithTasks;

  Future<void> fetchAllProjectData() async {
    _setLoading(true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/get_all_data.php'));
      final responseData = json.decode(response.body);

      if (responseData['status'] == 'success') {
        final List<dynamic> projectData = responseData['data'];
        _projectsWithTasks = projectData.map((json) => Project.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching all data: $e");
    } finally {
      _setLoading(false);
    }
  }
}
