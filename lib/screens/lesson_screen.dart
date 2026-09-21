import 'dart:math';

import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../services/narration_service.dart';
import '../services/progress_service.dart';

sealed class _Step {
  const _Step();
}

class _LearnStep extends _Step {
  const _LearnStep(this.word);
  final LessonWord word;
}

class _PracticeStep extends _Step {
  const _PracticeStep(this.target, this.choices);
  final LessonWord target;
  final List<LessonWord> choices;
}

List<_Step> _buildSteps(Lesson lesson) {
  final rnd = Random();
  final steps = <_Step>[];
  for (final word in lesson.words) {
    steps.add(_LearnStep(word));
    final others = lesson.words.where((w) => w != word).toList()..shuffle(rnd);
    final distractorCount = others.length < 2 ? others.length : 2;
    final choices = [word, ...others.take(distractorCount)]..shuffle(rnd);
    steps.add(_PracticeStep(word, choices));
  }
  return steps;
}

/// Plays one lesson: a "learn" step (see + hear the word) followed by a
/// "practice" step (tap the match) for each word — a teach-then-test
/// loop. Energy is spent once, before this screen opens (see PathScreen),
/// so nothing here is paywalled.
class LessonScreen extends StatefulWidget {
  const LessonScreen({
    super.key,
    required this.progress,
    required this.lesson,
  });

  final ProgressService progress;
  final Lesson lesson;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final List<_Step> _steps = _buildSteps(widget.lesson);
  late final PageController _controller;
  final _narration = NarrationService();
  late int _index;

  /// Practice steps answered correctly this sitting. A practice step that
  /// isn't in here can't be swiped past — the question has to be answered.
  final Set<int> _answered = {};

  bool get _canSwipe =>
      _steps[_index] is! _PracticeStep || _answered.contains(_index);

  @override
  void initState() {
    super.initState();
    final saved = widget.progress.lastStepFor(widget.lesson.id) ?? 0;
    _index = saved.clamp(0, _steps.length - 1).toInt();
    _controller = PageController(initialPage: _index);
    _speakIfPractice(_steps[_index]);
  }

  @override
  void dispose() {
    _controller.dispose();
    _narration.dispose();
    super.dispose();
  }

  void _speakIfPractice(_Step step) {
    if (step is _PracticeStep) {
      _narration.speak(step.target.word);
    }
  }

  void _onAnswered(int stepIndex) {
    setState(() => _answered.add(stepIndex));
    _goToStep(stepIndex + 1);
  }

