/// What the app knows about a learner at a moment in time, in the terms
/// achievements are written against. Built by the profile screen from
/// the catalog and ProgressService; nothing about achievements is
/// stored, so there's no state to keep in sync or migrate.
typedef AchievementStats = ({
  int stepsDone,
  int wordsLearned,
  int totalWords,
  int unitsFinished,
  int totalUnits,
  int longestStreak,
});

class Achievement {
  const Achievement({
    required this.id,
    required this.emoji,
    required this.title,
    required this.detail,
    required this.isEarned,
  });

  final String id;
  final String emoji;
  final String title;

  /// What it takes — shown whether or not it's been earned, so a locked
  /// badge is a goal rather than a mystery.
  final String detail;

  final bool Function(AchievementStats) isEarned;
}

/// Ordered roughly by when they'd be earned, so the grid reads as a
/// ladder. Milestones are deliberately close together early on: the
/// first few are the ones that decide whether a child comes back.
final List<Achievement> kAchievements = [
  Achievement(
    id: 'first_lesson',
    emoji: '🐣',
    title: 'First steps',
    detail: 'Finish a lesson',
    isEarned: (s) => s.stepsDone >= 1,
  ),
  Achievement(
    id: 'five_lessons',
    emoji: '🚀',
    title: 'Getting going',
    detail: 'Finish 5 lessons',
    isEarned: (s) => s.stepsDone >= 5,
  ),
  Achievement(
    id: 'first_unit',
    emoji: '🏆',
    title: 'Unit cleared',
    detail: 'Finish a whole unit',
    isEarned: (s) => s.unitsFinished >= 1,
  ),
  Achievement(
    id: 'twenty_words',
    emoji: '🔤',
    title: 'Twenty words',
    detail: 'Learn 20 words',
    isEarned: (s) => s.wordsLearned >= 20,
  ),
  Achievement(
    id: 'streak_3',
    emoji: '🔥',
    title: 'Three in a row',
    detail: 'Practise 3 days running',
    isEarned: (s) => s.longestStreak >= 3,
  ),
  Achievement(
    id: 'fifty_words',
    emoji: '📚',
    title: 'Fifty words',
    detail: 'Learn 50 words',
    isEarned: (s) => s.wordsLearned >= 50,
  ),
  Achievement(
    id: 'streak_7',
    emoji: '💪',
    title: 'A whole week',
    detail: 'Practise 7 days running',
    isEarned: (s) => s.longestStreak >= 7,
  ),
  Achievement(
    id: 'all_words',
    emoji: '🌟',
    title: 'Every word',
    detail: 'Learn every word there is',
    isEarned: (s) => s.totalWords > 0 && s.wordsLearned >= s.totalWords,
  ),
  Achievement(
    id: 'all_units',
    emoji: '🗺️',
    title: 'Whole map',
    detail: 'Finish every unit',
    isEarned: (s) => s.totalUnits > 0 && s.unitsFinished >= s.totalUnits,
  ),
];
