import 'package:flutter/material.dart';

/// One page of a book: a picture, a word, and a simple line of text.
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

/// A single book in the catalog.
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.coverEmoji,
    required this.coverColor,
    required this.playProductId,
    required this.priceLabel,
    required this.pages,
    required this.ageRange,
    required this.genres,
    this.previewPages = 2,
  });

  final String id;
  final String title;
  final String subtitle;
  final String coverEmoji;
  final Color coverColor;

  /// Recommended reader age, e.g. "1-3", "3-6".
  final String ageRange;

  /// e.g. ["Animals", "Nature"]. A book can belong to more than one.
  final List<String> genres;

  /// The one-time (non-consumable) product id you create in Google Play Console
  /// for buying this book on its own.
  final String playProductId;

  /// Display-only price for the demo. Real prices come from the store.
  final String priceLabel;

  final List<BookPage> pages;

  /// How many pages anyone can read for free before the paywall.
  final int previewPages;
}
