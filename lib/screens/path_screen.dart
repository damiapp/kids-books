import 'dart:math';

import 'package:flutter/material.dart';

import '../data/book_catalog.dart';
import '../models/book.dart';
import '../services/auth_service.dart';
import '../services/energy_service.dart';
import '../services/entitlement_service.dart';
import '../services/reading_progress_service.dart';
import 'landing_screen.dart';
import 'paywall_screen.dart';
import 'reader_screen.dart';

enum _NodeState { completed, current, locked }

/// Home: the learning path. Units stack down the screen, each with a
/// sticky banner and a winding trail of lesson nodes. A lesson unlocks
/// when the one before it is finished.
class PathScreen extends StatefulWidget {
  const PathScreen({
    super.key,
    required this.entitlements,
    required this.progress,
    required this.energy,
    this.auth,
  });

  final EntitlementService entitlements;
  final ReadingProgressService progress;
  final EnergyService energy;
  final AuthService? auth;

  @override
  State<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends State<PathScreen> {
  @override
  void initState() {
    super.initState();
    widget.energy.refresh();
  }

  /// Every lesson, in unlock order.
  List<Book> get _orderedLessons => [
        for (final unit in BookCatalog.units)
          for (final id in unit.bookIds) BookCatalog.byId(id),
      ];

  /// The next lesson to play — the first one not yet finished.
  Book? get _currentLesson {
    for (final book in _orderedLessons) {
      if (!widget.progress.isCompleted(book.id)) return book;
    }
    return null;
  }

  _NodeState _stateOf(Book book) {
    if (widget.progress.isCompleted(book.id)) return _NodeState.completed;
    return book.id == _currentLesson?.id ? _NodeState.current : _NodeState.locked;
  }

  /// How far through the current lesson we are, 0–1, or null if unstarted.
  double? _progressOf(Book book) {
    final step = widget.progress.lastStepFor(book.id);
    if (step == null) return null;
    return (step + 1) / (book.pages.length * 2);
  }

  Future<void> _openLesson(BuildContext context, Book book) async {
    final alreadyStarted = widget.progress.lastStepFor(book.id) != null;
    final isPremium = widget.entitlements.subscriptionActive;

    // Energy is only spent the first time a lesson is opened — resuming or
    // replaying an already-started lesson is always free.
    if (!alreadyStarted && !isPremium) {
      final spent = await widget.energy.spend(EnergyService.costPerLesson);
      if (!spent) {
        if (context.mounted) _showOutOfEnergy(context);
        return;
      }
    }

    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReaderScreen(progress: widget.progress, book: book),
    ));
  }

  void _showLocked(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Finish the lesson before this one first.'),
        duration: Duration(seconds: 2),
      ));
  }

  void _showOutOfEnergy(BuildContext context) {
    final wait = widget.energy.timeUntilNext;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Out of energy'),
        content: Text(
          wait == null
              ? 'Come back soon for more energy, or get All Access for unlimited energy.'
              : 'More energy in about ${_formatWait(wait)}, or get All Access for unlimited energy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _openSubscribe(context);
            },
            child: const Text('Get All Access'),
          ),
        ],
      ),
    );
  }

  String _formatWait(Duration d) {
    final minutes = d.inMinutes + (d.inSeconds % 60 > 0 ? 1 : 0);
    return minutes <= 1 ? '1 minute' : '$minutes minutes';
  }

  void _openSubscribe(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PaywallScreen(entitlements: widget.entitlements),
    ));
  }

  // Signing in (demo or Firebase) ends with pushAndRemoveUntil to here,
  // which clears the landing/onboarding/login stack — including the root
  // route's auth listener that would otherwise swap back to Landing on
  // sign-out. So sign-out has to navigate explicitly, the same way.
  Future<void> _signOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    await widget.auth?.signOut();
    if (!context.mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LandingScreen(
          entitlements: widget.entitlements,
          auth: widget.auth!,
          progress: widget.progress,
          energy: widget.energy,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _PathDrawer(
        entitlements: widget.entitlements,
        onSubscribeTap: () => _openSubscribe(context),
        onSignOutTap: widget.auth == null ? null : () => _signOut(context),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge(
              [widget.entitlements, widget.progress, widget.energy]),
          builder: (context, _) {
            final completedCount = _orderedLessons
                .where((b) => widget.progress.isCompleted(b.id))
                .length;

            return Column(
              children: [
                _TopBar(
                  energy: widget.energy,
                  isPremium: widget.entitlements.subscriptionActive,
                  completedCount: completedCount,
                  onEnergyTap: () => _openSubscribe(context),
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      for (final unit in BookCatalog.units) ...[
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _UnitHeaderDelegate(
                            unit: unit,
                            doneCount: unit.bookIds
                                .where(widget.progress.isCompleted)
                                .length,
                          ),
                        ),
                        SliverList.builder(
                          // One node per lesson, plus a trophy to close the unit.
                          itemCount: unit.bookIds.length + 1,
                          itemBuilder: (context, i) {
                            if (i == unit.bookIds.length) {
                              final unitDone = unit.bookIds
                                  .every(widget.progress.isCompleted);
                              return _PathRow(
                                index: i,
                                child: _PathNode(
                                  state: unitDone
                                      ? _NodeState.completed
                                      : _NodeState.locked,
                                  icon: Icons.emoji_events_rounded,
                                  onTap: unitDone
                                      ? null
                                      : () => _showLocked(context),
                                ),
                              );
                            }

                            final book = BookCatalog.byId(unit.bookIds[i]);
                            final state = _stateOf(book);
                            return _PathRow(
                              index: i,
                              label: book.title,
                              child: _PathNode(
                                state: state,
                                icon: state == _NodeState.completed
                                    ? Icons.star_rounded
                                    : state == _NodeState.current
                                        ? Icons.play_arrow_rounded
                                        : Icons.lock_rounded,
                                emoji: state == _NodeState.locked
                                    ? null
                                    : book.coverEmoji,
                                progress: state == _NodeState.current
                                    ? _progressOf(book)
                                    : null,
                                showStart: state == _NodeState.current,
                                onTap: state == _NodeState.locked
                                    ? () => _showLocked(context)
                                    : () => _openLesson(context, book),
                              ),
                            );
                          },
                        ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Stat header: menu, energy, lessons finished, All Access pill.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.energy,
    required this.isPremium,
    required this.completedCount,
    required this.onEnergyTap,
  });

  final EnergyService energy;
  final bool isPremium;
  final int completedCount;
  final VoidCallback onEnergyTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const Spacer(),
          _Stat(
            emoji: '⚡',
            label: isPremium ? '∞' : '${energy.current}',
            color: const Color(0xFFE0A100),
            onTap: isPremium ? null : onEnergyTap,
          ),
          const SizedBox(width: 14),
          _Stat(
            emoji: '⭐',
            label: '$completedCount',
            color: scheme.primary,
          ),
          if (isPremium) ...[
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'ALL ACCESS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.emoji,
    required this.label,
    required this.color,
    this.onTap,
  });

  final String emoji;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitHeaderDelegate extends SliverPersistentHeaderDelegate {
  _UnitHeaderDelegate({required this.unit, required this.doneCount});

  final LessonUnit unit;
  final int doneCount;

  @override
  double get minExtent => 88;

  @override
  double get maxExtent => 88;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: unit.color,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      unit.section,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      unit.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$doneCount/${unit.bookIds.length}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _UnitHeaderDelegate old) =>
      old.unit != unit || old.doneCount != doneCount;
}

/// Places a node along the winding trail, with its title underneath.
class _PathRow extends StatelessWidget {
  const _PathRow({required this.index, required this.child, this.label});

  final int index;
  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    // Sine offset gives the centre → right → right → centre → left → left
    // zigzag of a Duolingo-style trail.
    final width = MediaQuery.sizeOf(context).width;
    final amplitude = min(96.0, width * 0.24);
    final dx = sin(index * pi / 3) * amplitude;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Column(
          children: [
            child,
            if (label != null) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: 140,
                child: Text(
                  label!,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A756B),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One circular stop on the trail, with the chunky pressed-button look.
class _PathNode extends StatelessWidget {
  const _PathNode({
    required this.state,
    required this.icon,
    this.emoji,
    this.progress,
    this.showStart = false,
    this.onTap,
  });

  final _NodeState state;
  final IconData icon;
  final String? emoji;
  final double? progress;
  final bool showStart;
  final VoidCallback? onTap;

  static const _size = 78.0;
  static const _depth = 7.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color face = switch (state) {
      _NodeState.completed => const Color(0xFFF0B429),
      _NodeState.current => scheme.primary,
      _NodeState.locked => const Color(0xFFE6E2D9),
    };
    final Color rim = switch (state) {
      _NodeState.completed => const Color(0xFFCE9414),
      _NodeState.current => const Color(0xFF2B807B),
      _NodeState.locked => const Color(0xFFCFCABD),
    };
    final Color foreground =
        state == _NodeState.locked ? const Color(0xFF9E9889) : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showStart) ...[
          _StartBubble(color: scheme.primary),
          const SizedBox(height: 6),
        ],
        SizedBox(
          width: _size + 16,
          height: _size + _depth + 16,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              if (progress != null)
                Positioned(
                  top: 0,
                  child: SizedBox(
                    width: _size + 14,
                    height: _size + 14,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: const Color(0xFFE6E2D9),
                    ),
                  ),
                ),
              Positioned(
                top: 7 + _depth,
                child: Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(color: rim, shape: BoxShape.circle),
                ),
              ),
              Positioned(
                top: 7,
                child: Material(
                  color: face,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onTap,
                    child: SizedBox(
                      width: _size,
                      height: _size,
                      child: Center(
                        child: emoji == null
                            ? Icon(icon, size: 36, color: foreground)
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(emoji!,
                                      style: const TextStyle(fontSize: 30)),
                                  Icon(icon, size: 16, color: foreground),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StartBubble extends StatelessWidget {
  const _StartBubble({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E2D9), width: 2),
          ),
          child: Text(
            'START',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -3),
          child: Transform.rotate(
            angle: pi / 4,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: const Color(0xFFE6E2D9), width: 2),
                  bottom: BorderSide(color: const Color(0xFFE6E2D9), width: 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PathDrawer extends StatelessWidget {
  const _PathDrawer({
    required this.entitlements,
    required this.onSubscribeTap,
    this.onSignOutTap,
  });

  final EntitlementService entitlements;
  final VoidCallback onSubscribeTap;
  final VoidCallback? onSignOutTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subscribed = entitlements.subscriptionActive;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              color: scheme.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📚', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 10),
                  const Text('Story Shelf',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    subscribed ? 'All Access active' : 'Free plan',
                    style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.school_rounded),
              title: const Text('Learn'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(subscribed
                  ? Icons.verified_rounded
                  : Icons.workspace_premium_rounded),
              title: Text(subscribed ? 'All Access' : 'Subscribe'),
              onTap: () {
                Navigator.pop(context);
                onSubscribeTap();
              },
            ),
            if (onSignOutTap != null) ...[
              const Spacer(),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Sign out'),
                onTap: () {
                  Navigator.pop(context);
                  onSignOutTap!();
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
