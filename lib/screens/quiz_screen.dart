import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/ai_service.dart';
import '../services/pdf_service.dart';
import '../models/models.dart';

class QuizScreen extends StatefulWidget {
  final String topic;
  const QuizScreen({super.key, required this.topic});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final AIService _ai = AIService();
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  int? _selectedAnswer;
  bool _showResult = false;
  bool _showSettings = true;

  int _selectedCount = 3;
  String _selectedDifficulty = 'easy';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _showSettings = false;
    });
    try {
      final questions = await _ai.generateMCQs(
        widget.topic, 
        count: _selectedCount, 
        difficulty: _selectedDifficulty
      );
      setState(() {
        _questions = questions;
        _isLoading = false;
        _currentIndex = 0;
        _score = 0;
        _showResult = false;
        _selectedAnswer = null;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _submitAnswer() {
    if (_selectedAnswer == null) return;
    
    if (_selectedAnswer == _questions[_currentIndex]['correctIndex']) {
      _score++;
    }

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
      });
    } else {
      setState(() => _showResult = true);
      Provider.of<AppState>(context, listen: false).updateQuizResult(_score, _questions.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (_showSettings) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Settings')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Number of Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [3, 5, 10, 15].map((count) {
                  final isLocked = count > 3 && !state.isPremium;
                  return ChoiceChip(
                    label: Text('$count'),
                    selected: _selectedCount == count,
                    onSelected: isLocked ? null : (selected) {
                      if (selected) setState(() => _selectedCount = count);
                    },
                    avatar: isLocked ? const Icon(CupertinoIcons.lock_fill, size: 14) : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Difficulty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['easy', 'medium', 'hard'].map((diff) {
                  final isLocked = diff != 'easy' && !state.isPremium;
                  return ChoiceChip(
                    label: Text(diff.toUpperCase()),
                    selected: _selectedDifficulty == diff,
                    onSelected: isLocked ? null : (selected) {
                      if (selected) setState(() => _selectedDifficulty = diff);
                    },
                    avatar: isLocked ? const Icon(CupertinoIcons.lock_fill, size: 14) : null,
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _fetchQuestions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Start Quiz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_showResult) {
      return _buildResultSummary();
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz (${_currentIndex + 1}/${_questions.length})'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 24),
            Text(
              question['question'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...List.generate(
              (question['options'] as List).length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => setState(() => _selectedAnswer = index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedAnswer == index 
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.white,
                      border: Border.all(
                        color: _selectedAnswer == index 
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: _selectedAnswer == index ? Theme.of(context).primaryColor : Colors.grey[300],
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            question['options'][index],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedAnswer == null ? null : _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _currentIndex == _questions.length - 1 ? 'Finish' : 'Next',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSummary() {
    final percentage = (_score / _questions.length * 100).toStringAsFixed(0);
    return Scaffold(
      appBar: AppBar(title: const Text('Result Summary')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_score/${_questions.length}',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                    ),
                    Text('$percentage%', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Great Job!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep studying to improve your streak.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _buildResultAction(
              'Review Answers',
              CupertinoIcons.list_bullet,
              Colors.blue,
              () {}, // Could implement a review screen
            ),
            const SizedBox(height: 12),
            _buildResultAction(
              'Download Marksheet',
              CupertinoIcons.cloud_download_fill,
              Colors.green,
              () {
                final state = Provider.of<AppState>(context, listen: false);
                if (!state.isPremium) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Premium feature: Marksheet download locked.")),
                  );
                } else {
                  PDFService().generateMarksheet(_score, _questions.length, widget.topic);
                }
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Home', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
