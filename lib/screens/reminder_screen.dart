import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Reminders')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildReminderTile('Morning Session', '09:00 AM', true),
          _buildReminderTile('Afternoon Review', '02:00 PM', true),
          _buildReminderTile('Evening Quiz', '07:00 PM', false),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add New Reminder'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTile(String title, String time, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: const Icon(CupertinoIcons.bell_fill, color: Color(0xFF2E7D32)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(time),
        trailing: CupertinoSwitch(
          value: isActive,
          onChanged: (v) {},
          activeColor: const Color(0xFF2E7D32),
        ),
      ),
    );
  }
}
