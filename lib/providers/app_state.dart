import 'package:flutter/material.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final AIService _ai = AIService();
  final Connectivity _connectivity = Connectivity();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _alarmTimer;
  String? _lastRungTime;

  bool _isPremium = false;
  bool _isDarkMode = false;
  UserProgress _progress = UserProgress();
  List<StudyHistoryItem> _history = [];
  int _dailyCount = 0;
  bool _isOffline = false;
  String? _userName;
  String? _userPhoto;
  List<Marksheet> _marksheets = [];

  List<StudyPlan> _studyPlans = [];
  List<Reminder> _reminders = [];

  bool get isPremium => _isPremium;
  bool get isDarkMode => _isDarkMode;
  List<StudyPlan> get studyPlans => _studyPlans;
  List<Reminder> get reminders => _reminders;
  UserProgress get progress => _progress;
  List<StudyHistoryItem> get history => _history;
  int get dailyCount => _dailyCount;
  bool get canAskQuestion => _isPremium || _dailyCount < 15;
  bool get isOffline => _isOffline;
  String? get userName => _userName;
  String? get userPhoto => _userPhoto;
  List<Marksheet> get marksheets => _marksheets;

  AppState() {
    _loadInitialData();
    _monitorConnectivity();
    _startAlarmSystem();
  }

  void _startAlarmSystem() {
    _alarmTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkAlarms();
    });
  }

  void _checkAlarms() {
    final now = DateTime.now();
    final String currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    
    // Convert 12h format from UI to 24h for comparison
    // Simple logic: Reminders/Plans store time as "HH:MM AM/PM"
    
    if (_lastRungTime == currentTime) return;

    bool shouldRing = false;

    for (var reminder in _reminders) {
      if (reminder.isActive && _isTimeMatch(reminder.time, now)) {
        shouldRing = true;
        break;
      }
    }

    if (!shouldRing) {
      for (var plan in _studyPlans) {
        if (!plan.isCompleted && _isTimeMatch(plan.time, now)) {
          shouldRing = true;
          break;
        }
      }
    }

    if (shouldRing) {
      _ring();
      _lastRungTime = currentTime;
    }
  }

  bool _isTimeMatch(String timeStr, DateTime now) {
    try {
      // timeStr is like "09:00 AM"
      final parts = timeStr.toUpperCase().split(' ');
      if (parts.length < 2) return false;
      
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      String ampm = parts[1];

      if (ampm == "PM" && hour < 12) hour += 12;
      if (ampm == "AM" && hour == 12) hour = 0;

      return now.hour == hour && now.minute == minute;
    } catch (e) {
      return false;
    }
  }

  void _ring() {
    _audioPlayer.play(UrlSource('https://actions.google.com/sounds/v1/alarms/alarm_clock_short.ogg'));
  }

  void _monitorConnectivity() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _isOffline = results.contains(ConnectivityResult.none);
      notifyListeners();
    });
  }

  Future<void> _loadInitialData() async {
    _isPremium = await _storage.isPremium();
    _isDarkMode = await _storage.getDarkMode();
    _progress = await _storage.getProgress();
    _history = await _storage.getHistory();
    _dailyCount = await _storage.getDailyQuestionCount();
    _userName = await _storage.getUserName();
    _userPhoto = await _storage.getUserPhoto();
    _marksheets = await _storage.getMarksheets();
    _studyPlans = await _storage.getStudyPlans();
    _reminders = await _storage.getReminders();
    notifyListeners();
  }

  Future<void> addStudyPlan(StudyPlan plan) async {
    _studyPlans.add(plan);
    await _storage.saveStudyPlans(_studyPlans);
    notifyListeners();
  }

  Future<void> updateStudyPlan(StudyPlan plan) async {
    final index = _studyPlans.indexWhere((e) => e.id == plan.id);
    if (index != -1) {
      _studyPlans[index] = plan;
      await _storage.saveStudyPlans(_studyPlans);
      notifyListeners();
    }
  }

  Future<void> removeStudyPlan(String id) async {
    _studyPlans.removeWhere((e) => e.id == id);
    await _storage.saveStudyPlans(_studyPlans);
    notifyListeners();
  }

  Future<void> addReminder(Reminder reminder) async {
    _reminders.add(reminder);
    await _storage.saveReminders(_reminders);
    notifyListeners();
  }

  Future<void> updateReminder(Reminder reminder) async {
    final index = _reminders.indexWhere((e) => e.id == reminder.id);
    if (index != -1) {
      _reminders[index] = reminder;
      await _storage.saveReminders(_reminders);
      notifyListeners();
    }
  }

  Future<void> removeReminder(String id) async {
    _reminders.removeWhere((e) => e.id == id);
    await _storage.saveReminders(_reminders);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _storage.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> setProfile(String name, String? base64Photo) async {
    _userName = name;
    await _storage.setUserName(name);
    
    if (base64Photo != null) {
      _userPhoto = base64Photo;
      await _storage.setUserPhoto(base64Photo);
    }
    notifyListeners();
  }

  Future<void> togglePremium() async {
    _isPremium = !_isPremium;
    await _storage.setPremium(_isPremium);
    notifyListeners();
  }

  Future<String> askQuestion(String prompt, {bool detailed = false}) async {
    if (!canAskQuestion) {
      throw Exception("Daily limit reached. Upgrade to Premium for unlimited questions!");
    }

    final answer = await _ai.askQuestion(prompt, detailed: detailed);
    
    final item = StudyHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: prompt,
      answer: answer,
      timestamp: DateTime.now(),
      isDetailed: detailed,
    );

    _history.insert(0, item);
    if (!_isPremium && _history.length > 20) {
      _history.removeLast();
    }
    
    await _storage.saveHistoryItem(item, maxItems: _isPremium ? 1000 : 20);
    await _storage.incrementDailyCount();
    _dailyCount = await _storage.getDailyQuestionCount();
    
    notifyListeners();
    return answer;
  }

  Future<void> updateQuizResult(int correctCount, int totalCount) async {
    for (int i = 0; i < totalCount; i++) {
      await _storage.updateStreakAndCount(i < correctCount);
    }
    _progress = await _storage.getProgress();
    notifyListeners();
  }

  Future<void> saveMarksheet(String topic, int score, int total, List<dynamic> questions, List<int?> userAnswers) async {
    final item = Marksheet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      topic: topic,
      score: score,
      total: total,
      timestamp: DateTime.now(),
      questions: questions,
      userAnswers: userAnswers,
    );

    _marksheets.insert(0, item);
    if (!_isPremium && _marksheets.length > 5) {
      _marksheets.removeLast();
    }
    
    await _storage.saveMarksheet(item, maxItems: _isPremium ? 1000 : 5);
    notifyListeners();
  }
}
