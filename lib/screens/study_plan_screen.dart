import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';

class StudyPlanScreen extends StatelessWidget {
  const StudyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final plans = state.studyPlans;

    return Scaffold(
      appBar: AppBar(title: const Text('My Study Plan')),
      body: plans.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return _buildPlanItem(context, plan);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlanDialog(context),
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.calendar_badge_plus, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No study plans yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showAddPlanDialog(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
            child: const Text('Create Your First Plan'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanItem(BuildContext context, StudyPlan plan) {
    final state = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        border: Border.all(color: Colors.grey.withOpacity(isDark ? 0.1 : 0.1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              plan.isCompleted ? CupertinoIcons.check_mark_circled : CupertinoIcons.circle,
              color: plan.isCompleted ? const Color(0xFF2E7D32) : Colors.grey,
            ),
            onPressed: () {
              plan.isCompleted = !plan.isCompleted;
              state.updateStudyPlan(plan);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.subject,
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    decoration: plan.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(plan.topic, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                Text(plan.time, style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.delete, size: 20, color: Colors.redAccent),
            onPressed: () => state.removeStudyPlan(plan.id),
          ),
        ],
      ),
    );
  }

  void _showAddPlanDialog(BuildContext context) {
    final subCtrl = TextEditingController();
    final topicCtrl = TextEditingController();
    final timeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Study Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: subCtrl, decoration: const InputDecoration(labelText: 'Subject (e.g. Math)')),
            TextField(controller: topicCtrl, decoration: const InputDecoration(labelText: 'Topic (e.g. Calculus)')),
            TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Time (e.g. 10:00 AM)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (subCtrl.text.isNotEmpty) {
                final plan = StudyPlan(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  subject: subCtrl.text,
                  topic: topicCtrl.text,
                  time: timeCtrl.text,
                );
                Provider.of<AppState>(context, listen: false).addStudyPlan(plan);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
