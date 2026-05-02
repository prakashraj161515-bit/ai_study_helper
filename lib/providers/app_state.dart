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
  Timer? _checkTimer;
  Timer? _alarmStopTimer;
  String? _lastRungTime;
  bool _isAlarmRinging = false;
  String _alarmLabel = '';

  bool _isPremium = false;
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
  bool get isAlarmRinging => _isAlarmRinging;
  String get alarmLabel => _alarmLabel;
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

  // ─── Alarm System ──────────────────────────────────────────────
  void _startAlarmSystem() {
    _checkTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkAlarms());
  }

  void _checkAlarms() {
    if (_isAlarmRinging) return;
    final now = DateTime.now();
    final currentKey = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    if (_lastRungTime == currentKey) return;

    String? label;

    for (var r in _reminders) {
      if (r.isActive && _isTimeMatch(r.time, now)) {
        label = r.title;
        break;
      }
    }
    if (label == null) {
      for (var p in _studyPlans) {
        if (!p.isCompleted && _isTimeMatch(p.time, now)) {
          label = '${p.subject} – ${p.topic}';
          break;
        }
      }
    }

    if (label != null) {
      _lastRungTime = currentKey;
      _startRinging(label);
    }
  }

  bool _isTimeMatch(String timeStr, DateTime now) {
    try {
      // Supports "HH:MM AM/PM" or "HH:MM" (24h)
      final upper = timeStr.trim().toUpperCase();
      final hasMeridiem = upper.contains('AM') || upper.contains('PM');
      String timePart = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = timePart.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      if (hasMeridiem) {
        final isPM = upper.contains('PM');
        if (isPM && hour < 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
      }

      return now.hour == hour && now.minute == minute;
    } catch (_) {
      return false;
    }
  }

  void _startRinging(String label) {
    _isAlarmRinging = true;
    _alarmLabel = label;
    notifyListeners();

    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.play(UrlSource(
      'https://actions.google.com/sounds/v1/alarms/alarm_clock.ogg',
    ));

    // Auto-stop after 1 minute
    _alarmStopTimer = Timer(const Duration(minutes: 1), stopAlarm);
  }

  void stopAlarm() {
    _alarmStopTimer?.cancel();
    _alarmStopTimer = null;
    _audioPlayer.stop();
    _isAlarmRinging = false;
    _alarmLabel = '';
    notifyListeners();
  }

  // ─── Connectivity ───────────────────────────────────────────────
  void _monitorConnectivity() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _isOffline = results.contains(ConnectivityResult.none);
      notifyListeners();
    });
  }

  // ─── Load Data ──────────────────────────────────────────────────
  Future<void> _loadInitialData() async {
    _isPremium = await _storage.isPremium();
    await _storage.recordLoginProgress();
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

  // ─── Study Plans ────────────────────────────────────────────────
  Future<void> addStudyPlan(StudyPlan plan) async {
    _studyPlans.add(plan);
    await _storage.saveStudyPlans(_studyPlans);
    notifyListeners();
  }

  Future<void> updateStudyPlan(StudyPlan plan) async {
    final i = _studyPlans.indexWhere((e) => e.id == plan.id);
    if (i != -1) {
      _studyPlans[i] = plan;
      await _storage.saveStudyPlans(_studyPlans);
      notifyListeners();
    }
  }

  Future<void> removeStudyPlan(String id) async {
    _studyPlans.removeWhere((e) => e.id == id);
    await _storage.saveStudyPlans(_studyPlans);
    notifyListeners();
  }

  // ─── Reminders ──────────────────────────────────────────────────
  Future<void> addReminder(Reminder reminder) async {
    _reminders.add(reminder);
    await _storage.saveReminders(_reminders);
    notifyListeners();
  }

  Future<void> updateReminder(Reminder reminder) async {
    final i = _reminders.indexWhere((e) => e.id == reminder.id);
    if (i != -1) {
      _reminders[i] = reminder;
      await _storage.saveReminders(_reminders);
      notifyListeners();
    }
  }

  Future<void> removeReminder(String id) async {
    _reminders.removeWhere((e) => e.id == id);
    await _storage.saveReminders(_reminders);
    notifyListeners();
  }

  // ─── Profile ────────────────────────────────────────────────────
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

  // ─── AI / Questions ─────────────────────────────────────────────
  Future<String> askQuestion(String prompt, {bool detailed = false}) async {
    if (!canAskQuestion) {
      throw Exception('Daily limit reached. Upgrade to Premium for unlimited questions!');
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
    if (!_isPremium && _history.length > 20) _history.removeLast();

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

  Future<void> saveMarksheet(String topic, int score, int total,
      List<dynamic> questions, List<int?> userAnswers) async {
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
    if (!_isPremium && _marksheets.length > 5) _marksheets.removeLast();

    await _storage.saveMarksheet(item, maxItems: _isPremium ? 1000 : 5);
    notifyListeners();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _alarmStopTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
