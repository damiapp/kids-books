import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../widgets/motion.dart';

/// The moment a lesson ends. It used to be a system dialog — the same
/// grey box that asks whether to delete a file — which is the wrong
/// register entirely for "you did it" to a four-year-old.
///
/// Confetti falls, the lesson's own emoji pops in and floats, and the
/// screen assembles itself piece by piece. The streak and today's goal
/// sit here too, because this is the one moment they mean the most.
class LessonCompleteScreen extends StatelessWidget {
  const LessonCompleteScreen({
    super.key,
    required this.lesson,
    required this.streak,
    required this.lessonsToday,
    required this.dailyGoal,
  });

  final Lesson lesson;
  final int streak;
  final int lessonsToday;
  final int dailyGoal;

  /// Fades in rather than sliding: it's a moment, not a place.
  static Route<void> route({
    required Lesson lesson,
    required int streak,
    required int lessonsToday,
    required int dailyGoal,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => LessonCompleteScreen(
        lesson: lesson,
        streak: streak,
        lessonsToday: lessonsToday,
        dailyGoal: dailyGoal,
      ),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final goalMet = lessonsToday >= dailyGoal;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF6),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  PopIn(
                    from: 0.3,
                    child: Bob(
                      height: 6,
                      child: Container(
                        width: 150,
                        height: 150,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: lesson.coverColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(lesson.coverEmoji,
                            style: const TextStyle(fontSize: 76)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const PopIn(
                    delay: Duration(milliseconds: 180),
                    child: Text(
                      'Great job!',
                      style:
                          TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PopIn(
                    delay: const Duration(milliseconds: 280),
                    child: Text(
                      'You finished ${lesson.title}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7A756B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  PopIn(
                    delay: const Duration(milliseconds: 420),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (streak > 0)
                          _Chip(
                            emoji: '🔥',
                            label: streak == 1
                                ? 'First day!'
                                : '$streak days in a row',
                          ),
                        _Chip(
                          emoji: goalMet ? '🎉' : '🎯',
                          label: goalMet
                              ? "Today's goal done"
                              : '$lessonsToday of $dailyGoal today',
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                  PopIn(
                    delay: const Duration(milliseconds: 600),
                    from: 0.85,
                    child: Pressable(
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Last, so it falls over everything — and never takes a tap.
          const Positioned.fill(child: Confetti()),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E2D9), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
