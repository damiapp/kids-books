import 'package:flutter/material.dart';
import '../models/book.dart';

/// The catalog. Bundled for now so the app works offline.
///
/// To ship new lessons WITHOUT a new APK release, move this list to a JSON
/// manifest served from Cloudflare R2 (or Supabase) and fetch it at
/// startup — access is decided by energy + subscription, not by which
/// lessons shipped inside the app, so new ones show up for everyone
/// immediately.
class BookCatalog {
  static const List<Book> books = [
    Book(
      id: 'animals',
      title: 'Animal Friends',
      subtitle: 'Animals and their names',
      coverEmoji: '🦁',
      coverColor: Color(0xFFFFE1A8),
      ageRange: '3-6',
      genres: ['Animals', 'Nature'],
      pages: [
        BookPage(emoji: '🦁', word: 'Lion', text: 'The lion is the king of the animals.', color: Color(0xFFFFE1A8)),
        BookPage(emoji: '🐘', word: 'Elephant', text: 'The elephant is big and grey.', color: Color(0xFFD6E4EA)),
        BookPage(emoji: '🦒', word: 'Giraffe', text: 'The giraffe has a long neck.', color: Color(0xFFFFF0BE)),
        BookPage(emoji: '🐧', word: 'Penguin', text: 'The penguin cannot fly, but it can swim.', color: Color(0xFFD7EBF5)),
        BookPage(emoji: '🦊', word: 'Fox', text: 'The fox has a big fluffy tail.', color: Color(0xFFFFDBC2)),
        BookPage(emoji: '🐸', word: 'Frog', text: 'The frog can jump very high.', color: Color(0xFFD8F0CE)),
      ],
    ),
    Book(
      id: 'colours',
      title: 'Colours All Around',
      subtitle: 'Learn your first colours',
      coverEmoji: '🌈',
      coverColor: Color(0xFFE6DDF2),
      ageRange: '1-3',
      genres: ['Learning', 'Colours'],
      pages: [
        BookPage(emoji: '🍎', word: 'Red', text: 'The apple is red.', color: Color(0xFFF6D3D3)),
        BookPage(emoji: '☀️', word: 'Yellow', text: 'The sun is yellow.', color: Color(0xFFFFF0BE)),
        BookPage(emoji: '🌿', word: 'Green', text: 'The leaf is green.', color: Color(0xFFD8F0CE)),
        BookPage(emoji: '💧', word: 'Blue', text: 'The water is blue.', color: Color(0xFFD7EBF5)),
        BookPage(emoji: '🍇', word: 'Purple', text: 'The grapes are purple.', color: Color(0xFFE6DDF2)),
      ],
    ),
    Book(
      id: 'numbers',
      title: 'Count to Five',
      subtitle: 'Numbers one to five',
      coverEmoji: '🔢',
      coverColor: Color(0xFFD8F0CE),
      ageRange: '2-4',
      genres: ['Learning', 'Numbers'],
      pages: [
        BookPage(emoji: '🍏', word: 'One', text: 'One green apple.', color: Color(0xFFD8F0CE)),
        BookPage(emoji: '🐟🐟', word: 'Two', text: 'Two little fish.', color: Color(0xFFD7EBF5)),
        BookPage(emoji: '🎈🎈🎈', word: 'Three', text: 'Three party balloons.', color: Color(0xFFF6D3D3)),
        BookPage(emoji: '⭐⭐⭐⭐', word: 'Four', text: 'Four shining stars.', color: Color(0xFFFFF0BE)),
        BookPage(emoji: '🌸🌸🌸🌸🌸', word: 'Five', text: 'Five pretty flowers.', color: Color(0xFFF6DCE6)),
      ],
    ),
  ];

  static Book byId(String id) => books.firstWhere((b) => b.id == id);
}

/// Display-only. The real subscription price is configured in Play Console.
const String kSubscriptionPriceLabel = '€4.99 / month';
