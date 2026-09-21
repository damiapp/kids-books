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
  });

  final String id;
  final String title;
  final String subtitle;
  final String coverEmoji;
  final Color coverColor;

  final List<LessonWord> words;
}
