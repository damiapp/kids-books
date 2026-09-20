import 'package:flutter/material.dart';

/// One word a lesson teaches: a picture, the word itself, and a simple
/// sentence using it. Each becomes a "learn" step, immediately followed
/// by a "practice" step (tap-the-match) in the lesson player.
/// [emoji] is placeholder art — swap for a bundled asset or a Cloudflare R2
/// image URL when you have real illustrations.
class LessonWord {
  const LessonWord({
    required this.emoji,
    required this.word,
    required this.text,
    required this.color,
  });

  final String emoji;
  final String word;
  final String text;
  final Color color;
}

/// A single lesson on the learning path.
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.coverEmoji,
    required this.coverColor,
    required this.words,
    required this.ageRange,
    required this.genres,
  });

  final String id;
  final String title;
  final String subtitle;
  final String coverEmoji;
  final Color coverColor;

  /// Recommended learner age, e.g. "1-3", "3-6".
  final String ageRange;

  /// e.g. ["Animals", "Nature"]. A lesson can belong to more than one.
  final List<String> genres;

  final List<LessonWord> words;
}
