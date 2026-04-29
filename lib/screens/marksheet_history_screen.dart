import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../services/pdf_service.dart';
import '../models/models.dart';
import 'quiz_screen.dart';

class MarksheetHistoryScreen extends StatelessWidget {
  const MarksheetHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final marksheets = state.marksheets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marksheet History'),
        actions: [
          if (!state.isPremium)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                label: const Text('Free (Last 5)', style: TextStyle(fontSize: 12, color: Colors.white)),
                backgroundColor: Colors.orange,
              ),
            ),
        ],
      ),
      body: marksheets.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: marksheets.length,
              itemBuilder: (context, index) {
                final ms = marksheets[index];
                return _buildMarksheetCard(context, ms, state.isPremium);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.doc_text, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No marksheets saved yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Finish a quiz to automatically save your results!', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMarksheetCard(BuildContext context, Marksheet ms, bool isPremium) {
    final double percentage = (ms.score / ms.total) * 100;
    final String date = DateFormat('MMM d, yyyy • hh:mm a').format(ms.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getColor(percentage).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${ms.score}/${ms.total}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getColor(percentage),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ms.topic,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAction(
                  context,
                  'View Details',
                  CupertinoIcons.eye_fill,
                  Colors.blue,
                  () {
                     showDialog(
                       context: context,
                       builder: (context) => AlertDialog(
                         title: const Text('Marksheet Details'),
                         content: Column(
                           mainAxisSize: MainAxisSize.min,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text('Topic: ${ms.topic}', style: const TextStyle(fontWeight: FontWeight.bold)),
                             const SizedBox(height: 8),
                             Text('Score: ${ms.score} out of ${ms.total}'),
                             Text('Percentage: ${percentage.toStringAsFixed(1)}%'),
                             Text('Status: ${_getStatus(percentage)}'),
                           ],
                         ),
                         actions: [
                           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                         ],
                       ),
                     );
                  },
                ),
                _buildAction(
                  context,
                  'Review',
                  CupertinoIcons.list_bullet,
                  Colors.orange,
                  () {
                    if (ms.questions.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No review data available for this marksheet.')),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewScreen(
                            questions: ms.questions,
                            userAnswers: ms.userAnswers,
                          ),
                        ),
                      );
                    }
                  },
                ),
                _buildAction(
                  context,
                  'Download',
                  CupertinoIcons.cloud_download_fill,
                  isPremium ? Colors.green : Colors.grey,
                  () {
                    if (!isPremium) {
                      _showPremiumDialog(context);
                    } else {
                      PDFService().generateMarksheet(ms.score, ms.total, ms.topic);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  String _getStatus(double percentage) {
    if (percentage >= 80) return 'Excellent';
    if (percentage >= 50) return 'Good';
    return 'Need Improvement';
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Text('Download marksheet feature is only available for premium users. Free users can only save the last 5 marksheets.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Maybe Later')),
          ElevatedButton(
            onPressed: () {
              Provider.of<AppState>(context, listen: false).togglePremium();
              Navigator.pop(context);
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}
