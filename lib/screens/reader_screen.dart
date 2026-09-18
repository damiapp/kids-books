import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/entitlement_service.dart';
import '../services/narration_service.dart';
import 'paywall_screen.dart';

/// Swipe through one book. Preview pages are free; the first locked page shows
/// the paywall wall — the "pay per view" moment.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.entitlements, required this.book});

  final EntitlementService entitlements;
  final Book book;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _controller = PageController();
  final _narration = NarrationService();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    _narration.dispose();
    super.dispose();
  }

  void _openPaywall() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          PaywallScreen(entitlements: widget.entitlements, book: widget.book),
    ));
  }

  void _toggleSpeak(BookPage page) {
    if (_narration.isSpeaking) {
      _narration.stop();
    } else {
      _narration.speak('${page.word}. ${page.text}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([widget.entitlements, _narration]),
        builder: (context, _) {
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
                        child: Text(
                          book.title,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Center(
                          child: Text(
                            '${_index + 1}/${book.pages.length}',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF7A756B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) {
                      _narration.stop();
                      setState(() => _index = i);
                    },
                    itemCount: book.pages.length,
                    itemBuilder: (context, i) {
                      final canRead = widget.entitlements.canRead(book, i);
                      final page = book.pages[i];
                      return canRead
                          ? _PageView(
                              page: page,
                              isSpeaking: _narration.isSpeaking,
                              onSpeak: () => _toggleSpeak(page),
                            )
                          : _LockedView(book: book, onUnlock: _openPaywall);
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

class _PageView extends StatelessWidget {
  const _PageView({
    required this.page,
    required this.isSpeaking,
    required this.onSpeak,
  });

  final BookPage page;
  final bool isSpeaking;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                        fontSize: 18, height: 1.4, color: Color(0xFF534F48)),
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
    );
  }
}

class _LockedView extends StatelessWidget {
  const _LockedView({required this.book, required this.onUnlock});

  final Book book;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EEE7),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 44, color: Color(0xFF7A756B)),
            const SizedBox(height: 14),
            const Text(
              'Keep reading',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3D3A34)),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Buy “${book.title}”, or subscribe to unlock every book.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Color(0xFF534F48)),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onUnlock,
              style: FilledButton.styleFrom(minimumSize: const Size(220, 52)),
              child: const Text('See options'),
            ),
          ],
        ),
      ),
    );
  }
}
