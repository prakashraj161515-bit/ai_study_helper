import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final reminders = state.reminders;

    return Scaffold(
      appBar: AppBar(title: const Text('Study Reminders')),
      body: reminders.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: reminders.length,
              itemBuilder: (context, index) => _buildTile(reminders[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(context, null),
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Reminder', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.bell_slash, size: 72, color: Colors.grey.withOpacity(0.25)),
          const SizedBox(height: 16),
          const Text('No reminders yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showDialog(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Add Reminder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(Reminder reminder) {
    final state = Provider.of<AppState>(context, listen: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: reminder.isActive
                ? const Color(0xFF2E7D32).withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            CupertinoIcons.bell_fill,
            color: reminder.isActive ? const Color(0xFF2E7D32) : Colors.grey,
            size: 20,
          ),
        ),
        title: Text(reminder.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: reminder.isActive ? Colors.black87 : Colors.grey,
            )),
        subtitle: Text(
          reminder.time,
          style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoSwitch(
              value: reminder.isActive,
              activeColor: const Color(0xFF2E7D32),
              onChanged: (v) {
                reminder.isActive = v;
                state.updateReminder(reminder);
              },
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(CupertinoIcons.pencil, size: 18, color: Color(0xFF2E7D32)),
              onPressed: () => _showDialog(context, reminder),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.delete, size: 18, color: Colors.redAccent),
              onPressed: () => state.removeReminder(reminder.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDialog(BuildContext context, Reminder? existing) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    // Pre-fill with current time if new, existing time if editing
    final now = DateTime.now();
    String defaultHour = now.hour > 12
        ? (now.hour - 12).toString().padLeft(2, '0')
        : now.hour.toString().padLeft(2, '0');
    String defaultMinute = now.minute.toString().padLeft(2, '0');
    String defaultMeridiem = now.hour >= 12 ? 'PM' : 'AM';

    if (existing != null) {
      // parse existing time like "09:30 AM"
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
          title: Text(existing == null ? 'Add Reminder' : 'Edit Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reminder Name',
                  hintText: 'e.g. Morning Study',
                  prefixIcon: Icon(CupertinoIcons.bell),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                final timeStr =
                    '${hourCtrl.text.padLeft(2, '0')}:${minuteCtrl.text.padLeft(2, '0')} $meridiem';
                final appState = Provider.of<AppState>(context, listen: false);
                if (existing == null) {
                  appState.addReminder(Reminder(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleCtrl.text.trim(),
                    time: timeStr,
                  ));
                } else {
                  existing.title = titleCtrl.text.trim();
                  existing.time = timeStr;
                  appState.updateReminder(existing);
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
