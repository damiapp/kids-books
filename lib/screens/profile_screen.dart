import 'package:flutter/material.dart';

import '../data/achievements.dart';
import '../data/lesson_catalog.dart';
import '../models/lesson.dart';
import '../services/auth_service.dart';
import '../services/energy_service.dart';
import '../services/entitlement_service.dart';
import '../services/progress_service.dart';
import 'lesson_screen.dart';

/// Where the learner stands: what they've finished, what they know, what
/// comes next. Read-only — everything here is derived from the catalog
/// and ProgressService, so there's no state of its own to keep in sync.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.progress,
    required this.energy,
    required this.entitlements,
    this.auth,
  });

  final ProgressService progress;
  final EnergyService energy;
  final EntitlementService entitlements;
  final AuthService? auth;

  /// Words met in finished lessons. Counted by the word itself, not per
  /// lesson: unit reviews re-use words their unit already taught, so
  /// counting appearances would inflate the number.
  Set<String> get _wordsLearned => {
        for (final lesson in LessonCatalog.lessons)
          if (progress.isCompleted(lesson.id))
            for (final word in lesson.words) word.word,
      };

  int _doneIn(LessonUnit unit) =>
      unit.lessonIds.where(progress.isCompleted).length +
      (progress.isCompleted(unit.reviewId) ? 1 : 0);

  bool _isFinished(LessonUnit unit) => _doneIn(unit) == unit.stepCount;

  /// The unit they're working through: the first one not yet finished.
  /// Null once the whole catalog is done.
  LessonUnit? get _currentUnit {
    for (final unit in LessonCatalog.units) {
      if (!_isFinished(unit)) return unit;
    }
    return null;
  }

  /// The next thing to play, matching the path's unlock order: the first
  /// unfinished lesson of the current unit, or its review once the
  /// lessons are done.
  ({String title, bool isReview})? get _nextUp {
    final unit = _currentUnit;
    if (unit == null) return null;
    for (final id in unit.lessonIds) {
      if (!progress.isCompleted(id)) {
        return (title: LessonCatalog.byId(id).title, isReview: false);
      }
    }
    return (title: '${unit.title} review', isReview: true);
  }

  int get _totalSteps =>
      LessonCatalog.units.fold(0, (sum, unit) => sum + unit.stepCount);

  int get _doneSteps =>
      LessonCatalog.units.fold(0, (sum, unit) => sum + _doneIn(unit));

  /// Opens a drill over the words they keep missing. Free, deliberately:
  /// charging energy to practise the hard ones would price the most
  /// useful thing in the app.
  void _openPractice(BuildContext context, Lesson drill) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LessonScreen(
        progress: progress,
        lesson: drill,
        isPractice: true,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListenableBuilder(
        listenable: Listenable.merge([progress, energy, entitlements]),
        builder: (context, _) {
          final unit = _currentUnit;
          final next = _nextUp;
          final totalWords = LessonCatalog.allWords.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Headline(
                email: auth?.currentEmail,
                subscribed: entitlements.subscriptionActive,
                energyLabel: entitlements.subscriptionActive
                    ? '∞'
                    : '${energy.current}',
                doneSteps: _doneSteps,
                totalSteps: _totalSteps,
              ),
              const SizedBox(height: 14),
              _TodayCard(
                lessonsToday: progress.lessonsToday,
                goal: ProgressService.dailyGoal,
                streak: progress.streak,
                longestStreak: progress.longestStreak,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      emoji: '⭐',
                      value: '$_doneSteps',
                      label: _doneSteps == 1 ? 'lesson done' : 'lessons done',
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      emoji: '🔤',
                      value: '${_wordsLearned.length}',
                      label: 'of $totalWords words',
                      color: const Color(0xFFE0A100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (next != null && unit != null) ...[
                const _SectionTitle('Up next'),
                _NextUpCard(unit: unit, title: next.title, isReview: next.isReview),
                const SizedBox(height: 22),
              ] else ...[
                const _SectionTitle('Up next'),
                const _AllDoneCard(),
                const SizedBox(height: 22),
              ],
              const _SectionTitle('Units'),
              for (final u in LessonCatalog.units)
                _UnitRow(
                  unit: u,
                  done: _doneIn(u),
                  isCurrent: u.id == unit?.id,
                ),
              const SizedBox(height: 10),
              if (LessonCatalog.practiceLesson(progress.trickiestWords)
                  case final drill?) ...[
                const _SectionTitle('Worth another go'),
                _TrickyWordsCard(
                  count: drill.words.length,
                  onTap: () => _openPractice(context, drill),
                ),
                const SizedBox(height: 22),
              ],
              const _SectionTitle('Achievements'),
              _AchievementGrid(
                stats: (
                  stepsDone: _doneSteps,
                  wordsLearned: _wordsLearned.length,
                  totalWords: totalWords,
                  unitsFinished:
                      LessonCatalog.units.where(_isFinished).length,
                  totalUnits: LessonCatalog.units.length,
                  longestStreak: progress.longestStreak,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({
    required this.email,
    required this.subscribed,
    required this.energyLabel,
    required this.doneSteps,
    required this.totalSteps,
  });

  final String? email;
  final bool subscribed;
  final String energyLabel;
  final int doneSteps;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = totalSteps == 0 ? 0.0 : doneSteps / totalSteps;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🐣', style: TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email ?? 'Your learner',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${subscribed ? 'All Access' : 'Free plan'} · ⚡ $energyLabel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '$doneSteps of $totalSteps',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${(fraction * 100).round()}%',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: fraction, minHeight: 10),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  final String emoji;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E2D9), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7A756B),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          color: Color(0xFF9E9889),
        ),
      ),
    );
  }
}

