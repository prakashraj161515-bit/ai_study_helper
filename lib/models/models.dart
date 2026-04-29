import 'dart:convert';

enum QuestionDifficulty { easy, medium, hard }

class StudyHistoryItem {
  final String id;
  final String question;
  final String answer;
  final DateTime timestamp;
  final bool isDetailed;

  StudyHistoryItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.timestamp,
    this.isDetailed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'timestamp': timestamp.toIso8601String(),
      'isDetailed': isDetailed,
    };
  }

  factory StudyHistoryItem.fromMap(Map<String, dynamic> map) {
    return StudyHistoryItem(
      id: map['id'],
      question: map['question'],
      answer: map['answer'],
      timestamp: DateTime.parse(map['timestamp']),
      isDetailed: map['isDetailed'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());
  factory StudyHistoryItem.fromJson(String source) => StudyHistoryItem.fromMap(json.decode(source));
}

class MCQOption {
  final String text;
  final bool isCorrect;

  MCQOption({required this.text, required this.isCorrect});

  Map<String, dynamic> toMap() {
    return {'text': text, 'isCorrect': isCorrect};
  }

  factory MCQOption.fromMap(Map<String, dynamic> map) {
    return MCQOption(text: map['text'], isCorrect: map['isCorrect']);
  }
}

class MCQQuestion {
  final String question;
  final List<MCQOption> options;
  final String explanation;

  MCQQuestion({
    required this.question,
    required this.options,
    required this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options.map((x) => x.toMap()).toList(),
      'explanation': explanation,
    };
  }

  factory MCQQuestion.fromMap(Map<String, dynamic> map) {
    return MCQQuestion(
      question: map['question'],
      options: List<MCQOption>.from(map['options']?.map((x) => MCQOption.fromMap(x))),
      explanation: map['explanation'] ?? '',
    );
  }
}

class UserProgress {
  final int streak;
  final DateTime? lastActiveDate;
  final int totalQuestions;
  final int correctAnswers;

  UserProgress({
    this.streak = 0,
    this.lastActiveDate,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
  });

  double get accuracy => totalQuestions == 0 ? 0 : (correctAnswers / totalQuestions) * 100;

  Map<String, dynamic> toMap() {
    return {
      'streak': streak,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
    };
  }

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      streak: map['streak'] ?? 0,
      lastActiveDate: map['lastActiveDate'] != null ? DateTime.parse(map['lastActiveDate']) : null,
      totalQuestions: map['totalQuestions'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
    );
  }
}

class Marksheet {
  final String id;
  final String topic;
  final int score;
  final int total;
  final DateTime timestamp;
  final List<dynamic> questions;
  final List<int?> userAnswers;

  Marksheet({
    required this.id,
    required this.topic,
    required this.score,
    required this.total,
    required this.timestamp,
    this.questions = const [],
    this.userAnswers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'score': score,
      'total': total,
      'timestamp': timestamp.toIso8601String(),
      'questions': questions,
      'userAnswers': userAnswers,
    };
  }

  factory Marksheet.fromMap(Map<String, dynamic> map) {
    return Marksheet(
      id: map['id'],
      topic: map['topic'],
      score: map['score'],
      total: map['total'],
      timestamp: DateTime.parse(map['timestamp']),
      questions: map['questions'] ?? [],
      userAnswers: List<int?>.from(map['userAnswers'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());
  factory Marksheet.fromJson(String source) => Marksheet.fromMap(json.decode(source));
}
