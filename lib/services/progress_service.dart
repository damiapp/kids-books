import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Everything the app remembers about a learner: how far into each lesson
/// they got, which lessons are finished, how many days in a row they've
/// practised, and which words keep tripping them up.
///
/// It all lives here rather than in separate services because it's all
/// written at the same two moments — finishing a lesson, and missing a
/// word — and because this is the one service already passed to every
/// screen that would need it.
///
/// Local only, same SharedPreferences-backed pattern as
/// DemoEntitlementService.
class ProgressService extends ChangeNotifier {
  static const _stepKey = 'lesson_last_step';
  static const _completedKey = 'lesson_completed_ids';
  static const _missesKey = 'word_misses';
  static const _streakKey = 'streak_days';
  static const _longestStreakKey = 'streak_longest';
  static const _lastActiveDayKey = 'streak_last_day';
  static const _todayCountKey = 'streak_today_count';

  /// Lessons a day, for the daily goal. Two is about ten minutes for a
  /// preschooler — short enough to hit on a bad day, which is the only
  /// way a streak means anything.
  static const int dailyGoal = 2;

  final Map<String, int> _lastStep = {};
  final Set<String> _completed = {};
  final Map<String, int> _misses = {};

  int _streak = 0;
  int _longestStreak = 0;
  String _lastActiveDay = '';
  int _todayCount = 0;

  int? lastStepFor(String lessonId) => _lastStep[lessonId];

  bool isCompleted(String lessonId) => _completed.contains(lessonId);

  /// How many times this word has been answered wrong, ever.
  int missesFor(String word) => _misses[word] ?? 0;

  /// Words missed at least once, worst first. Ties keep a stable order so
  /// a practice drill built from this doesn't reshuffle between builds.
  List<String> get trickiestWords {
    final entries = _misses.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return [for (final e in entries) e.key];
  }

  /// Days in a row with at least one lesson finished. Today doesn't count
  /// until a lesson is finished, so it reads 0 on a fresh day — the
  /// number only ever goes up by doing something.
  int get streak => _isCurrent(_lastActiveDay) ? _streak : 0;

  int get longestStreak => _longestStreak;

  /// Lessons finished today, replays included — the point of the goal is
  /// showing up, not reaching new material.
  int get lessonsToday => _lastActiveDay == _today ? _todayCount : 0;

  bool get dailyGoalMet => lessonsToday >= dailyGoal;

  static String _dayStamp(DateTime d) => '${d.year}-${d.month}-${d.day}';

  static String get _today => _dayStamp(DateTime.now());

  static String get _yesterday =>
      _dayStamp(DateTime.now().subtract(const Duration(days: 1)));

  /// A streak is still alive if its last day was today or yesterday.
  static bool _isCurrent(String day) => day == _today || day == _yesterday;

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
    final rawMisses = prefs.getString(_missesKey);
    if (rawMisses != null) {
      final decoded = (jsonDecode(rawMisses) as Map).cast<String, dynamic>();
      _misses
        ..clear()
        ..addAll(decoded.map((word, n) => MapEntry(word, n as int)));
    }
    _streak = prefs.getInt(_streakKey) ?? 0;
    _longestStreak = prefs.getInt(_longestStreakKey) ?? 0;
    _lastActiveDay = prefs.getString(_lastActiveDayKey) ?? '';
    _todayCount = prefs.getInt(_todayCountKey) ?? 0;
    notifyListeners();
  }

  Future<void> setLastStep(String lessonId, int stepIndex) async {
    if (_lastStep[lessonId] == stepIndex) return;
    _lastStep[lessonId] = stepIndex;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stepKey, jsonEncode(_lastStep));
    notifyListeners();
  }

  /// Called when a lesson is played to the end. Replaying one already
  /// finished still counts as practising today — it just doesn't add to
  /// the set of lessons completed.
  Future<void> markCompleted(String lessonId) async {
    _completed.add(lessonId);
    _recordActivity();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_completedKey, _completed.toList());
    await _persistStreak(prefs);
    notifyListeners();
  }

  /// Rolls the streak forward. Yesterday continues it, an older day (or
  /// none) starts a new one, and a second lesson the same day only adds
  /// to today's count.
  void _recordActivity() {
    final today = _today;
    if (_lastActiveDay == today) {
      _todayCount++;
      return;
    }
    _streak = _lastActiveDay == _yesterday ? _streak + 1 : 1;
    _longestStreak = _streak > _longestStreak ? _streak : _longestStreak;
    _lastActiveDay = today;
    _todayCount = 1;
  }

  Future<void> _persistStreak(SharedPreferences prefs) async {
    await prefs.setInt(_streakKey, _streak);
    await prefs.setInt(_longestStreakKey, _longestStreak);
    await prefs.setString(_lastActiveDayKey, _lastActiveDay);
    await prefs.setInt(_todayCountKey, _todayCount);
  }

  /// A wrong answer on [word]. This is what makes reviews and the
  /// practice drill spend their time where it's needed.
  Future<void> recordMiss(String word) async {
    _misses[word] = (_misses[word] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_missesKey, jsonEncode(_misses));
    notifyListeners();
  }

  /// Clears a word once it's been answered right in a practice drill, so
  /// "tricky words" empties out as they're learned rather than becoming
  /// a permanent record of every early mistake.
  Future<void> forgiveMiss(String word) async {
    if (_misses.remove(word) == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_missesKey, jsonEncode(_misses));
    notifyListeners();
  }
}
