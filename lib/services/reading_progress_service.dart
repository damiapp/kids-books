import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks per-lesson progress (last step reached, completion) and
/// favorites. Local only — same SharedPreferences-backed pattern as
/// DemoEntitlementService.
class ReadingProgressService extends ChangeNotifier {
  static const _stepKey = 'lesson_last_step';
  static const _completedKey = 'lesson_completed_ids';
  static const _favoritesKey = 'favorite_book_ids';

  final Map<String, int> _lastStep = {};
  final Set<String> _completed = {};
  final Set<String> _favorites = {};

  int? lastStepFor(String bookId) => _lastStep[bookId];

  bool isCompleted(String bookId) => _completed.contains(bookId);

  bool isFavorite(String bookId) => _favorites.contains(bookId);

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

  Future<void> setLastStep(String bookId, int stepIndex) async {
    if (_lastStep[bookId] == stepIndex) return;
    _lastStep[bookId] = stepIndex;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stepKey, jsonEncode(_lastStep));
    notifyListeners();
  }

  Future<void> markCompleted(String bookId) async {
    if (!_completed.add(bookId)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_completedKey, _completed.toList());
    notifyListeners();
  }

  Future<void> toggleFavorite(String bookId) async {
    if (!_favorites.remove(bookId)) {
      _favorites.add(bookId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, _favorites.toList());
    notifyListeners();
  }
}
