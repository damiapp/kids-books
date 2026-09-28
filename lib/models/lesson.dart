import 'package:flutter/material.dart';

/// Parses the `#RRGGBB` strings the catalog JSON uses. Opaque always —
/// nothing in the catalog is translucent, and a bad value would
/// otherwise fail silently as an invisible card.
Color colorFromHex(String hex) {
  final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
  return Color(0xFF000000 | value);
}

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

  factory LessonWord.fromJson(Map<String, dynamic> json) => LessonWord(
        emoji: json['emoji'] as String,
        word: json['word'] as String,
        text: json['text'] as String,
        color: colorFromHex(json['color'] as String),
      );
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

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        coverEmoji: json['coverEmoji'] as String,
        coverColor: colorFromHex(json['coverColor'] as String),
        words: [
          for (final word in json['words'] as List)
            LessonWord.fromJson((word as Map).cast<String, dynamic>()),
        ],
      );
}
