import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final AIService _ai = AIService();
  final Connectivity _connectivity = Connectivity();

  bool _isPremium = true;
  UserProgress _progress = UserProgress();
  List<StudyHistoryItem> _history = [];
  int _dailyCount = 0;
  bool _isOffline = false;
  String? _userName;
  String? _userPhoto;
  List<Marksheet> _marksheets = [];

  bool get isPremium => true;
  UserProgress get progress => _progress;
  List<StudyHistoryItem> get history => _history;
  int get dailyCount => _dailyCount;
  bool get canAskQuestion => true;
  bool get isOffline => _isOffline;
  String? get userName => _userName;
  String? get userPhoto => _userPhoto;
  List<Marksheet> get marksheets => _marksheets;

  AppState() {
    _loadInitialData();
    _monitorConnectivity();
  }

  void _monitorConnectivity() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _isOffline = results.contains(ConnectivityResult.none);
      notifyListeners();
    });
  }

  Future<void> _loadInitialData() async {
    _isPremium = true; // Always premium
    _progress = await _storage.getProgress();
    _history = await _storage.getHistory();
    _dailyCount = await _storage.getDailyQuestionCount();
    _userName = await _storage.getUserName();
    _userPhoto = await _storage.getUserPhoto();
    _marksheets = await _storage.getMarksheets();
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
    // No-op or keep for UI consistency but effectively does nothing
    notifyListeners();
  }

  Future<String> askQuestion(String prompt, {bool detailed = false}) async {
    // Unlimited questions
    final answer = await _ai.askQuestion(prompt, detailed: detailed);
    
    final item = StudyHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: prompt,
      answer: answer,
      timestamp: DateTime.now(),
      isDetailed: detailed,
    );

    _history.insert(0, item);
    
    await _storage.saveHistoryItem(item, maxItems: 1000);
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

  Future<void> saveMarksheet(String topic, int score, int total) async {
    final item = Marksheet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      topic: topic,
      score: score,
      total: total,
      timestamp: DateTime.now(),
    );

    _marksheets.insert(0, item);
    
    await _storage.saveMarksheet(item, maxItems: 1000);
    notifyListeners();
  }
}
