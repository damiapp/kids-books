import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peekadoo/models/lesson.dart';
import 'package:peekadoo/screens/lesson_screen.dart';
import 'package:peekadoo/services/narration_service.dart';
import 'package:peekadoo/services/progress_service.dart';
import 'package:peekadoo/widgets/motion.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The lesson player is the part of the app a child spends nearly all
/// their time in, and the two things tested here are the ones a child
/// would hit hardest: leaving by accident, and getting stuck guessing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const lesson = Lesson(
    id: 'test-lesson',
    title: 'Test',
    subtitle: 'Three words',
    coverEmoji: '🧪',
    coverColor: Color(0xFFFFFFFF),
    words: [
      LessonWord(
          emoji: '🍎', word: 'apple', text: 'An apple.', color: Colors.red),
      LessonWord(
          emoji: '⚽', word: 'ball', text: 'A ball.', color: Colors.blue),
      LessonWord(emoji: '🐱', word: 'cat', text: 'A cat.', color: Colors.grey),
    ],
  );

  /// Everything the app asked the voice to say, in order.
  late List<String> spoken;
  late ProgressService progress;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    spoken = [];
    NarrationService.resetForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'),
            (call) async {
      if (call.method == 'speak') spoken.add(call.arguments as String);
      return 1;
    });
    progress = ProgressService();
    await progress.init();
    // Open straight onto the first question ("apple"), not its learn card.
    await progress.setLastStep(lesson.id, 1);
  });

  /// The lesson, opened from a home screen so leaving it has somewhere
  /// to go back to.
  Future<void> openLesson(WidgetTester tester) async {
    // A phone held upright, as the app is locked to.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => LessonScreen(progress: progress, lesson: lesson),
            )),
            child: const Text('home'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('home'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Finder choice(String word) => find.descendant(
        of: find.byType(GridView),
        matching: find.text(word),
      );

  Bob bobOf(WidgetTester tester, String word) => tester.widget<Bob>(
        find.ancestor(of: choice(word), matching: find.byType(Bob)),
      );

  group('leaving a lesson', () {
    testWidgets('the close button asks first, and keep playing stays',
        (tester) async {
      await openLesson(tester);

      await tester.tap(find.byTooltip('Stop'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Stop playing?'), findsOneWidget);
      expect(spoken.last, 'Do you want to stop playing?');

      await tester.tap(find.text('▶  Keep playing'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Stop playing?'), findsNothing);
      expect(find.byType(LessonScreen), findsOneWidget);
      // The question is asked again, so the child knows where they are.
      expect(spoken.last, 'Can you find... apple?');
    });

    testWidgets('the back gesture asks too, and stop leaves',
        (tester) async {
      await openLesson(tester);

      // What Android's back gesture does: a pop the route may refuse.
      await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Stop playing?'), findsOneWidget);

      await tester.tap(find.text('🏠  Stop'));
      // Settles once the lesson's page has animated away; its looping
      // animations go with it.
      await tester.pumpAndSettle();
      expect(find.byType(LessonScreen), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('getting stuck', () {
    testWidgets('one miss just asks again', (tester) async {
      await openLesson(tester);

      await tester.tap(choice('ball'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(spoken.last, 'Try again! Can you find... apple?');
      expect(bobOf(tester, 'apple').height, 0);
      expect(progress.trickiestWords, contains('apple'));
    });

    testWidgets('a second miss points to the right answer', (tester) async {
      await openLesson(tester);

      await tester.tap(choice('ball'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(choice('cat'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(spoken.last, 'Look, here it is! apple!');
      expect(bobOf(tester, 'apple').height, greaterThan(0));
      expect(bobOf(tester, 'ball').height, 0);
      expect(bobOf(tester, 'cat').height, 0);

      // And the hinted card still has to be tapped to move on.
      await tester.tap(choice('apple'));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 400));
      expect(progress.lastStepFor(lesson.id), 2);

      // On to the next learn card, which nudges after a while if nobody
      // swipes; let that happen so no timer outlives the test.
      await tester.pump(const Duration(seconds: 8));
      expect(spoken.last, 'Swipe to see what comes next!');
    });
  });
}
