import 'package:flutter/material.dart';

import '../data/lesson_catalog.dart';
import '../models/lesson.dart';
import '../services/narration_service.dart';
import '../services/progress_service.dart';

/// Every word the child has learned, as cards they can tap to hear
/// again. The one screen here a preschooler can use unaided — no reading
/// required, nothing to get wrong, and no way to lose progress.
class WordBankScreen extends StatefulWidget {
  const WordBankScreen({super.key, required this.progress});

  final ProgressService progress;

  @override
  State<WordBankScreen> createState() => _WordBankScreenState();
}

class _WordBankScreenState extends State<WordBankScreen> {
  final _narration = NarrationService();
  String? _speaking;

  @override
  void dispose() {
    _narration.dispose();
    super.dispose();
  }

  /// Words from finished lessons, in teaching order. Reviews are skipped
  /// — they re-use words their unit already taught, and a word shouldn't
  /// appear twice.
  List<LessonWord> get _learned {
    final seen = <String>{};
    return [
      for (final lesson in LessonCatalog.lessons)
        if (widget.progress.isCompleted(lesson.id))
          for (final word in lesson.words)
            if (seen.add(word.word)) word,
    ];
  }

  void _say(LessonWord word) {
    setState(() => _speaking = word.word);
    _narration.speak('${word.word}. ${word.text}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word bank')),
      body: ListenableBuilder(
        // The narration service is in here too, so the little speaker
        // badge clears when the device actually stops talking rather
        // than when the call returns.
        listenable: Listenable.merge([widget.progress, _narration]),
        builder: (context, _) {
          final words = _learned;
          final total = LessonCatalog.allWords.length;

          if (words.isEmpty) return const _EmptyBank();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Text(
                      '${words.length} of $total words',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7A756B),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Tap to listen 👂',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9E9889),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    for (final word in words)
                      _WordCard(
                        word: word,
                        isSpeaking:
                            _narration.isSpeaking && _speaking == word.word,
                        onTap: () => _say(word),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({
    required this.word,
    required this.isSpeaking,
    required this.onTap,
  });

  final LessonWord word;
  final bool isSpeaking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: word.color,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Same rule as the lesson cards: a multi-emoji word
                  // shrinks to fit rather than wrapping out of the card.
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        word.emoji,
                        softWrap: false,
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    word.word,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3B3931),
                    ),
                  ),
                ],
              ),
            ),
            if (isSpeaking)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.volume_up_rounded,
                    size: 16, color: Color(0xFF3B3931)),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBank extends StatelessWidget {
  const _EmptyBank();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📖', style: TextStyle(fontSize: 56)),
            SizedBox(height: 14),
            Text(
              'No words yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 6),
            Text(
              'Finish a lesson and every word from it lands here, ready to '
              'listen to again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF7A756B)),
            ),
          ],
        ),
      ),
    );
  }
}
