import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final reminders = state.reminders;

    return Scaffold(
      appBar: AppBar(title: const Text('Study Reminders')),
      body: reminders.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                return _buildReminderTile(context, reminder);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderDialog(context),
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
          Icon(CupertinoIcons.bell_slash, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No reminders set', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showAddReminderDialog(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
            child: const Text('Set a Reminder'),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTile(BuildContext context, Reminder reminder) {
    final state = Provider.of<AppState>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(CupertinoIcons.bell_fill, color: reminder.isActive ? const Color(0xFF2E7D32) : Colors.grey),
        title: Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(reminder.time),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoSwitch(
              value: reminder.isActive,
              onChanged: (v) {
                reminder.isActive = v;
                state.updateReminder(reminder);
              },
              activeColor: const Color(0xFF2E7D32),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.delete, size: 20, color: Colors.redAccent),
              onPressed: () => state.removeReminder(reminder.id),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final timeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Reminder Name (e.g. Exam Rev)')),
            TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Time (e.g. 09:00 AM)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                final reminder = Reminder(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleCtrl.text,
                  time: timeCtrl.text,
                );
                Provider.of<AppState>(context, listen: false).addReminder(reminder);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