class _NextUpCard extends StatelessWidget {
  const _NextUpCard({
    required this.unit,
    required this.title,
    required this.isReview,
  });

  final LessonUnit unit;
  final String title;
  final bool isReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unit.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(
            isReview ? '🏆' : '▶️',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unit.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F0CE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Text('🎉', style: TextStyle(fontSize: 28)),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Every unit finished. More lessons are on the way!',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.unit,
    required this.done,
    required this.isCurrent,
  });

  final LessonUnit unit;
  final int done;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final finished = done == unit.stepCount;
    final notStarted = done == 0 && !isCurrent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: notStarted ? const Color(0xFFE6E2D9) : unit.color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              finished
                  ? Icons.check_rounded
                  : notStarted
                      ? Icons.lock_rounded
                      : Icons.play_arrow_rounded,
              size: 18,
              color: notStarted ? const Color(0xFF9E9889) : Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unit.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: notStarted
                        ? const Color(0xFF9E9889)
                        : const Color(0xFF3B3931),
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: done / unit.stepCount,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFEDEAE1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$done/${unit.stepCount}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF7A756B),
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's goal and the streak. Deliberately gentle: a missed day resets
/// the count quietly and nothing here nags — streak pressure aimed at a
/// three-year-old really lands on whoever holds the phone.
class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.lessonsToday,
    required this.goal,
    required this.streak,
    required this.longestStreak,
  });

  final int lessonsToday;
  final int goal;
  final int streak;
  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final met = lessonsToday >= goal;
    final capped = lessonsToday > goal ? goal : lessonsToday;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E2D9), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                met ? '🎉' : '🎯',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  met
                      ? 'Today’s goal done!'
                      : 'Today: $lessonsToday of $goal lessons',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (streak > 0)
                Text(
                  '🔥 $streak',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: scheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal == 0 ? 0 : capped / goal,
              minHeight: 9,
              backgroundColor: const Color(0xFFEDEAE1),
            ),
          ),
          if (longestStreak > 0) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                streak >= longestStreak && streak > 0
                    ? 'Best streak yet — keep it going'
                    : 'Best streak: $longestStreak days',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9E9889),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The words they've got wrong, offered back as a short drill.
class _TrickyWordsCard extends StatelessWidget {
  const _TrickyWordsCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFDBC2),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tricky words',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count to practise · free, no energy',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7A6A5B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  const _AchievementGrid({required this.stats});

  final AchievementStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        for (final achievement in kAchievements)
          _AchievementTile(
            achievement: achievement,
            earned: achievement.isEarned(stats),
          ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.earned});

  final Achievement achievement;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: earned ? scheme.primaryContainer : const Color(0xFFF2F0EA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: earned ? scheme.primary : const Color(0xFFE6E2D9),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // A locked badge keeps its shape but loses its colour, so the
          // grid reads as a row of goals rather than a row of mysteries.
          Opacity(
            opacity: earned ? 1 : 0.35,
            child: Text(
              achievement.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: earned ? const Color(0xFF3B3931) : const Color(0xFF9E9889),
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Text(
              achievement.detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9E9889),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
