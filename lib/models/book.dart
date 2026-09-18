import 'package:flutter/material.dart';

/// One page of a book: a picture, a word, and a simple line of text. Each
/// page becomes a "learn" step, immediately followed by a "practice" step
/// (tap-the-match quiz) in the lesson player.
/// [emoji] is placeholder art — swap for a bundled asset or a Cloudflare R2
/// image URL when you have real illustrations.
class BookPage {
  const BookPage({
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

/// A single lesson (built from what used to be a "book") in the catalog.
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.coverEmoji,
    required this.coverColor,
    required this.pages,
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

  final List<BookPage> pages;
}
