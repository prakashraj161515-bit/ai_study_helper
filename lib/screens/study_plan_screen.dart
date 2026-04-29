import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';

class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final plans = state.studyPlans;

    return Scaffold(
      appBar: AppBar(title: const Text('My Study Plan')),
      body: plans.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: plans.length,
              itemBuilder: (context, i) => _buildPlanTile(plans[i]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(context, null),
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Plan', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.calendar_badge_plus, size: 72, color: Colors.grey.withOpacity(0.25)),
          const SizedBox(height: 16),
          const Text('No study plans yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showDialog(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Create First Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTile(StudyPlan plan) {
    final state = Provider.of<AppState>(context, listen: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        border: Border.all(
          color: plan.isCompleted
              ? const Color(0xFF2E7D32).withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: () {
            plan.isCompleted = !plan.isCompleted;
            state.updateStudyPlan(plan);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: plan.isCompleted
                  ? const Color(0xFF2E7D32).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(
              plan.isCompleted ? CupertinoIcons.check_mark_circled : CupertinoIcons.circle,
              color: plan.isCompleted ? const Color(0xFF2E7D32) : Colors.grey,
              size: 22,
            ),
          ),
        ),
        title: Text(
          plan.subject,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: plan.isCompleted ? TextDecoration.lineThrough : null,
            color: plan.isCompleted ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.topic, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(CupertinoIcons.clock, size: 12, color: Color(0xFF2E7D32)),
                const SizedBox(width: 4),
                Text(plan.time,
                    style: const TextStyle(
                        color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(CupertinoIcons.pencil, size: 18, color: Color(0xFF2E7D32)),
              onPressed: () => _showDialog(context, plan),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.delete, size: 18, color: Colors.redAccent),
              onPressed: () => state.removeStudyPlan(plan.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDialog(BuildContext context, StudyPlan? existing) async {
    final subCtrl = TextEditingController(text: existing?.subject ?? '');
    final topicCtrl = TextEditingController(text: existing?.topic ?? '');

    final now = DateTime.now();
    int initHour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    String defaultHour = initHour.toString().padLeft(2, '0');
    String defaultMinute = now.minute.toString().padLeft(2, '0');
    String defaultMeridiem = now.hour >= 12 ? 'PM' : 'AM';

    if (existing != null) {
      try {
        final parts = existing.time.split(' ');
        final tp = parts[0].split(':');
        defaultHour = tp[0];
        defaultMinute = tp[1];
        defaultMeridiem = parts.length > 1 ? parts[1] : 'AM';
      } catch (_) {}
    }

    final hourCtrl = TextEditingController(text: defaultHour);
    final minuteCtrl = TextEditingController(text: defaultMinute);
    String meridiem = defaultMeridiem;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(existing == null ? 'Add Study Plan' : 'Edit Study Plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: subCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    hintText: 'e.g. Mathematics',
                    prefixIcon: Icon(CupertinoIcons.book),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: topicCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Topic',
                    hintText: 'e.g. Calculus Chapter 3',
                    prefixIcon: Icon(CupertinoIcons.doc_text),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Alarm Time',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hourCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 2,
                        decoration: const InputDecoration(
                          labelText: 'HH',
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: minuteCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 2,
                        decoration: const InputDecoration(
                          labelText: 'MM',
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'AM', label: Text('AM')),
                        ButtonSegment(value: 'PM', label: Text('PM')),
                      ],
                      selected: {meridiem},
                      onSelectionChanged: (s) => setStateDialog(() => meridiem = s.first),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? const Color(0xFF2E7D32)
                              : null,
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? Colors.white
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (subCtrl.text.trim().isEmpty) return;
                final timeStr =
                    '${hourCtrl.text.padLeft(2, '0')}:${minuteCtrl.text.padLeft(2, '0')} $meridiem';
                final appState = Provider.of<AppState>(context, listen: false);
                if (existing == null) {
                  appState.addStudyPlan(StudyPlan(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    subject: subCtrl.text.trim(),
                    topic: topicCtrl.text.trim(),
                    time: timeStr,
                  ));
                } else {
                  existing.subject = subCtrl.text.trim();
                  existing.topic = topicCtrl.text.trim();
                  existing.time = timeStr;
                  appState.updateStudyPlan(existing);
                }
                Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Save' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}
