import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/models.dart';

// --- PROVIDER ---
class SprintProvider with ChangeNotifier {
  final String _baseUrl = kIsWeb ? 'http://localhost/project_ppl' : 'http://10.0.2.2/project_ppl';

  List<Project> _projects = [];
  List<ScrumTask> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  // --- PROPERTI BARU UNTUK INDIKATOR LOADING KHUSUS (SOLUSI ERROR) ---
  bool _isUpdatingTask = false;

  // GETTERS
  List<Project> get projects => _projects;
  List<ScrumTask> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- GETTER BARU ---
  bool get isUpdatingTask => _isUpdatingTask;

  void clearError() {
    _errorMessage = null;
  }

  // --- FUNGSI UNTUK PROJECTS ---
  Future<void> fetchProjects() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final url = Uri.parse('$_baseUrl/get_projects.php');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        final List<dynamic> projectData = responseData['data'];
        _projects = projectData.map((json) => Project.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = "Gagal memuat proyek: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProject(String name, String duration) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final url = Uri.parse('$_baseUrl/add_project.php');
    try {
      await http.post(url, body: {'name': name, 'duration': duration});
      await fetchProjects();
    } catch (e) {
      _errorMessage = "Gagal menambah proyek: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FUNGSI UNTUK TASKS (UNTUK SCRUM PAGE) ---
  Future<void> fetchTasks(int projectId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final url = Uri.parse('$_baseUrl/get_tasks.php?project_id=$projectId');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        final List<dynamic> taskData = responseData['data'];
        _tasks = taskData.map((json) => ScrumTask.fromJson(json)).toList();
      } else {
        _tasks = [];
      }
    } catch (e) {
      _errorMessage = "Gagal memuat tugas: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(int projectId, String title, TaskStatus status) async {
    // Menggunakan isUpdatingTask karena operasi ini lebih cepat dari fetchTasks
    _isUpdatingTask = true;
    notifyListeners();
    final url = Uri.parse('$_baseUrl/add_task.php');
    try {
      await http.post(url, body: {
        'project_id': projectId.toString(), 'title': title, 'status': status.name, 'story_points': '3',
      });
      await fetchTasks(projectId);
    } catch (e) {
      _errorMessage = "Gagal menambah tugas: ${e.toString()}";
      notifyListeners();
    } finally {
      _isUpdatingTask = false;
      notifyListeners();
    }
  }

  Future<void> updateTaskStatus(int projectId, String taskId, TaskStatus newStatus) async {
    // --- IMPLEMENTASI LOGIKA isUpdatingTask DI SINI ---
    _isUpdatingTask = true;
    notifyListeners(); // Tampilkan indikator loading di kolom segera

    final url = Uri.parse('$_baseUrl/update_task_status.php');
    try {
      await http.post(url, body: {
        'task_id': taskId, 'new_status': newStatus.name, 'completion_day': newStatus == TaskStatus.done ? '4' : 'NULL',
      });
      // Panggil fetchTasks untuk memuat ulang data yang diperbarui
      await fetchTasks(projectId);
    } catch (e) {
      _errorMessage = "Gagal mengupdate status: ${e.toString()}";
      notifyListeners();
    } finally {
      // Sembunyikan indikator loading di kolom setelah operasi selesai
      _isUpdatingTask = false;
      notifyListeners();
    }
  }

  Future<void> deleteTask(int projectId, String taskId) async {
    // Menggunakan isUpdatingTask karena operasi ini juga memicu fetchTasks
    _isUpdatingTask = true;
    notifyListeners();
    final url = Uri.parse('$_baseUrl/delete_task.php');
    try {
      await http.post(url, body: {'task_id': taskId});
      await fetchTasks(projectId);
    } catch (e) {
      _errorMessage = "Gagal menghapus tugas: ${e.toString()}";
      notifyListeners();
    } finally {
      _isUpdatingTask = false;
      notifyListeners();
    }
  }

  // State baru untuk menyimpan semua data proyek beserta tugasnya
  List<Project> _projectsWithTasks = [];
  List<Project> get projectsWithTasks => _projectsWithTasks;

  // FUNGSI BARU: Mengambil semua data proyek dan tugasnya
  Future<void> fetchAllProjectData() async {
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse('$_baseUrl/get_all_data.php');
    try {
      final response = await http.get(url);
      final responseData = json.decode(response.body);

      if (responseData['status'] == 'success') {
        final List<dynamic> projectData = responseData['data'];
        _projectsWithTasks = projectData.map((json) => Project.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching all data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}