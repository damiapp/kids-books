import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks per-book reading progress (last page opened) and favorites.
/// Local only — same SharedPreferences-backed pattern as
/// DemoEntitlementService.
class ReadingProgressService extends ChangeNotifier {
  static const _progressKey = 'reading_progress';
  static const _favoritesKey = 'favorite_book_ids';

  final Map<String, int> _lastPage = {};
  final Set<String> _favorites = {};

  int? lastPageFor(String bookId) => _lastPage[bookId];

  bool isFavorite(String bookId) => _favorites.contains(bookId);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawProgress = prefs.getString(_progressKey);
    if (rawProgress != null) {
      final decoded = (jsonDecode(rawProgress) as Map).cast<String, dynamic>();
      _lastPage
        ..clear()
        ..addAll(decoded.map((id, page) => MapEntry(id, page as int)));
    }
    final rawFavorites = prefs.getStringList(_favoritesKey);
    if (rawFavorites != null) {
      _favorites
        ..clear()
        ..addAll(rawFavorites);
    }
    notifyListeners();
  }

  Future<void> setLastPage(String bookId, int pageIndex) async {
    if (_lastPage[bookId] == pageIndex) return;
    _lastPage[bookId] = pageIndex;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(_lastPage));
    notifyListeners();
  }

  Future<void> toggleFavorite(String bookId) async {
    if (!_favorites.remove(bookId)) {
      _favorites.add(bookId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, _favorites.toList());
    notifyListeners();
  }
}
