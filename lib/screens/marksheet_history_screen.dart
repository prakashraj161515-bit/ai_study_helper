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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Marksheets'),
        actions: [
          IconButton(icon: const Icon(Icons.school_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card (Simulated from image)
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.userName ?? 'Prakash Kumar',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Class 12th (Science)',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      ),
                      Text(
                        'Roll No.: 123456',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.badge, color: Color(0xFF2E7D32), size: 32),
                ),
              ],
            ),
          ),
          
          // Tabs (Simulated)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildTab('All Exams', true),
                _buildTab('Term Exams', false),
                _buildTab('Annual Exams', false),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: marksheets.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: marksheets.length,
                    itemBuilder: (context, index) {
                      final ms = marksheets[index];
                      return _buildMarksheetItem(context, ms, state.isPremium);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F5E9) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? const Color(0xFF2E7D32) : Colors.grey,
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.doc_text, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text('No marksheets saved yet', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildMarksheetItem(BuildContext context, Marksheet ms, bool isPremium) {
    final double percentage = (ms.score / ms.total) * 100;
    final String date = DateFormat('dd MMM yyyy').format(ms.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                    Text('CBSE • $date', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _showOptions(context, ms, isPremium);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8F5E9),
                  foregroundColor: const Color(0xFF2E7D32),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  minimumSize: const Size(60, 32),
                ),
                child: const Text('View', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Percentage: ',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, Marksheet ms, bool isPremium) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Marksheet Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildOptionTile(context, CupertinoIcons.eye, 'View Details', () {
              Navigator.pop(context);
              _showDetailsDialog(context, ms);
            }),
            _buildOptionTile(context, CupertinoIcons.list_bullet, 'Review Answers', () {
              Navigator.pop(context);
              if (ms.questions.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No review data available.')));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(questions: ms.questions, userAnswers: ms.userAnswers)));
              }
            }, color: Colors.orange),
            _buildOptionTile(context, CupertinoIcons.cloud_download, 'Download PDF', () {
              Navigator.pop(context);
              if (!isPremium) {
                _showPremiumDialog(context);
              } else {
                PDFService().generateMarksheet(ms.score, ms.total, ms.topic);
              }
            }, color: Colors.green),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? const Color(0xFF2E7D32)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
    );
  }

  void _showDetailsDialog(BuildContext context, Marksheet ms) {
    final double percentage = (ms.score / ms.total) * 100;
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
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Text('Download marksheet feature is only available for premium users.'),
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
