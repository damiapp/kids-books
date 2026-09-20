import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks per-lesson progress (last step reached, completion) and
/// favorites. Local only — same SharedPreferences-backed pattern as
/// DemoEntitlementService.
class ProgressService extends ChangeNotifier {
  static const _stepKey = 'lesson_last_step';
  static const _completedKey = 'lesson_completed_ids';
  static const _favoritesKey = 'lesson_favorite_ids';

  final Map<String, int> _lastStep = {};
  final Set<String> _completed = {};
  final Set<String> _favorites = {};

  int? lastStepFor(String lessonId) => _lastStep[lessonId];

  bool isCompleted(String lessonId) => _completed.contains(lessonId);

  bool isFavorite(String lessonId) => _favorites.contains(lessonId);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawStep = prefs.getString(_stepKey);
    if (rawStep != null) {
      final decoded = (jsonDecode(rawStep) as Map).cast<String, dynamic>();
      _lastStep
        ..clear()
        ..addAll(decoded.map((id, step) => MapEntry(id, step as int)));
    }
    final rawCompleted = prefs.getStringList(_completedKey);
    if (rawCompleted != null) {
      _completed
        ..clear()
        ..addAll(rawCompleted);
    }
    final rawFavorites = prefs.getStringList(_favoritesKey);
    if (rawFavorites != null) {
      _favorites
        ..clear()
        ..addAll(rawFavorites);
    }
    notifyListeners();
  }

  Future<void> setLastStep(String lessonId, int stepIndex) async {
    if (_lastStep[lessonId] == stepIndex) return;
    _lastStep[lessonId] = stepIndex;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stepKey, jsonEncode(_lastStep));
    notifyListeners();
  }

  Future<void> markCompleted(String lessonId) async {
    if (!_completed.add(lessonId)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_completedKey, _completed.toList());
    notifyListeners();
  }

  Future<void> toggleFavorite(String lessonId) async {
    if (!_favorites.remove(lessonId)) {
      _favorites.add(lessonId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, _favorites.toList());
    notifyListeners();
  }
}
