import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const String _keyHistory = 'study_history';
  static const String _keyProgress = 'user_progress';
  static const String _keyPremium = 'is_premium';
  static const String _keyDailyCount = 'daily_question_count';
  static const String _keyLastQuestionDate = 'last_question_date';
  static const String _keyUserName = 'user_name';
  static const String _keyUserPhoto = 'user_photo';

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }

  Future<String?> getUserPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserPhoto);
  }

  Future<void> setUserPhoto(String base64Image) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserPhoto, base64Image);
  }

  Future<void> saveHistoryItem(StudyHistoryItem item, {int maxItems = 20}) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.insert(0, item);
    
    if (history.length > maxItems && !(await isPremium())) {
      history.removeRange(maxItems, history.length);
    }
    
    final data = history.map((e) => e.toJson()).toList();
    await prefs.setStringList(_keyHistory, data);
  }

  Future<List<StudyHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_keyHistory) ?? [];
    return data.map((e) => StudyHistoryItem.fromJson(e)).toList();
  }

  Future<UserProgress> getProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyProgress);
    if (data == null) return UserProgress();
    return UserProgress.fromMap(jsonDecode(data));
  }

  Future<void> saveProgress(UserProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProgress, jsonEncode(progress.toMap()));
  }

  Future<void> updateStreakAndCount(bool isCorrect) async {
    final progress = await getProgress();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int newStreak = progress.streak;
    DateTime? lastActive = progress.lastActiveDate;
    
    if (lastActive != null) {
      final lastDate = DateTime(lastActive.year, lastActive.month, lastActive.day);
      final difference = today.difference(lastDate).inDays;
      
      if (difference == 1) {
        newStreak++;
      } else if (difference > 1) {
        newStreak = 1;
      }
      // If difference == 0, streak remains same (already counted today)
    } else {
      newStreak = 1;
    }

    final newProgress = UserProgress(
      streak: newStreak,
      lastActiveDate: today,
      totalQuestions: progress.totalQuestions + 1,
      correctAnswers: progress.correctAnswers + (isCorrect ? 1 : 0),
    );
    
    await saveProgress(newProgress);
  }

  Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPremium) ?? false;
  }

  Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPremium, value);
  }

  Future<int> getDailyQuestionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyLastQuestionDate);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    if (lastDate != today) {
      await prefs.setString(_keyLastQuestionDate, today);
      await prefs.setInt(_keyDailyCount, 0);
      return 0;
    }
    return prefs.getInt(_keyDailyCount) ?? 0;
  }

  Future<void> incrementDailyCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getDailyQuestionCount();
    await prefs.setInt(_keyDailyCount, current + 1);
  }
}
