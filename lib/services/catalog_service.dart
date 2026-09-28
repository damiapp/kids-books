import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/lesson_catalog.dart';

/// Loads the lesson catalog, and quietly keeps it up to date.
///
/// Startup never waits on the network. The app opens on the newest
/// catalog already on the device — the one cached from a previous run,
/// or the copy bundled in the APK — and only then goes looking for a
/// newer one in the background.
///
/// A catalog fetched now is stored for **next launch** rather than
/// swapped in live. Replacing the lessons under a child who is halfway
/// through one would strand their saved place mid-lesson, and no amount
/// of freshness is worth that.
class CatalogService {
  CatalogService._();

  static const _bundledAsset = 'assets/catalog.json';
  static const _cacheKey = 'catalog_json';

  /// The repo is public, so its raw file is a perfectly good host and
  /// adds no vendor: editing the catalog is a commit. Swap this for a
  /// CDN if it ever gets popular enough to matter (README §4).
  static const _remoteUrl =
      'https://raw.githubusercontent.com/damiapp/kids-books/main/assets/catalog.json';

  static const _fetchTimeout = Duration(seconds: 10);

  /// Puts a catalog in place before the first frame. Falls back to the
  /// bundled copy whenever the cached one won't load, so a bad remote
  /// file can cost a user their *update*, never their app.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);

    if (cached != null && _tryLoad(cached, 'cache')) return;
    if (cached != null) await prefs.remove(_cacheKey);

    final bundled = await rootBundle.loadString(_bundledAsset);
    LessonCatalog.load(jsonDecode(bundled) as Map<String, dynamic>);
  }

  /// Looks for a newer catalog and caches it for next launch. Every
  /// failure here is survivable by design — no connection, a 404, a
  /// truncated body, JSON that doesn't parse, a unit pointing at a
  /// lesson that isn't there — so it never throws and never blocks.
  static Future<bool> refreshInBackground() async {
    try {
      final response =
          await http.get(Uri.parse(_remoteUrl)).timeout(_fetchTimeout);
      if (response.statusCode != 200) return false;

      // Decoded as UTF-8 explicitly: the words are full of emoji, and
      // http's default falls back to Latin-1 without a charset header.
      final body = utf8.decode(response.bodyBytes);
      final json = jsonDecode(body) as Map<String, dynamic>;
      final version = json['version'] as int? ?? 0;
      if (version <= LessonCatalog.version) return false;

      // Checked before it is stored, and checked without disturbing the
      // catalog this session is running on. Caching one that can't load
      // would cost the user a launch and then be discarded anyway.
      LessonCatalog.parse(json);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, body);
      debugPrint('Catalog v$version cached; it will be used next launch.');
      return true;
    } catch (error) {
      debugPrint('Catalog refresh skipped: $error');
      return false;
    }
  }

  static bool _tryLoad(String source, String label) {
    try {
      LessonCatalog.load(jsonDecode(source) as Map<String, dynamic>);
      return true;
    } catch (error) {
      debugPrint('Catalog from $label rejected: $error');
      return false;
    }
  }
}
