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
  final bool _isLoading = false;
  String? _errorMessage;
  String _role = 'developer';
  int? _userId = 1;
  String? _username = 'testuser';
  String? _fullName = 'Test User';
  List<DailyScrumLog> _dailyScrumLogs = [];

  @override
  List<Project> get projects => _projects;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get errorMessage => _errorMessage;

  @override
  String get role => _role;

  @override
  bool get isScrumMaster => _role == 'scrum_master';

  @override
  bool get isDeveloper => _role == 'developer' || _role == 'user';

  @override
  bool get canCreateProject => isScrumMaster;

  @override
  bool get canManageRoles => isScrumMaster;

  @override
  Future<void> fetchProjects() async {}

  @override
  Future<void> addProject(String name, String sprint) async {
    final newProject = Project(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      sprint: int.tryParse(sprint) ?? 0,
      tasks: [],
    );
    _projects.add(newProject);
    notifyListeners();
  }

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
  @override
  Future<void> fetchNotifications() async {}
  @override
  void setUserData(int id, String username, String fullName, {String role = 'developer'}) {
    _userId = id;
    _username = username;
    _fullName = fullName;
    _role = role;
    notifyListeners();
  }
  @override
  String? get fullName => _fullName;
  @override
  int? get userId => _userId;
  @override
  String? get username => _username;
  @override
  List<NotificationItem> get notifications => [];
  @override
  List<DailyScrumLog> get dailyScrumLogs => _dailyScrumLogs;
  @override
  Future<void> fetchDailyScrumLogs(int projectId) async {}
  @override
  Future<bool> addDailyScrumLog({
    required int projectId,
    required String yesterday,
    required String today,
    required String blockers,
  }) async {
    _dailyScrumLogs.add(DailyScrumLog(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: _userId ?? 1,
      projectId: projectId,
      yesterday: yesterday,
      today: today,
      blockers: blockers,
      username: _username ?? 'test',
      scrumDate: DateTime.now(),
      createdAt: DateTime.now(),
    ));
    notifyListeners();
    return true;
  }
}

/// Helper to build a testable widget with mock provider
Widget buildTestableWidget(Widget child, MockSprintProvider provider) {
  return ChangeNotifierProvider<SprintProvider>.value(
    value: provider,
    child: MaterialApp(home: child),
  );
}

