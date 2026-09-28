import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:peekadoo/data/lesson_catalog.dart';

/// The catalog ships over the network now (README §4), so a malformed
/// file can reach an installed app without a build standing in the way.
/// These are what stands in the way instead.
///
/// They run against `assets/catalog.json` on disk — the real file, not a
/// fixture — so editing content and pushing without running them is the
/// thing CI catches.
void main() {
  late Map<String, dynamic> catalog;

  setUpAll(() {
    final file = File('assets/catalog.json');
    expect(file.existsSync(), isTrue,
        reason: 'assets/catalog.json is what the app ships with');
    catalog = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  });

  group('assets/catalog.json', () {
    test('loads through the same parser the app uses', () {
      final parsed = LessonCatalog.parse(catalog);
      expect(parsed.units, isNotEmpty);
      expect(parsed.lessons, isNotEmpty);
      expect(parsed.version, greaterThanOrEqualTo(1),
          reason: 'version gates whether a fetched catalog replaces this one');
    });

    test('every unit points at lessons that exist', () {
      final parsed = LessonCatalog.parse(catalog);
      final ids = {for (final lesson in parsed.lessons) lesson.id};
      for (final unit in parsed.units) {
        for (final id in unit.lessonIds) {
          expect(ids, contains(id), reason: 'unit ${unit.id} wants $id');
        }
      }
    });

    test('no lesson is stranded off the path', () {
      final parsed = LessonCatalog.parse(catalog);
      final referenced = {
        for (final unit in parsed.units) ...unit.lessonIds,
      };
      for (final lesson in parsed.lessons) {
        expect(referenced, contains(lesson.id),
            reason: '${lesson.id} exists but no unit lists it, so it is '
                'unreachable and its energy cost is never paid');
      }
    });

    test('ids are unique', () {
      final parsed = LessonCatalog.parse(catalog);
      final lessonIds = [for (final l in parsed.lessons) l.id];
      final unitIds = [for (final u in parsed.units) u.id];
      expect(lessonIds.toSet(), hasLength(lessonIds.length));
      expect(unitIds.toSet(), hasLength(unitIds.length));
    });

    test('every lesson can pose a question', () {
      final parsed = LessonCatalog.parse(catalog);
      for (final lesson in parsed.lessons) {
        // One right answer plus two wrong ones.
        expect(lesson.words.length, greaterThanOrEqualTo(3),
            reason: '${lesson.id} has too few words for a practice step');
      }
    });

    test('words are taught once', () {
      final parsed = LessonCatalog.parse(catalog);
      final words = [
        for (final lesson in parsed.lessons)
          for (final word in lesson.words) word.word,
      ];
      final seen = <String>{};
      final repeated = {for (final w in words) if (!seen.add(w)) w};
      expect(repeated, isEmpty,
          reason: 'a repeated word appears twice in the word bank and can '
              'be its own distractor in a review');
    });

    test('every word is complete and speakable', () {
      final parsed = LessonCatalog.parse(catalog);
      for (final lesson in parsed.lessons) {
        for (final word in lesson.words) {
          expect(word.emoji.trim(), isNotEmpty, reason: lesson.id);
          expect(word.word.trim(), isNotEmpty, reason: lesson.id);
          // The sentence is read aloud, so it needs to end like one.
          expect(word.text.trim(), endsWithAny(['.', '!']),
              reason: '${lesson.id}/${word.word}');
        }
      }
    });

    test('emoji stay within what an older Android can draw', () {
      final parsed = LessonCatalog.parse(catalog);
      for (final lesson in parsed.lessons) {
        for (final word in lesson.words) {
          // A ZWJ sequence an older font lacks degrades into several
          // unrelated glyphs; a missing one is a blank box. Neither
          // reads as a bug to a three-year-old.
          expect(word.emoji.contains('‍'), isFalse,
              reason: '${lesson.id}/${word.word} uses a ZWJ sequence');
          for (final rune in word.emoji.runes) {
            expect(rune, lessThan(0x1FB00),
                reason: '${lesson.id}/${word.word} uses a very new glyph');
          }
        }
      }
    });
  });

  group('LessonCatalog.parse rejects', () {
    Map<String, dynamic> withLessons(List<Map<String, dynamic>> lessons,
            {List<Map<String, dynamic>>? units}) =>
        {
          'version': 1,
          'units': units ??
              [
                {
                  'id': 'u1',
                  'section': 'S1',
                  'title': 'Unit',
                  'color': '#3AA7A0',
                  'lessonIds': [for (final l in lessons) l['id']],
                }
              ],
          'lessons': lessons,
        };

    Map<String, dynamic> lesson(String id, int wordCount) => {
          'id': id,
          'title': 'T',
          'subtitle': 'S',
          'coverEmoji': '🎯',
          'coverColor': '#3AA7A0',
          'words': [
            for (var i = 0; i < wordCount; i++)
              {
                'emoji': '🍎',
                'word': '$id$i',
                'text': 'A sentence.',
                'color': '#3AA7A0',
              },
          ],
        };

    test('a unit pointing at a missing lesson', () {
      final json = withLessons([lesson('a', 3)]);
      (json['units'] as List).first['lessonIds'] = ['a', 'ghost'];
      expect(() => LessonCatalog.parse(json), throwsFormatException);
    });

    test('a lesson too small to quiz', () {
      expect(() => LessonCatalog.parse(withLessons([lesson('a', 2)])),
          throwsFormatException);
    });

    test('an empty catalog', () {
      expect(
          () => LessonCatalog.parse({
                'version': 1,
                'units': <dynamic>[],
                'lessons': <dynamic>[],
              }),
          throwsFormatException);
    });

    test('but accepts a minimal valid one', () {
      final parsed = LessonCatalog.parse(withLessons([lesson('a', 3)]));
      expect(parsed.lessons, hasLength(1));
      expect(parsed.units, hasLength(1));
    });
  });
}

/// `endsWith` takes one suffix; a read-aloud sentence may end with
/// either a full stop or an exclamation mark.
Matcher endsWithAny(List<String> suffixes) => anyOf(
      [for (final suffix in suffixes) endsWith(suffix)],
    );
