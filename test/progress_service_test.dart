import 'package:flutter_test/flutter_test.dart';
import 'package:peekadoo/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The streak is the one piece of state that depends on *when* things
/// happened, which makes it the one that can look fine for weeks and
/// then be wrong at midnight. ProgressService.clock exists so these can
/// walk the calendar instead of waiting for it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 5, 10, 9);
    ProgressService.clock = () => now;
  });

  tearDown(() => ProgressService.clock = DateTime.now);

  Future<ProgressService> fresh() async {
    final progress = ProgressService();
    await progress.init();
    return progress;
  }

  group('streak', () {
    test('is zero before anything is finished', () async {
      final progress = await fresh();
      expect(progress.streak, 0);
      expect(progress.lessonsToday, 0);
    });

    test('a finished lesson starts it at one', () async {
      final progress = await fresh();
      await progress.markCompleted('colours');
      expect(progress.streak, 1);
      expect(progress.lessonsToday, 1);
    });

    test('yesterday continues it', () async {
      final progress = await fresh();
      await progress.markCompleted('colours');
      now = now.add(const Duration(days: 1));
      await progress.markCompleted('numbers');
      expect(progress.streak, 2);
      expect(progress.lessonsToday, 1, reason: 'a new day counts from zero');
    });

    test('a missed day starts over', () async {
      final progress = await fresh();
      await progress.markCompleted('colours');
      now = now.add(const Duration(days: 3));
      await progress.markCompleted('numbers');
      expect(progress.streak, 1);
    });

    test('reads as zero once it has lapsed, without a lesson being played',
        () async {
      final progress = await fresh();
      await progress.markCompleted('colours');
      expect(progress.streak, 1);
      now = now.add(const Duration(days: 2));
      expect(progress.streak, 0,
          reason: 'the count only survives while it is today or yesterday');
    });

    test('still shows yesterday as live, so a day is not lost mid-morning',
        () async {
      final progress = await fresh();
      await progress.markCompleted('colours');
      now = now.add(const Duration(days: 1));
      expect(progress.streak, 1);
    });

    test('keeps the best run even after the current one lapses', () async {
      final progress = await fresh();
      await progress.markCompleted('a');
      now = now.add(const Duration(days: 1));
      await progress.markCompleted('b');
      now = now.add(const Duration(days: 5));
      await progress.markCompleted('c');
      expect(progress.streak, 1);
      expect(progress.longestStreak, 2);
    });

    test('survives a restart', () async {
      final first = await fresh();
      await first.markCompleted('colours');
      final second = await fresh();
      expect(second.streak, 1);
      expect(second.lessonsToday, 1);
    });
  });

  group('daily goal', () {
    test('counts a replay, because showing up is the point', () async {
      final progress = await fresh();
      await progress.markCompleted('colours');
      await progress.markCompleted('colours');
      expect(progress.lessonsToday, 2);
      expect(progress.dailyGoalMet, isTrue);
      expect(progress.isCompleted('colours'), isTrue);
    });

    test('a replay does not inflate the streak', () async {
      final progress = await fresh();
      await progress.markCompleted('colours');
      await progress.markCompleted('colours');
      expect(progress.streak, 1);
    });
  });

  group('missed words', () {
    test('counts misses and orders the worst first', () async {
      final progress = await fresh();
      await progress.recordMiss('Blue');
      await progress.recordMiss('Red');
      await progress.recordMiss('Red');
      expect(progress.missesFor('Red'), 2);
      expect(progress.trickiestWords.first, 'Red');
      expect(progress.trickiestWords, ['Red', 'Blue']);
    });

    test('forgiving one removes it from practice', () async {
      final progress = await fresh();
      await progress.recordMiss('Red');
      await progress.forgiveMiss('Red');
      expect(progress.trickiestWords, isEmpty);
      expect(progress.missesFor('Red'), 0);
    });

    test('forgiving a word never missed is harmless', () async {
      final progress = await fresh();
      await progress.forgiveMiss('Never');
      expect(progress.trickiestWords, isEmpty);
    });

    test('survives a restart', () async {
      final first = await fresh();
      await first.recordMiss('Red');
      final second = await fresh();
      expect(second.missesFor('Red'), 1);
    });
  });

  group('lesson progress', () {
    test('remembers the last step', () async {
      final progress = await fresh();
      await progress.setLastStep('colours', 4);
      expect(progress.lastStepFor('colours'), 4);
      expect((await fresh()).lastStepFor('colours'), 4);
    });

    test('is null for a lesson never opened', () async {
      final progress = await fresh();
      expect(progress.lastStepFor('never'), isNull);
    });
  });
}
