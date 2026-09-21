import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks per-lesson progress: the last step reached, and whether the
/// lesson is finished. Local only — same SharedPreferences-backed
/// pattern as DemoEntitlementService.
class ProgressService extends ChangeNotifier {
  static const _stepKey = 'lesson_last_step';
  static const _completedKey = 'lesson_completed_ids';

  final Map<String, int> _lastStep = {};
  final Set<String> _completed = {};

  int? lastStepFor(String lessonId) => _lastStep[lessonId];

  bool isCompleted(String lessonId) => _completed.contains(lessonId);

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
}