void main() {
  // ================================================================
  // MODEL UNIT TESTS
  // ================================================================
  group('Model Unit Tests', () {
    test('ScrumTask.fromJson parses correctly', () {
      final json = {
        'id': '1',
        'title': 'Test Task',
        'status': 'toDo',
        'story_points': '5',
        'assigned_sprint': '2',
        'completion_sprint': null,
      };

      final task = ScrumTask.fromJson(json);
      expect(task.id, '1');
      expect(task.title, 'Test Task');
      expect(task.status, TaskStatus.toDo);
      expect(task.storyPoints, 5);
      expect(task.assignedSprint, 2);
      expect(task.completionDay, isNull);
    });

    test('ScrumTask.fromJson handles unknown status gracefully', () {
      final json = {
        'id': '1',
        'title': 'Test',
        'status': 'unknownStatus',
        'story_points': '3',
      };
      final task = ScrumTask.fromJson(json);
      expect(task.status, TaskStatus.backlog); // Falls back to backlog
    });

    test('ScrumTask.fromJson handles done status with completion', () {
      final json = {
        'id': '2',
        'title': 'Done Task',
        'status': 'done',
        'story_points': '8',
        'assigned_sprint': '3',
        'completion_sprint': '3',
      };
      final task = ScrumTask.fromJson(json);
      expect(task.status, TaskStatus.done);
      expect(task.completionDay, 3);
    });

    test('Project.fromJson parses with nested tasks', () {
      final json = {
        'id': '10',
        'name': 'My Project',
        'sprint': '5',
        'tasks': [
          {'id': '1', 'title': 'T1', 'status': 'backlog', 'story_points': '3'},
          {'id': '2', 'title': 'T2', 'status': 'done', 'story_points': '5'},
        ],
      };

      final project = Project.fromJson(json);
      expect(project.id, 10);
      expect(project.name, 'My Project');
      expect(project.sprint, 5);
      expect(project.tasks.length, 2);
    });

    test('Project.progress calculates correctly', () {
      final project = Project(
        id: 1,
        name: 'Test',
        sprint: 3,
        tasks: [
          ScrumTask(id: '1', title: 'A', storyPoints: 5, status: TaskStatus.done),
          ScrumTask(id: '2', title: 'B', storyPoints: 5, status: TaskStatus.inProgress),
        ],
      );
      expect(project.progress, 50); // 5/10 = 50%
    });

    test('Project.progress returns 0 for empty tasks', () {
      final project = Project(id: 1, name: 'Empty', sprint: 3, tasks: []);
      expect(project.progress, 0);
    });

    test('Project.progress returns 100 when all done', () {
      final project = Project(
        id: 1,
        name: 'Complete',
        sprint: 2,
        tasks: [
          ScrumTask(id: '1', title: 'A', storyPoints: 3, status: TaskStatus.done),
          ScrumTask(id: '2', title: 'B', storyPoints: 7, status: TaskStatus.done),
        ],
      );
      expect(project.progress, 100);
    });

    test('Project.currentSprint returns highest assigned sprint', () {
      final project = Project(
        id: 1,
        name: 'Multi Sprint',
        sprint: 5,
        tasks: [
          ScrumTask(id: '1', title: 'A', storyPoints: 3, assignedSprint: 1),
          ScrumTask(id: '2', title: 'B', storyPoints: 5, assignedSprint: 3),
          ScrumTask(id: '3', title: 'C', storyPoints: 2, assignedSprint: 2),
        ],
      );
      expect(project.currentSprint, 3);
    });

    test('Project.currentSprint returns 1 for empty tasks', () {
      final project = Project(id: 1, name: 'Empty', sprint: 3, tasks: []);
      expect(project.currentSprint, 1);
    });

    test('BurndownData stores values correctly', () {
      final data = BurndownData(sprint: 2, estimated: 10, actual: 15);
      expect(data.sprint, 2);
      expect(data.estimated, 10);
      expect(data.actual, 15);
    });

    test('NotificationItem.fromJson parses correctly', () {
      final json = {
        'id': '5',
        'title': 'New Task',
        'message': 'Task created',
        'type': 'task_created',
        'is_read': 0,
        'created_at': '2026-03-01 10:00:00',
      };
      final notif = NotificationItem.fromJson(json);
      expect(notif.id, 5);
      expect(notif.title, 'New Task');
      expect(notif.type, 'task_created');
      expect(notif.isRead, false);
    });

    test('NotificationItem.fromJson handles is_read variants', () {
      final jsonTrue = {
        'id': '1', 'title': 'T', 'message': 'M',
        'type': 'info', 'is_read': true, 'created_at': '2026-01-01 00:00:00',
      };
      final jsonOne = {
        'id': '2', 'title': 'T', 'message': 'M',
        'type': 'info', 'is_read': 1, 'created_at': '2026-01-01 00:00:00',
      };
      expect(NotificationItem.fromJson(jsonTrue).isRead, true);
      expect(NotificationItem.fromJson(jsonOne).isRead, true);
    });

    test('DailyScrumLog.fromJson parses correctly', () {
      final json = {
        'id': '1',
        'user_id': '5',
        'project_id': '10',
        'yesterday': 'Did testing',
        'today': 'Will implement feature',
        'blockers': 'Waiting for API',
        'username': 'haikal',
        'scrum_date': '2026-03-03',
        'created_at': '2026-03-03 09:00:00',
      };
      final log = DailyScrumLog.fromJson(json);
      expect(log.id, 1);
      expect(log.userId, 5);
      expect(log.projectId, 10);
      expect(log.yesterday, 'Did testing');
      expect(log.today, 'Will implement feature');
      expect(log.blockers, 'Waiting for API');
      expect(log.username, 'haikal');
    });
  });

  // ================================================================
  // PROVIDER LOGIC TESTS
  // ================================================================
  group('SprintProvider Logic Tests', () {
    test('generateBurndownData returns correct data', () {
      final provider = MockSprintProvider();
      // Create a real SprintProvider to test the logic
      final realProvider = SprintProvider();

      final project = Project(
        id: 1,
        name: 'Burndown Test',
        sprint: 3,
        tasks: [
          ScrumTask(id: '1', title: 'A', storyPoints: 6, status: TaskStatus.done, completionDay: 1),
          ScrumTask(id: '2', title: 'B', storyPoints: 4, status: TaskStatus.done, completionDay: 2),
          ScrumTask(id: '3', title: 'C', storyPoints: 5, status: TaskStatus.inProgress),
        ],
      );

      final burndownData = realProvider.generateBurndownData(project);
      expect(burndownData.length, 4); // sprint 0 to sprint 3
      expect(burndownData[0].sprint, 0);
      expect(burndownData[0].actual, 15); // All 15 story points remain
      expect(burndownData[1].actual, 9);  // After sprint 1: 15-6 = 9
      expect(burndownData[2].actual, 5);  // After sprint 2: 15-6-4 = 5
    });

    test('generateBurndownData returns empty for no tasks', () {
      final realProvider = SprintProvider();
      final project = Project(id: 1, name: 'Empty', sprint: 3, tasks: []);
      expect(realProvider.generateBurndownData(project), isEmpty);
    });

    test('generateBurndownData returns empty for zero sprints', () {
      final realProvider = SprintProvider();
      final project = Project(
        id: 1, name: 'Zero Sprint', sprint: 0,
        tasks: [ScrumTask(id: '1', title: 'T', storyPoints: 5)],
      );
      expect(realProvider.generateBurndownData(project), isEmpty);
    });

    test('MockSprintProvider role permissions work', () {
      final provider = MockSprintProvider();
      
      // Default role is developer
      expect(provider.isDeveloper, true);
      expect(provider.isScrumMaster, false);
      expect(provider.canCreateProject, false);

      // Set as scrum master
      provider.setUserData(1, 'admin', 'Admin User', role: 'scrum_master');
      expect(provider.isScrumMaster, true);
      expect(provider.isDeveloper, false);
      expect(provider.canCreateProject, true);
      expect(provider.canManageRoles, true);
    });

    test('setUserData stores all fields correctly', () {
      final provider = MockSprintProvider();
      provider.setUserData(42, 'haikal', 'Haikal Riyadh', role: 'scrum_master');
      
      expect(provider.userId, 42);
      expect(provider.username, 'haikal');
      expect(provider.fullName, 'Haikal Riyadh');
      expect(provider.role, 'scrum_master');
    });
  });

  // ================================================================
  // WIDGET TESTS
  // ================================================================
  group('Widget Tests', () {
    testWidgets('HomePage shows all 4 bottom navigation tabs', (WidgetTester tester) async {
      final mockProvider = MockSprintProvider();
      await tester.pumpWidget(buildTestableWidget(const HomePage(), mockProvider));

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Proyek'), findsOneWidget);
      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Pengaturan'), findsOneWidget);
    });

    testWidgets('Bottom nav switches between pages', (WidgetTester tester) async {
      final mockProvider = MockSprintProvider();
      await tester.pumpWidget(buildTestableWidget(const HomePage(), mockProvider));

      // Tap on Projects tab
      await tester.tap(find.byIcon(Icons.folder_open));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectsPage), findsOneWidget);
    });

    testWidgets('ProjectsPage shows create project form', (WidgetTester tester) async {
      final mockProvider = MockSprintProvider();
      await tester.pumpWidget(buildTestableWidget(const ProjectsPage(), mockProvider));
      await tester.pumpAndSettle();

      expect(find.text('Project Name'), findsOneWidget);
      expect(find.text('Sprint'), findsOneWidget);
      expect(find.text('Create Project'), findsOneWidget);
    });

    testWidgets('Pengguna dapat menambahkan proyek baru dan melihatnya di daftar', (WidgetTester tester) async {
      final mockProvider = MockSprintProvider();
      await tester.pumpWidget(buildTestableWidget(const HomePage(), mockProvider));

      // Navigate to Projects tab
      await tester.tap(find.byIcon(Icons.folder_open));
      await tester.pumpAndSettle();

      expect(find.byType(ProjectsPage), findsOneWidget);
      expect(find.text('Project Name'), findsOneWidget);
      expect(find.text("Proyek Mobile Baru"), findsNothing);

      // Fill form and submit
      await tester.enterText(find.widgetWithText(TextFormField, 'Project Name'), 'Proyek Mobile Baru');
      await tester.enterText(find.widgetWithText(TextFormField, 'Sprint'), '8');
      await tester.tap(find.text('Create Project'));
      await tester.pumpAndSettle();

      expect(find.text('Proyek Mobile Baru'), findsOneWidget);
      expect(find.text('Sprint: 8 | Progres: 0%'), findsOneWidget);
    });

    testWidgets('ProjectsPage validates empty project name', (WidgetTester tester) async {
      final mockProvider = MockSprintProvider();
      await tester.pumpWidget(buildTestableWidget(const ProjectsPage(), mockProvider));
      await tester.pumpAndSettle();

      // Try to submit with empty fields
      await tester.tap(find.text('Create Project'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Masukkan nama proyek'), findsOneWidget);
    });

    testWidgets('ProjectsPage validates sprint as number', (WidgetTester tester) async {
      final mockProvider = MockSprintProvider();
      await tester.pumpWidget(buildTestableWidget(const ProjectsPage(), mockProvider));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Project Name'), 'Test');
      await tester.enterText(find.widgetWithText(TextFormField, 'Sprint'), 'abc');
      await tester.tap(find.text('Create Project'));
      await tester.pumpAndSettle();

      expect(find.text('Sprint harus berupa angka'), findsOneWidget);
    });
  });

  // ================================================================
  // NAVIGATION TESTS
  // ================================================================
  group('Navigation Tests', () {
    testWidgets('Settings page shows account, roles, and logout', (WidgetTester tester) async {
      final mockProvider = MockSprintProvider();
      await tester.pumpWidget(buildTestableWidget(const HomePage(), mockProvider));

      // Navigate to Settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Roles & Permissions'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });
  });
}
