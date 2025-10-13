import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

// Pastikan semua path import ini sudah benar
import '../services/sprint_provider.dart';
import '../models/models.dart';
import 'projects_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Memuat semua data proyek saat halaman pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SprintProvider>(context, listen: false).fetchAllProjectData();
    });
  }

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Consumer<SprintProvider>(
          builder: (context, sprintProvider, child) {
            if (sprintProvider.isLoading && sprintProvider.projectsWithTasks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (sprintProvider.projectsWithTasks.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () => sprintProvider.fetchAllProjectData(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: sprintProvider.projectsWithTasks.length + 1, // +1 untuk header
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildHeader(context, headerStyle);
                  }
                  final project = sprintProvider.projectsWithTasks[index - 1];
                  return _buildProjectDashboard(context, project);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // --- WIDGET-WIDGET HELPER ---

  Widget _buildHeader(BuildContext context, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const FlutterLogo(size: 36),
            const SizedBox(width: 8),
            Text('Dashboard', style: style),
          ]),
          OutlinedButton.icon(
            icon: const Icon(Icons.list_alt_rounded, size: 18),
            label: const Text('Semua Proyek'),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectsPage()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDashboard(BuildContext context, Project project) {
    const subHeaderStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

    final tasks = project.tasks;
    final double totalTasks = tasks.length.toDouble();
    final double countDone = tasks.where((t) => t.status == TaskStatus.done).length.toDouble();
    final double countInProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length.toDouble();
    final double countToDo = tasks.where((t) => t.status == TaskStatus.toDo).length.toDouble();

    final List<FlSpot> workflowData = [
      FlSpot(0, totalTasks), FlSpot(1, totalTasks),
      FlSpot(2, countToDo + countInProgress + countDone),
      FlSpot(3, countInProgress + countDone),
      FlSpot(4, countDone), FlSpot(5, 0),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.name, style: subHeaderStyle),
            const Divider(height: 24),
            Text('Workflow Burndown', style: subHeaderStyle.copyWith(fontSize: 16)),
            const SizedBox(height: 20),
            tasks.isEmpty
                ? const SizedBox(height: 200, child: Center(child: Text('Tidak ada tugas di proyek ini.')))
                : _buildWorkflowChart(context, workflowData, totalTasks),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowChart(BuildContext context, List<FlSpot> data, double totalTasks) {
    double calculatedMaxY = (totalTasks > 0 ? (totalTasks / 5).ceil() * 5.0 : 5.0);
    if (calculatedMaxY <= totalTasks && totalTasks > 0) calculatedMaxY += 5.0;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 0, maxX: 5, minY: 0, maxY: calculatedMaxY,
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: _bottomTitleWidgets)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => _leftTitleWidgets(value, meta, calculatedMaxY))),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.black26, width: 1)),
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              barWidth: 3,
              color: Theme.of(context).primaryColor,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Theme.of(context).primaryColor.withOpacity(0.2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.layers_clear_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Tidak Ada Proyek', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Buat proyek baru di halaman "Projects" untuk melihat progress di sini.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Buat Proyek'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectsPage()));
              },
            )
          ],
        ),
      ),
    );
  }

  // ### KODE YANG SEBELUMNYA HILANG ###

  // Helper untuk judul sumbu X
  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold);
    String text;
    switch (value.toInt()) {
      case 1: text = 'Backlog'; break;
      case 2: text = 'To Do'; break;
      case 3: text = 'In Prog'; break;
      case 4: text = 'Done'; break;
      case 5: text = 'Finish'; break;
      default: return Container();
    }
    return SideTitleWidget(axisSide: meta.axisSide, space: 4, child: Text(text, style: style));
  }

  // Helper untuk judul sumbu Y
  Widget _leftTitleWidgets(double value, TitleMeta meta, double calculatedMaxY) {
    const style = TextStyle(fontSize: 10, color: Colors.black54);
    int interval;
    if (calculatedMaxY <= 5) {
      interval = 1;
    } else if (calculatedMaxY <= 10) {
      interval = 2;
    } else {
      interval = 5;
    }

    if (value == 0 || value == calculatedMaxY || (value % interval == 0 && value > 0)) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 4,
        child: Text('${value.toInt()}', style: style, textAlign: TextAlign.center),
      );
    }
    return Container();
  }
}