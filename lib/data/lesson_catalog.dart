import 'package:flutter/material.dart';

import '../models/lesson.dart';

/// One section of the learning path: a banner plus the lessons under it,
/// in the order they unlock.
class LessonUnit {
  const LessonUnit({
    required this.id,
    required this.section,
    required this.title,
    required this.color,
    required this.lessonIds,
  });

  /// Stable id, and the stem of [reviewId].
  final String id;

  /// Small label above the title, e.g. "SECTION 1, UNIT 1".
  final String section;
  final String title;
  final Color color;
  final List<String> lessonIds;

  /// How the unit's review is tracked in ProgressService. The review is
  /// built at runtime rather than sitting in the catalog, so its id has
  /// to come from somewhere both the path and the profile can reach.
  String get reviewId => 'review_$id';

  /// Lessons plus the review — the unit's real length, which is what
  /// both the path banner and the profile count against.
  int get stepCount => lessonIds.length + 1;

  factory LessonUnit.fromJson(Map<String, dynamic> json) => LessonUnit(
        id: json['id'] as String,
        section: json['section'] as String,
        title: json['title'] as String,
        color: colorFromHex(json['color'] as String),
        lessonIds: [for (final id in json['lessonIds'] as List) id as String],
      );
}

/// The content, loaded at startup by CatalogService rather than compiled
/// in — see README §4. Everything below reads from whichever version
/// that service settled on: the one bundled in the APK, or a newer one
/// fetched earlier and cached.
///
/// It stays a static holder so the screens don't have to thread a
/// service through the tree for something that never changes while the
/// app is running.
class LessonCatalog {
  LessonCatalog._();

  static List<LessonUnit> _units = const [];
  static List<Lesson> _lessons = const [];
  static int _version = 0;

  /// The path, top to bottom. A lesson unlocks when the one before it is
  /// finished, so order here is what gates progression.
  static List<LessonUnit> get units => _units;

  static List<Lesson> get lessons => _lessons;

  /// Which catalog version is live. Bumped by whoever edits the JSON.
  static int get version => _version;

  static bool get isLoaded => _lessons.isNotEmpty;

  /// Replaces the live catalog with [json], which must already be
  /// valid — [parse] is what decides that.
  static void load(Map<String, dynamic> json) {
    final parsed = parse(json);
    _lessons = parsed.lessons;
    _units = parsed.units;
    _version = parsed.version;
  }

  /// Reads a catalog without touching the live one, throwing if it
  /// would leave the path broken. A unit pointing at a lesson that
  /// isn't there would crash on the first build of the map, and a
  /// remote file is exactly where that mistake comes from.
  ///
  /// Separate from [load] so a downloaded catalog can be checked while
  /// the app carries on running the one it started with.
  static ({List<LessonUnit> units, List<Lesson> lessons, int version}) parse(
      Map<String, dynamic> json) {
    final lessons = [
      for (final lesson in json['lessons'] as List)
        Lesson.fromJson((lesson as Map).cast<String, dynamic>()),
    ];
    final units = [
      for (final unit in json['units'] as List)
        LessonUnit.fromJson((unit as Map).cast<String, dynamic>()),
    ];

    final ids = {for (final lesson in lessons) lesson.id};
    if (lessons.isEmpty || units.isEmpty) {
      throw const FormatException('catalog has no lessons or no units');
    }
    for (final unit in units) {
      for (final id in unit.lessonIds) {
        if (!ids.contains(id)) {
          throw FormatException('unit ${unit.id} wants missing lesson $id');
        }
      }
    }
    // A practice step needs two wrong answers to sit beside the right
    // one, so a lesson of fewer than three words has no question to ask.
    for (final lesson in lessons) {
      if (lesson.words.length < 3) {
        throw FormatException('lesson ${lesson.id} has under three words');
      }
    }

    return (units: units, lessons: lessons, version: json['version'] as int? ?? 0);
  }

  static Lesson byId(String id) => lessons.firstWhere((l) => l.id == id);

  /// Every distinct word in the catalog, in teaching order.
  static List<LessonWord> get allWords {
    final seen = <String>{};
    return [
      for (final lesson in lessons)
        for (final word in lesson.words)
          if (seen.add(word.word)) word,
    ];
  }

  /// Looks a word up by its text. Null if it isn't in the catalog any
  /// more — a saved miss can outlive the lesson that taught it, and now
  /// that lessons arrive over the network, outlive the whole catalog.
  static LessonWord? wordByText(String text) {
    for (final word in allWords) {
      if (word.word == text) return word;
    }
    return null;
  }

  /// A drill over [words] — the same listen-and-tap loop as a lesson,
  /// built on the fly from whatever is being practised. Null when fewer
  /// than two of them are still in the catalog, since a tap-the-match
  /// question needs something to choose between.
  static Lesson? practiceLesson(List<String> words) {
    final found = [
      for (final text in words)
        if (wordByText(text) case final word?) word,
    ];
    if (found.length < 2) return null;
    return Lesson(
      id: 'practice_tricky',
      title: 'Tricky words',
      subtitle: 'The ones worth another go',
      coverEmoji: '🎯',
      coverColor: const Color(0xFFFFDBC2),
      words: found.take(6).toList(),
    );
  }
}

/// Display-only. The real subscription price is configured in Play Console.
const String kSubscriptionPriceLabel = '€4.99 / month';
