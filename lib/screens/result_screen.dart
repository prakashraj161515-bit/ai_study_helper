import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatefulWidget {
  final String question;
  final String answer;

  const ResultScreen({super.key, required this.question, required this.answer});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late String _currentAnswer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentAnswer = widget.answer;
  }

  Future<void> _loadDetailed() async {
    final state = Provider.of<AppState>(context, listen: false);
    
    setState(() => _isLoading = true);
    try {
      final detailedAnswer = await state.askQuestion(widget.question, detailed: true);
      setState(() {
        _currentAnswer = detailedAnswer;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question:',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text(
              'AI Answer:',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : Text(
                      _currentAnswer,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'In Details',
                    CupertinoIcons.doc_text_fill,
                    Colors.blue,
                    _loadDetailed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Back Home',
                    CupertinoIcons.house_fill,
                    Colors.orange,
                    () => Navigator.of(context).popUntil((route) => route.isFirst),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => QuizScreen(topic: widget.question)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Generate MCQs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
