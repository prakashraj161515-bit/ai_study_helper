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
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(title: const Text('Solution')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Question',
              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Text(
                widget.question,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'AI Study Solution',
              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.05)),
              ),
              child: _isLoading 
                ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFF2E7D32))))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(CupertinoIcons.sparkles, color: Color(0xFF2E7D32), size: 18),
                          SizedBox(width: 8),
                          Text('Detailed Explanation', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentAnswer,
                        style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                      ),
                    ],
                  ),
            ),
            const SizedBox(height: 40),
            
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    'Get Detailed', 
                    CupertinoIcons.doc_text, 
                    const Color(0xFFE8F5E9), 
                    const Color(0xFF2E7D32), 
                    _loadDetailed
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildButton(
                    'Practice Quiz', 
                    CupertinoIcons.checkmark_seal, 
                    const Color(0xFFE3F2FD), 
                    const Color(0xFF1976D2), 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(topic: widget.question)))
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
