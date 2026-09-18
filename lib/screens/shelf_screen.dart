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

/// Home: the lesson shelf, with an energy bar, continue-lesson card,
/// search, and a filter sheet (genre / age / favorites) on top.
class ShelfScreen extends StatefulWidget {
  const ShelfScreen({
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
  State<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends State<ShelfScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedGenre;
  String? _selectedAge;
  bool _favoritesOnly = false;

  bool get _hasActiveFilter =>
      _selectedGenre != null || _selectedAge != null || _favoritesOnly;

  @override
  void initState() {
    super.initState();
    widget.energy.refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openBook(BuildContext context, Book book) async {
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

  // Signing in (demo or Firebase) ends with pushAndRemoveUntil to Shelf,
  // which clears the landing/onboarding/login stack — including the root
  // route's auth listener that would otherwise swap Shelf back to Landing
  // on sign-out. So sign-out has to navigate explicitly, the same way.
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

  Future<void> _openFilterSheet(List<String> genres, List<String> ages) async {
    final result = await showModalBottomSheet<_FilterSelection>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheet(
        genres: genres,
        ages: ages,
        initial: _FilterSelection(
          genre: _selectedGenre,
          age: _selectedAge,
          favoritesOnly: _favoritesOnly,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedGenre = result.genre;
        _selectedAge = result.age;
        _favoritesOnly = result.favoritesOnly;
      });
    }
  }

  List<Book> get _filteredBooks {
    final query = _query.trim().toLowerCase();
    return BookCatalog.books.where((book) {
      if (_selectedGenre != null && !book.genres.contains(_selectedGenre)) {
        return false;
      }
      if (_selectedAge != null && book.ageRange != _selectedAge) {
        return false;
      }
      if (_favoritesOnly && !widget.progress.isFavorite(book.id)) {
        return false;
      }
      if (query.isNotEmpty &&
          !book.title.toLowerCase().contains(query) &&
          !book.subtitle.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// First lesson that's been started but not finished, if any.
  (Book, int)? get _continueLesson {
    for (final book in BookCatalog.books) {
      final step = widget.progress.lastStepFor(book.id);
      if (step != null && !widget.progress.isCompleted(book.id)) {
        return (book, step);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final genres = {for (final b in BookCatalog.books) ...b.genres}.toList()
      ..sort();
    final ages = {for (final b in BookCatalog.books) b.ageRange}.toList()
      ..sort();
    final books = _filteredBooks;
    final continueLesson = _continueLesson;

    return Scaffold(
      drawer: _ShelfDrawer(
        entitlements: widget.entitlements,
        onSubscribeTap: () => _openSubscribe(context),
        onSignOutTap: widget.auth == null ? null : () => _signOut(context),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge(
            [widget.entitlements, widget.progress, widget.energy]),
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              const SliverAppBar.large(
                title: Text('Story Shelf'),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: widget.entitlements.subscriptionActive
                      ? const _AllAccessBadge()
                      : Column(
                          children: [
                            _EnergyBar(
                              energy: widget.energy,
                              onTap: () => _openSubscribe(context),
                            ),
                            const SizedBox(height: 8),
                            _SubscribeBanner(onTap: () => _openSubscribe(context)),
                          ],
                        ),
                ),
              ),
              if (continueLesson != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _ContinueLessonCard(
                      book: continueLesson.$1,
                      stepIndex: continueLesson.$2,
                      totalSteps: continueLesson.$1.pages.length * 2,
                      onTap: () => _openBook(context, continueLesson.$1),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            hintText: 'Search lessons',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                  ),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Badge(
                        isLabelVisible: _hasActiveFilter,
                        smallSize: 9,
                        child: IconButton.filledTonal(
                          onPressed: () => _openFilterSheet(genres, ages),
                          tooltip: 'Filter lessons',
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (books.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 32, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        'No lessons match — try a different filter.',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  sliver: SliverList.separated(
                    itemCount: books.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final book = books[i];
                      return _BookRow(
                        book: book,
                        started: widget.progress.lastStepFor(book.id) != null,
                        completed: widget.progress.isCompleted(book.id),
                        isFavorite: widget.progress.isFavorite(book.id),
                        onToggleFavorite: () =>
                            widget.progress.toggleFavorite(book.id),
                        onTap: () => _openBook(context, book),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EnergyBar extends StatelessWidget {
  const _EnergyBar({required this.energy, required this.onTap});

  final EnergyService energy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: energy.current / EnergyService.maxEnergy,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${energy.current}/${EnergyService.maxEnergy}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSelection {
  const _FilterSelection({this.genre, this.age, this.favoritesOnly = false});

  final String? genre;
  final String? age;
  final bool favoritesOnly;
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.genres,
    required this.ages,
    required this.initial,
  });

  final List<String> genres;
  final List<String> ages;
  final _FilterSelection initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _genre;
  String? _age;
  bool _favoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _genre = widget.initial.genre;
    _age = widget.initial.age;
    _favoritesOnly = widget.initial.favoritesOnly;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Filter lessons',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Favorites only'),
              secondary: const Icon(Icons.favorite_rounded),
              value: _favoritesOnly,
              onChanged: (value) => setState(() => _favoritesOnly = value),
            ),
            if (widget.genres.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Genre', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All genres'),
                    selected: _genre == null,
                    onSelected: (_) => setState(() => _genre = null),
                  ),
                  for (final genre in widget.genres)
                    ChoiceChip(
                      label: Text(genre),
                      selected: _genre == genre,
                      onSelected: (_) =>
                          setState(() => _genre = _genre == genre ? null : genre),
                    ),
                ],
              ),
            ],
            if (widget.ages.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Age', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All ages'),
                    selected: _age == null,
                    onSelected: (_) => setState(() => _age = null),
                  ),
                  for (final age in widget.ages)
                    ChoiceChip(
                      label: Text('Ages $age'),
                      selected: _age == age,
                      onSelected: (_) =>
                          setState(() => _age = _age == age ? null : age),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _genre = null;
                      _age = null;
                      _favoritesOnly = false;
                    }),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      _FilterSelection(
                        genre: _genre,
                        age: _age,
                        favoritesOnly: _favoritesOnly,
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueLessonCard extends StatelessWidget {
  const _ContinueLessonCard({
    required this.book,
    required this.stepIndex,
    required this.totalSteps,
    required this.onTap,
  });

  final Book book;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: book.coverColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(book.coverEmoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Continue lesson',
                        style:
                            TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${book.title} · step ${stepIndex + 1} of $totalSteps',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
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

class _ShelfDrawer extends StatelessWidget {
  const _ShelfDrawer({
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
              leading: const Icon(Icons.auto_stories_rounded),
              title: const Text('Shelf'),
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

class _SubscribeBanner extends StatelessWidget {
  const _SubscribeBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('All Access',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text(
                'Unlimited energy — never wait to start a lesson.',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(kSubscriptionPriceLabel,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  FilledButton(onPressed: onTap, child: const Text('Subscribe')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllAccessBadge extends StatelessWidget {
  const _AllAccessBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('All Access is active — unlimited energy!',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({
    required this.book,
    required this.started,
    required this.completed,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onTap,
  });

  final Book book;
  final bool started;
  final bool completed;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String status = completed
        ? 'Done'
        : started
            ? 'In progress'
            : 'New';

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: book.coverColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(book.coverEmoji,
                    style: const TextStyle(fontSize: 36)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(book.subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF7A756B))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Tag(label: 'Ages ${book.ageRange}'),
                        for (final genre in book.genres) _Tag(label: genre),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFavorite ? const Color(0xFFE0637A) : null,
                ),
                onPressed: onToggleFavorite,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: completed
                      ? const Color(0xFFDCF0DC)
                      : Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
