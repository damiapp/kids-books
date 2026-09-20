import 'package:flutter/material.dart';
import '../models/lesson.dart';

/// One section of the learning path: a banner plus the lessons under it,
/// in the order they unlock.
class LessonUnit {
  const LessonUnit({
    required this.section,
    required this.title,
    required this.color,
    required this.lessonIds,
  });

  /// Small label above the title, e.g. "SECTION 1, UNIT 1".
  final String section;
  final String title;
  final Color color;
  final List<String> lessonIds;
}

/// The catalog. Bundled for now so the app works offline.
///
/// To ship new lessons WITHOUT a new APK release, move this list to a JSON
/// manifest served from Cloudflare R2 (or Supabase) and fetch it at
/// startup — access is decided by energy + subscription, not by which
/// lessons shipped inside the app, so new ones show up for everyone
/// immediately.
class LessonCatalog {
  /// The path, top to bottom. A lesson unlocks when the one before it is
  /// finished, so order here is what gates progression.
  static const List<LessonUnit> units = [
    LessonUnit(
      section: 'SECTION 1, UNIT 1',
      title: 'First words',
      color: Color(0xFF3AA7A0),
      lessonIds: ['colours', 'numbers'],
    ),
    LessonUnit(
      section: 'SECTION 1, UNIT 2',
      title: 'Animals & nature',
      color: Color(0xFFE08D3C),
      lessonIds: ['animals'],
    ),
  ];

  static const List<Lesson> lessons = [
    Lesson(
      id: 'animals',
      title: 'Animal Friends',
      subtitle: 'Animals and their names',
      coverEmoji: '🦁',
      coverColor: Color(0xFFFFE1A8),
      ageRange: '3-6',
      genres: ['Animals', 'Nature'],
      words: [
        LessonWord(emoji: '🦁', word: 'Lion', text: 'The lion is the king of the animals.', color: Color(0xFFFFE1A8)),
        LessonWord(emoji: '🐘', word: 'Elephant', text: 'The elephant is big and grey.', color: Color(0xFFD6E4EA)),
        LessonWord(emoji: '🦒', word: 'Giraffe', text: 'The giraffe has a long neck.', color: Color(0xFFFFF0BE)),
        LessonWord(emoji: '🐧', word: 'Penguin', text: 'The penguin cannot fly, but it can swim.', color: Color(0xFFD7EBF5)),
        LessonWord(emoji: '🦊', word: 'Fox', text: 'The fox has a big fluffy tail.', color: Color(0xFFFFDBC2)),
        LessonWord(emoji: '🐸', word: 'Frog', text: 'The frog can jump very high.', color: Color(0xFFD8F0CE)),
      ],
    ),
    Lesson(
      id: 'colours',
      title: 'Colours All Around',
      subtitle: 'Learn your first colours',
      coverEmoji: '🌈',
      coverColor: Color(0xFFE6DDF2),
      ageRange: '1-3',
      genres: ['Learning', 'Colours'],
      words: [
        LessonWord(emoji: '🍎', word: 'Red', text: 'The apple is red.', color: Color(0xFFF6D3D3)),
        LessonWord(emoji: '☀️', word: 'Yellow', text: 'The sun is yellow.', color: Color(0xFFFFF0BE)),
        LessonWord(emoji: '🌿', word: 'Green', text: 'The leaf is green.', color: Color(0xFFD8F0CE)),
        LessonWord(emoji: '💧', word: 'Blue', text: 'The water is blue.', color: Color(0xFFD7EBF5)),
        LessonWord(emoji: '🍇', word: 'Purple', text: 'The grapes are purple.', color: Color(0xFFE6DDF2)),
      ],
    ),
    Lesson(
      id: 'numbers',
      title: 'Count to Five',
      subtitle: 'Numbers one to five',
      coverEmoji: '🔢',
      coverColor: Color(0xFFD8F0CE),
      ageRange: '2-4',
      genres: ['Learning', 'Numbers'],
      words: [
        LessonWord(emoji: '🍏', word: 'One', text: 'One green apple.', color: Color(0xFFD8F0CE)),
        LessonWord(emoji: '🐟🐟', word: 'Two', text: 'Two little fish.', color: Color(0xFFD7EBF5)),
        LessonWord(emoji: '🎈🎈🎈', word: 'Three', text: 'Three party balloons.', color: Color(0xFFF6D3D3)),
        LessonWord(emoji: '⭐⭐⭐⭐', word: 'Four', text: 'Four shining stars.', color: Color(0xFFFFF0BE)),
        LessonWord(emoji: '🌸🌸🌸🌸🌸', word: 'Five', text: 'Five pretty flowers.', color: Color(0xFFF6DCE6)),
      ],
    ),
  ];

  static Lesson byId(String id) => lessons.firstWhere((l) => l.id == id);
}

/// Display-only. The real subscription price is configured in Play Console.
const String kSubscriptionPriceLabel = '€4.99 / month';
