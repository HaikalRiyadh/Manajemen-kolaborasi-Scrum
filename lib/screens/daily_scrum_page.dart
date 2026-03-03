import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/sprint_provider.dart';
import '../models/models.dart';

class DailyScrumPage extends StatefulWidget {
  final int projectId;
  final String projectName;

  const DailyScrumPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<DailyScrumPage> createState() => _DailyScrumPageState();
}

class _DailyScrumPageState extends State<DailyScrumPage> {
  final _formKey = GlobalKey<FormState>();
  final _yesterdayController = TextEditingController();
  final _todayController = TextEditingController();
  final _blockersController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SprintProvider>(context, listen: false)
          .fetchDailyScrumLogs(widget.projectId);
    });
  }

  Future<void> _submitDailyScrum() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = Provider.of<SprintProvider>(context, listen: false);
    final success = await provider.addDailyScrumLog(
      projectId: widget.projectId,
      yesterday: _yesterdayController.text.trim(),
      today: _todayController.text.trim(),
      blockers: _blockersController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _yesterdayController.clear();
      _todayController.clear();
      _blockersController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily Scrum berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menyimpan daily scrum'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Scrum - ${widget.projectName}'),
      ),
      body: Column(
        children: [
          // Form Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.record_voice_over, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Stand-up Meeting Log',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const Divider(height: 24),
                      _buildQuestionField(
                        label: '🔙 Apa yang dikerjakan kemarin?',
                        controller: _yesterdayController,
                        hint: 'Contoh: Menyelesaikan fitur login dan unit test...',
                      ),
                      const SizedBox(height: 12),
                      _buildQuestionField(
                        label: '📌 Apa yang akan dikerjakan hari ini?',
                        controller: _todayController,
                        hint: 'Contoh: Implementasi fitur daily scrum log...',
                      ),
                      const SizedBox(height: 12),
                      _buildQuestionField(
                        label: '🚧 Apakah ada hambatan (blockers)?',
                        controller: _blockersController,
                        hint: 'Contoh: Menunggu API endpoint dari backend...',
                        isRequired: false,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitDailyScrum,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send),
                          label: Text(_isSubmitting ? 'Menyimpan...' : 'Submit Daily Scrum'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // History section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.history, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Histori Daily Scrum',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Log list
          Expanded(
            child: Consumer<SprintProvider>(
              builder: (context, provider, child) {
                final logs = provider.dailyScrumLogs;

                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada log daily scrum',
                          style: TextStyle(color: Colors.grey[500], fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Submit daily scrum pertamamu!',
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchDailyScrumLogs(widget.projectId),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildLogCard(log);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(12),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Field ini wajib diisi';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildLogCard(DailyScrumLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        log.username.isNotEmpty ? log.username[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      log.username.isNotEmpty ? log.username : 'User #${log.userId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(log.scrumDate),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 16),
            _buildLogSection('🔙 Kemarin', log.yesterday),
            const SizedBox(height: 8),
            _buildLogSection('📌 Hari Ini', log.today),
            if (log.blockers.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildLogSection('🚧 Blockers', log.blockers, isBlocker: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogSection(String title, String content, {bool isBlocker = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isBlocker ? Colors.red.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: isBlocker ? Border.all(color: Colors.red.shade200) : null,
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: isBlocker ? Colors.red.shade800 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _yesterdayController.dispose();
    _todayController.dispose();
    _blockersController.dispose();
    super.dispose();
  }
}
