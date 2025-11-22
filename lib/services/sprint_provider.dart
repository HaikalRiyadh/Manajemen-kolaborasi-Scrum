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
    notifyListeners();
  }

  // ... (fetchProjects, addProject, fetchProjectDetails - tidak ada perubahan signifikan)
  Future<void> fetchProjects() async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/get_all_data.php'));
      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['status'] == 'success') {
            final List<dynamic> projectData = responseData['data'];
            _projects = projectData.map((json) => Project.fromJson(json)).toList();
          } else {
            throw Exception(responseData['message'] ?? 'Gagal memuat data proyek');
          }
        } on FormatException {
          debugPrint('Server Response (Error): ${response.body}');
          throw Exception('Respons dari server tidak valid. Kemungkinan ada error di sisi server.');
        }
      } else {
        throw Exception('Server returned error: ${response.statusCode}');
      }
    } catch (e) {
      _setError("Gagal memuat proyek: ${e.toString().replaceAll('Exception: ', '')}");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addProject(String name, String sprint) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await http.post(Uri.parse('$_baseUrl/add_project.php'), body: {'name': name, 'sprint': sprint});
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['status'] == 'success') {
            await fetchProjects();
          } else {
            throw Exception(responseData['message'] ?? 'Gagal menambah proyek di server');
          }
        } on FormatException {
            debugPrint('Server Response (addProject Error): ${response.body}');
            throw Exception('Respons tidak valid dari server saat menambah proyek.');
        }
      } else {
          // PERBAIKAN: Tampilkan body respons saat terjadi error 500
          throw Exception('Gagal menambah proyek di server (Error: ${response.statusCode}). Response: ${response.body}');
      }
    } catch (e) {
      _setError("Gagal menambah proyek: ${e.toString().replaceAll('Exception: ', '')}");
    } finally {
      _setLoading(false);
    }
  }
  
    Future<void> updateTaskStatus(ScrumTask task, TaskStatus newStatus, int projectId, int currentSprint) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) return;

    final taskIndex = _projects[projectIndex].tasks.indexWhere((t) => t.id == task.id);
    if (taskIndex == -1) return;

    final oldStatus = _projects[projectIndex].tasks[taskIndex].status;
    _projects[projectIndex].tasks[taskIndex].status = newStatus;

    // Jika tugas ditandai 'Done', catat sprint penyelesaiannya
    int? completionSprint = (newStatus == TaskStatus.done) ? currentSprint : null;
    _projects[projectIndex].tasks[taskIndex].completionDay = completionSprint;
    notifyListeners();

    _setError(null);
    try {
        final response = await http.post(
            Uri.parse('$_baseUrl/update_task_status.php'),
            body: {
                'task_id': task.id,
                'new_status': newStatus.name,
                // Kirim sprint saat ini jika tugas sudah selesai
                if (completionSprint != null) 'completion_sprint': completionSprint.toString(),
            },
        );

        final responseData = json.decode(response.body);
        if (responseData['status'] != 'success') {
            throw Exception(responseData['message'] ?? 'Gagal update di server');
        }
        await fetchProjects(); // Sinkronkan data setelah berhasil
    } catch (e) {
        _setError("Gagal update status: ${e.toString().replaceAll('Exception: ', '')}");
        // Rollback jika gagal
        _projects[projectIndex].tasks[taskIndex].status = oldStatus;
        _projects[projectIndex].tasks[taskIndex].completionDay = (oldStatus == TaskStatus.done) ? currentSprint : null;
        notifyListeners();
    }
}


  Future<void> completeSprint(int projectId) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/complete_sprint.php'),
        body: {'project_id': projectId.toString()},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          await fetchProjects(); // Refresh data untuk mendapatkan sprint baru dan status tugas
        } else {
          throw Exception(responseData['message'] ?? 'Gagal menyelesaikan sprint');
        }
      } else {
        throw Exception('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _setError("Gagal menyelesaikan sprint: ${e.toString().replaceAll('Exception: ', '')}");
    } finally {
      _setLoading(false);
    }
  }

  // ... (sisa metode lainnya: deleteTask, fetchAllProjectData, generateBurndownData)
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
      await fetchProjects();
    } catch (e) {
      _setError("Gagal menghapus tugas: ${e.toString().replaceAll('Exception: ', '')}");
    }
  }

  List<Project> _projectsWithTasks = [];
  List<Project> get projectsWithTasks => _projectsWithTasks;

  Future<void> fetchAllProjectData() async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/get_all_data.php'));
      try {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          final List<dynamic> projectData = responseData['data'];
          _projectsWithTasks = projectData.map((json) => Project.fromJson(json)).toList();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to load data');
        }
      } on FormatException {
        debugPrint('Server Response (Error): ${response.body}');
        throw Exception('Respons dari server tidak valid. Periksa kembali sisi server.');
      }
    } catch (e) {
      _setError("Error fetching all data: ${e.toString().replaceAll('Exception: ', '')}");
    } finally {
      _setLoading(false);
    }
  }

  List<BurndownData> generateBurndownData(Project project) {
    if (project.tasks.isEmpty || project.sprint <= 0) {
      return [];
    }

    final totalStoryPoints = project.tasks.fold<int>(0, (sum, task) => sum + task.storyPoints);
    // Jika tidak ada story points, tidak ada yang bisa di-burndown
    if (totalStoryPoints == 0) return [];

    final idealPointsPerDay = totalStoryPoints / project.sprint;

    List<BurndownData> burndownData = [];
    for (int sprint = 0; sprint <= project.sprint; sprint++) {
      final estimated = totalStoryPoints - (sprint * idealPointsPerDay);

      // Hitung story points yang sudah selesai pada atau sebelum sprint ini
      final completedStoryPoints = project.tasks
          .where((task) => task.status == TaskStatus.done && task.completionDay != null && task.completionDay! <= sprint)
          .fold<int>(0, (sum, task) => sum + task.storyPoints);
      
      final actual = totalStoryPoints - completedStoryPoints;

      burndownData.add(BurndownData(
        sprint: sprint,
        estimated: estimated.round(),
        actual: actual,
      ));
    }
    return burndownData;
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
        } else {
          throw Exception(responseData['message'] ?? 'Gagal menambah tugas di server');
        }
      } else {
        throw Exception('Gagal terhubung ke server (Error: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint("Error in addTask: ${e.toString()}");
      _setError("Gagal menambah tugas: ${e.toString().replaceAll('Exception: ', '')}");
    } 
  }
}