  void _goToStep(int i) {
    if (i >= _steps.length) {
      _finishLesson();
      return;
    }
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finishLesson() async {
    // Completion is reaching the end, not landing on the last question —
    // the final practice step still has to be answered to get here.
    widget.progress.markCompleted(widget.lesson.id);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Lesson complete! 🎉'),
        content: Text('Great job finishing "${widget.lesson.title}".'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _onPageChanged(int i) {
    _narration.stop();
    setState(() => _index = i);
    widget.progress.setLastStep(widget.lesson.id, i);
    _speakIfPractice(_steps[i]);
  }

  void _toggleSpeak(String text) {
    if (_narration.isSpeaking) {
      _narration.stop();
    } else {
      _narration.speak(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([widget.progress, _narration]),
        builder: (context, _) {
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          _narration.stop();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_index + 1) / _steps.length,
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    // Learn steps swipe freely; an unanswered practice step
                    // is a wall until the right picture is tapped.
                    physics: _canSwipe
                        ? const PageScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    itemCount: _steps.length,
                    itemBuilder: (context, i) {
                      final step = _steps[i];
                      return switch (step) {
                        _LearnStep() => _LearnView(
                            word: step.word,
                            isSpeaking: _narration.isSpeaking,
                            onSpeak: () => _toggleSpeak(
                                '${step.word.word}. ${step.word.text}'),
                          ),
                        _PracticeStep() => _PracticeView(
                            key: ValueKey('practice-$i-${step.target.word}'),
                            target: step.target,
                            choices: step.choices,
                            isSpeaking: _narration.isSpeaking,
                            onReplay: () =>
                                _narration.speak(step.target.word),
                            onCorrect: () => _onAnswered(i),
                          ),
                      };
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LearnView extends StatelessWidget {
  const _LearnView({
    required this.word,
    required this.isSpeaking,
    required this.onSpeak,
  });

  final LessonWord word;
  final bool isSpeaking;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: word.color,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Same reason as the choice cards: a five-emoji
                        // word has to shrink to fit, not wrap.
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              word.emoji,
                              softWrap: false,
                              style: const TextStyle(fontSize: 120),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          word.word,
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3D3A34),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            word.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 18,
                                height: 1.4,
                                color: Color(0xFF534F48)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton.filled(
                      onPressed: onSpeak,
                      tooltip: isSpeaking ? 'Stop reading' : 'Read aloud',
                      icon: Icon(
                        isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _SwipeHint(),
        ],
      ),
    );
  }
}

/// Nudges the swipe, since a three-year-old won't guess it. Drifts right
/// and back so it reads as "keep going this way".
class _SwipeHint extends StatefulWidget {
  const _SwipeHint();

  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _drift = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, child) => Transform.translate(
        offset: Offset(_drift.value * 12, 0),
        child: child,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Swipe to keep going',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, size: 20, color: color),
        ],
      ),
    );
  }
}

class _PracticeView extends StatefulWidget {
  const _PracticeView({
    super.key,
    required this.target,
    required this.choices,
    required this.isSpeaking,
    required this.onReplay,
    required this.onCorrect,
  });

  final LessonWord target;
  final List<LessonWord> choices;
  final bool isSpeaking;
  final VoidCallback onReplay;
  final VoidCallback onCorrect;

  @override
  State<_PracticeView> createState() => _PracticeViewState();
}

class _PracticeViewState extends State<_PracticeView> {
  LessonWord? _correctSelected;
  LessonWord? _wrongTapped;

  void _choose(LessonWord choice) {
    if (_correctSelected != null) return;
    if (choice.word == widget.target.word) {
      setState(() {
        _correctSelected = choice;
        _wrongTapped = null;
      });
      Future.delayed(const Duration(milliseconds: 550), widget.onCorrect);
    } else {
      setState(() => _wrongTapped = choice);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _wrongTapped = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        children: [
          const Text(
            'Which one did you hear?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          IconButton.filledTonal(
            onPressed: widget.onReplay,
            tooltip: 'Listen again',
            icon: Icon(
                widget.isSpeaking ? Icons.volume_up_rounded : Icons.replay_rounded),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: widget.choices.length > 1 ? 2 : 1,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              children: [
                for (final choice in widget.choices)
                  _ChoiceCard(
                    word: choice,
                    isCorrect: _correctSelected == choice,
                    isWrong: _wrongTapped == choice,
                    onTap: () => _choose(choice),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.word,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
  });

  final LessonWord word;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = isCorrect
        ? const Color(0xFFDCF0DC)
        : isWrong
            ? const Color(0xFFF6D3D3)
            : word.color;
    final Color? borderColor = isCorrect
        ? const Color(0xFF4CAF50)
        : isWrong
            ? const Color(0xFFE0637A)
            : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: borderColor != null ? Border.all(color: borderColor, width: 3) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              children: [
                // Counting words are several emoji wide ("⭐⭐⭐⭐"). Scale
                // them down to a single line instead of letting them wrap
                // and shove the label out of the card.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      word.emoji,
                      softWrap: false,
                      style: const TextStyle(fontSize: 56),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  word.word,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                if (isCorrect)
                  const Icon(Icons.check_circle_rounded,
                      size: 22, color: Color(0xFF4CAF50)),
                if (isWrong)
                  const Icon(Icons.cancel_rounded,
                      size: 22, color: Color(0xFFE0637A)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
