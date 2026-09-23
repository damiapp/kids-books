import 'package:flutter/material.dart';

import '../data/lesson_catalog.dart';
import '../services/auth_service.dart';
import '../services/energy_service.dart';
import '../services/entitlement_service.dart';
import '../services/progress_service.dart';

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
          final totalWords = {
            for (final lesson in LessonCatalog.lessons)
              for (final word in lesson.words) word.word,
          }.length;

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
              const SizedBox(height: 18),
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
