import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:project/services/sprint_provider.dart';
import 'package:project/models/models.dart';
import 'package:project/screens/home_page.dart';
import 'package:project/screens/projects_page.dart';

// Mock Provider untuk mengisolasi tes dari network dan database
class MockSprintProvider extends ChangeNotifier implements SprintProvider {
  List<Project> _projects = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  List<Project> get projects => _projects;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<void> fetchProjects() async {
    // Simulasi tanpa tindakan
  }

  @override
  Future<void> addProject(String name, String sprint) async {
    final newProject = Project(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      sprint: int.tryParse(sprint) ?? 0,
      tasks: [],
    );
    _projects.add(newProject);
    notifyListeners(); // Memberi tahu UI untuk update
  }

  // Implementasi sisa dari abstract methods jika ada, dengan behavior kosong
  @override
  void _setLoading(bool loading) { _isLoading = loading; notifyListeners(); }
  @override
  void _setError(String? message) { _errorMessage = message; notifyListeners(); }
  @override
  void clearError() { _errorMessage = null; notifyListeners(); }
  @override
  Future<void> updateTaskStatus(ScrumTask task, TaskStatus newStatus, int projectId, int sprintNumber) async {}
  @override
  List<BurndownData> generateBurndownData(Project project) => [];
  @override
  Future<void> deleteTask(String taskId, int projectId) async {}
  @override
  Future<void> addTask(int projectId, String title, int storyPoints) async {}
}

void main() {
  // Skenario BDD: Menambahkan Proyek Baru
  testWidgets('Pengguna dapat menambahkan proyek baru dan melihatnya di daftar', (WidgetTester tester) async {
    // Arrange: Siapkan mock provider
    final mockProvider = MockSprintProvider();

    // Bangun aplikasi dengan mock provider, mulai dari HomePage
    await tester.pumpWidget(
      ChangeNotifierProvider<SprintProvider>.value(
        value: mockProvider,
        child: const MaterialApp(
          home: HomePage(), 
        ),
      ),
    );

    // **Given:** Pengguna berada di HomePage dan beralih ke halaman Proyek
    await tester.tap(find.byIcon(Icons.folder_open));
    await tester.pumpAndSettle();

    // Verifikasi bahwa kita berada di ProjectsPage dan formnya ada
    expect(find.byType(ProjectsPage), findsOneWidget, reason: 'Seharusnya sudah berada di ProjectsPage');
    expect(find.text('Project Name'), findsOneWidget, reason: 'Form input nama proyek seharusnya ada');
    expect(find.text("Proyek Mobile Baru"), findsNothing, reason: 'Proyek baru seharusnya belum ada di daftar');

    // **When:** Pengguna mengisi form dan menekan tombol 'Create Project'
    await tester.enterText(find.widgetWithText(TextFormField, 'Project Name'), 'Proyek Mobile Baru');
    await tester.enterText(find.widgetWithText(TextFormField, 'Sprint'), '8');
    await tester.tap(find.text('Create Project'));
    await tester.pumpAndSettle(); // Tunggu UI diperbarui setelah menambah proyek

    // **Then:** Proyek baru muncul di dalam daftar
    expect(find.text('Proyek Mobile Baru'), findsOneWidget, reason: 'Proyek baru seharusnya tampil di daftar');
    // Verifikasi detail lain jika ditampilkan di card, contohnya jumlah sprint
    expect(find.text('Sprint: 8 | Progres: 0%'), findsOneWidget, reason: 'Detail proyek di card seharusnya benar');
  });
}
