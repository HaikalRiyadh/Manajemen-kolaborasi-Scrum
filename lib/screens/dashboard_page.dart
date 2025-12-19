import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Menggunakan fetchProjects karena sudah mencakup semua data
      Provider.of<SprintProvider>(context, listen: false).fetchProjects();
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
            if (sprintProvider.isLoading && sprintProvider.projects.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // Menggunakan provider.projects yang sekarang berisi semua data
            final activeProjects = sprintProvider.projects.where((p) => p.progress < 100).toList();

            if (activeProjects.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () => sprintProvider.fetchProjects(), // Cukup panggil fetchProjects
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: activeProjects.length + 1, // +1 untuk header
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildHeader(context, headerStyle);
                  }
                  final project = activeProjects[index - 1];
                  return BurndownChartCard(project: project);
                },
              ),
            );
          },
        ),
      ),
    );
  }
  
  // ... (Widget _buildHeader dan _buildEmptyState tidak berubah)
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.layers_clear_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Tidak Ada Proyek Aktif', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Semua proyek sudah selesai atau belum ada proyek yang dibuat.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
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
}

class BurndownChartCard extends StatelessWidget {
  final Project project;

  const BurndownChartCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    // Tidak perlu memanggil provider di sini, karena data sudah lengkap dari Consumer
    final sprintProvider = Provider.of<SprintProvider>(context, listen: false);
    final burndownData = sprintProvider.generateBurndownData(project);
    final totalStoryPoints = project.tasks.fold<int>(0, (sum, task) => sum + task.storyPoints);

    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(project.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Text('Sprint Saat Ini: ${project.currentSprint}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
            const Divider(height: 24),
            Text('Burndown Chart', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            burndownData.isEmpty
                ? const SizedBox(height: 200, child: Center(child: Text('Data tidak cukup untuk menampilkan chart.')))
                : _buildChart(context, burndownData, totalStoryPoints, project.sprint),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<BurndownData> data, int totalStoryPoints, int totalSprints) {
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: totalSprints.toDouble(),
          minY: 0,
          maxY: totalStoryPoints.toDouble(),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) => _bottomTitleWidgets(value, meta, totalSprints),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) => _leftTitleWidgets(value, meta, totalStoryPoints.toDouble()),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Garis Estimasi (Ideal)
            LineChartBarData(
              spots: data.map((d) => FlSpot(d.sprint.toDouble(), d.estimated.toDouble())).toList(),
              isCurved: false,
              color: Colors.purple.withOpacity(0.5),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              dashArray: [5, 5],
            ),
            // Garis Aktual
            LineChartBarData(
              spots: data.map((d) => FlSpot(d.sprint.toDouble(), d.actual.toDouble())).toList(),
              isCurved: false,
              color: Colors.purple,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
            ),
          ],
          gridData: const FlGridData(
            show: true,
            drawVerticalLine: true,
            drawHorizontalLine: true,
            verticalInterval: 1,
          ),
        ),
      ),
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta, int totalSprints) {
    const style = TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold);
    int interval = (totalSprints / 5).ceil();
    if (value.toInt() % interval == 0 || value.toInt() == totalSprints) {
      return SideTitleWidget(axisSide: meta.axisSide, space: 4, child: Text('S${value.toInt()}', style: style));
    }
    return Container();
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta, double calculatedMaxY) {
    const style = TextStyle(fontSize: 10, color: Colors.black54);
    double interval = (calculatedMaxY / 4).ceilToDouble();
    if (interval > 0 && (value % interval == 0 || value == calculatedMaxY)) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 4,
        child: Text('${value.toInt()} pts', style: style, textAlign: TextAlign.center),
      );
    }
    return Container();
  }
}
