import 'dart:math';

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/narration_service.dart';
import '../services/reading_progress_service.dart';

sealed class _LessonStep {
  const _LessonStep();
}

class _LearnStep extends _LessonStep {
  const _LearnStep(this.page);
  final BookPage page;
}

class _PracticeStep extends _LessonStep {
  const _PracticeStep(this.target, this.choices);
  final BookPage target;
  final List<BookPage> choices;
}

List<_LessonStep> _buildSteps(Book book) {
  final rnd = Random();
  final steps = <_LessonStep>[];
  for (final page in book.pages) {
    steps.add(_LearnStep(page));
    final others = book.pages.where((p) => p != page).toList()..shuffle(rnd);
    final distractorCount = others.length < 2 ? others.length : 2;
    final choices = [page, ...others.take(distractorCount)]..shuffle(rnd);
    steps.add(_PracticeStep(page, choices));
  }
  return steps;
}

/// Plays one lesson: a "learn" step (see + hear the word) followed by a
/// "practice" step (tap the match) for each page — a Duolingo-style
/// teach-then-test loop. Energy is spent once, before this screen opens
/// (see ShelfScreen), so nothing here is paywalled.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.progress,
    required this.book,
  });

  final ReadingProgressService progress;
  final Book book;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final List<_LessonStep> _steps = _buildSteps(widget.book);
  late final PageController _controller;
  final _narration = NarrationService();
  late int _index;

  @override
  void initState() {
    super.initState();
    final saved = widget.progress.lastStepFor(widget.book.id) ?? 0;
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

  void _speakIfPractice(_LessonStep step) {
    if (step is _PracticeStep) {
      _narration.speak(step.target.word);
    }
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
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Lesson complete! 🎉'),
        content: Text('Great job finishing "${widget.book.title}".'),
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
    widget.progress.setLastStep(widget.book.id, i);
    if (i == _steps.length - 1) {
      widget.progress.markCompleted(widget.book.id);
    }
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
    final book = widget.book;

    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([widget.progress, _narration]),
        builder: (context, _) {
          final isFavorite = widget.progress.isFavorite(book.id);
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
                      IconButton(
                        onPressed: () =>
                            widget.progress.toggleFavorite(book.id),
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite ? const Color(0xFFE0637A) : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    itemCount: _steps.length,
                    itemBuilder: (context, i) {
                      final step = _steps[i];
                      return switch (step) {
                        _LearnStep() => _LearnPageView(
                            page: step.page,
                            isSpeaking: _narration.isSpeaking,
                            isLastStep: i == _steps.length - 1,
                            onSpeak: () => _toggleSpeak(
                                '${step.page.word}. ${step.page.text}'),
                            onNext: () => _goToStep(i + 1),
                          ),
                        _PracticeStep() => _PracticePageView(
                            key: ValueKey('practice-$i-${step.target.word}'),
                            target: step.target,
                            choices: step.choices,
                            isSpeaking: _narration.isSpeaking,
                            onReplay: () =>
                                _narration.speak(step.target.word),
                            onCorrect: () => _goToStep(i + 1),
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

class _LearnPageView extends StatelessWidget {
  const _LearnPageView({
    required this.page,
    required this.isSpeaking,
    required this.isLastStep,
    required this.onSpeak,
    required this.onNext,
  });

  final BookPage page;
  final bool isSpeaking;
  final bool isLastStep;
  final VoidCallback onSpeak;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: page.color,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(page.emoji, style: const TextStyle(fontSize: 120)),
                        const SizedBox(height: 16),
                        Text(
                          page.word,
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
                            page.text,
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(
                isLastStep ? 'Finish' : 'Next',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticePageView extends StatefulWidget {
  const _PracticePageView({
    super.key,
    required this.target,
    required this.choices,
    required this.isSpeaking,
    required this.onReplay,
    required this.onCorrect,
  });

  final BookPage target;
  final List<BookPage> choices;
  final bool isSpeaking;
  final VoidCallback onReplay;
  final VoidCallback onCorrect;

  @override
  State<_PracticePageView> createState() => _PracticePageViewState();
}

class _PracticePageViewState extends State<_PracticePageView> {
  BookPage? _correctSelected;
  BookPage? _wrongTapped;

  void _choose(BookPage choice) {
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
                    page: choice,
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
    required this.page,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
  });

  final BookPage page;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = isCorrect
        ? const Color(0xFFDCF0DC)
        : isWrong
            ? const Color(0xFFF6D3D3)
            : page.color;
    final Color? borderColor = isCorrect
        ? const Color(0xFF4CAF50)
        : isWrong
            ? const Color(0xFFE0637A)
            : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
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
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(page.emoji, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text(page.word,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                if (isCorrect)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50)),
                  ),
                if (isWrong)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.cancel_rounded, color: Color(0xFFE0637A)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
