import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/ai_service.dart';
import '../services/pdf_service.dart';

class QuizScreen extends StatefulWidget {
  final String topic;
  const QuizScreen({super.key, required this.topic});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final AIService _ai = AIService();
  List<dynamic> _questions = [];
  List<int?> _userAnswers = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  int? _selectedAnswer;
  bool _isAnswered = false;
  bool _showResult = false;
  bool _showSettings = true;

  int _selectedCount = 4;
  String _selectedDifficulty = 'easy';

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppState>(context, listen: false);
    if (state.isPremium) {
      _selectedCount = 5;
    } else {
      _selectedCount = 4;
    }
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
        _userAnswers = List.filled(questions.length, null);
        _isLoading = false;
        _currentIndex = 0;
        _score = 0;
        _showResult = false;
        _selectedAnswer = null;
        _isAnswered = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _handleOptionTap(int index) {
    if (_isAnswered) return;

    setState(() {
      _selectedAnswer = index;
      _isAnswered = true;
      _userAnswers[_currentIndex] = index;
      
      if (index == _questions[_currentIndex]['correctIndex']) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _isAnswered = false;
      });
    } else {
      setState(() => _showResult = true);
      final state = Provider.of<AppState>(context, listen: false);
      state.updateQuizResult(_score, _questions.length);
      state.saveMarksheet(widget.topic, _score, _questions.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (_showSettings) return _buildSettingsView(state);
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_showResult) return _buildResultSummary();

    final Map<String, dynamic> question = Map<String, dynamic>.from(_questions[_currentIndex]);

    return Scaffold(
      appBar: AppBar(title: Text('Quiz (${_currentIndex + 1}/${_questions.length})')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: (_currentIndex + 1) / _questions.length),
            const SizedBox(height: 24),
            Text(question['question'].toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ...List.generate(
              (question['options'] as List).length,
              (index) => _buildOptionCard(index, question),
            ),
            const Spacer(),
            if (_isAnswered)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
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

  Widget _buildOptionCard(int index, Map<String, dynamic> question) {
    final int correctIndex = question['correctIndex'];
    final bool isSelected = _selectedAnswer == index;
    final bool isCorrect = index == correctIndex;
    
    Color borderColor = Colors.grey[300]!;
    Color bgColor = Colors.white;
    Widget? trailing;

    if (_isAnswered) {
      if (isCorrect) {
        borderColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.1);
        trailing = const Icon(Icons.check_circle, color: Colors.green);
      } else if (isSelected) {
        borderColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
        trailing = const Icon(Icons.cancel, color: Colors.red);
      }
    } else if (isSelected) {
      borderColor = Theme.of(context).primaryColor;
      bgColor = Theme.of(context).primaryColor.withOpacity(0.1);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleOptionTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(String.fromCharCode(65 + index), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(child: Text(question['options'][index].toString(), style: const TextStyle(fontSize: 16))),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsView(AppState state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (!state.isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('4 Questions (Free Version)', style: TextStyle(color: Colors.black87)),
                  ],
                ),
              )
            else
              Wrap(spacing: 8, children: [5, 10, 15].map((c) => ChoiceChip(
                label: Text('$c'), 
                selected: _selectedCount == c,
                onSelected: (s) => setState(() => _selectedCount = c),
              )).toList()),
            const SizedBox(height: 24),
            const Text('Difficulty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: ['easy', 'medium', 'hard'].map((d) => ChoiceChip(
              label: Text(d.toUpperCase()), 
              selected: _selectedDifficulty == d,
              onSelected: (s) => setState(() => _selectedDifficulty = d),
            )).toList()),
            const Spacer(),
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
              onPressed: _fetchQuestions,
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Start Quiz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSummary() {
    return Scaffold(
      appBar: AppBar(title: const Text('Result Summary')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$_score/${_questions.length}', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
            const SizedBox(height: 40),
            _buildResultAction('Review Answers', CupertinoIcons.list_bullet, Colors.blue, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(questions: _questions, userAnswers: _userAnswers)));
            }),
            const SizedBox(height: 12),
            _buildResultAction('Download Marksheet', CupertinoIcons.cloud_download_fill, Colors.green, () {
               final state = Provider.of<AppState>(context, listen: false);
               if (!state.isPremium) {
                 _showPremiumDialog();
               } else {
                 PDFService().generateMarksheet(_score, _questions.length, widget.topic);
               }
            }),
            const Spacer(),
            SizedBox(width: double.infinity, height: 56, child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Back to Home'),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildResultAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[300]!)),
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Text('Download marksheet feature is only available for premium users. You can also save unlimited marksheets and share them!'),
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

class ReviewScreen extends StatelessWidget {
  final List<dynamic> questions;
  final List<int?> userAnswers;
  const ReviewScreen({super.key, required this.questions, required this.userAnswers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Answers')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final Map<String, dynamic> q = Map<String, dynamic>.from(questions[index]);
          final int? userChoice = userAnswers[index];
          final int correctIndex = q['correctIndex'];
          final bool isCorrect = userChoice == correctIndex;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q${index + 1}: ${q['question']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...List.generate((q['options'] as List).length, (i) {
                    bool isUserSelection = userChoice == i;
                    bool isCorrectOption = correctIndex == i;
                    
                    Color textColor = Colors.black87;
                    if (isCorrectOption) textColor = Colors.green;
                    else if (isUserSelection && !isCorrect) textColor = Colors.red;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            isCorrectOption ? Icons.check_circle : (isUserSelection ? Icons.cancel : Icons.radio_button_unchecked),
                            size: 16,
                            color: textColor == Colors.black87 ? Colors.grey : textColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(q['options'][i].toString(), style: TextStyle(color: textColor, fontWeight: isUserSelection || isCorrectOption ? FontWeight.bold : null))),
                        ],
                      ),
                    );
                  }),
                  if (q['explanation'] != null) ...[
                    const Divider(height: 24),
                    Text('Explanation:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800])),
                    Text(q['explanation'].toString(), style: const TextStyle(fontStyle: FontStyle.italic)),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
