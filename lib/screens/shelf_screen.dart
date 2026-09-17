import 'package:flutter/material.dart';

import '../data/book_catalog.dart';
import '../models/book.dart';
import '../services/auth_service.dart';
import '../services/entitlement_service.dart';
import 'landing_screen.dart';
import 'paywall_screen.dart';
import 'reader_screen.dart';

/// Home: the bookshelf, with an all-access banner on top.
class ShelfScreen extends StatelessWidget {
  const ShelfScreen({super.key, required this.entitlements, this.auth});

  final EntitlementService entitlements;
  final AuthService? auth;

  void _openBook(BuildContext context, Book book) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReaderScreen(entitlements: entitlements, book: book),
    ));
  }

  void _openSubscribe(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PaywallScreen(entitlements: entitlements),
    ));
  }

  // Signing in (demo or Firebase) ends with pushAndRemoveUntil to Shelf,
  // which clears the landing/onboarding/login stack — including the root
  // route's auth listener that would otherwise swap Shelf back to Landing
  // on sign-out. So sign-out has to navigate explicitly, the same way.
  Future<void> _signOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    await auth?.signOut();
    if (!context.mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LandingScreen(entitlements: entitlements, auth: auth!),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _ShelfDrawer(
        entitlements: entitlements,
        onSubscribeTap: () => _openSubscribe(context),
        onSignOutTap: auth == null ? null : () => _signOut(context),
      ),
      body: ListenableBuilder(
        listenable: entitlements,
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
                  child: entitlements.subscriptionActive
                      ? const _AllAccessBadge()
                      : _SubscribeBanner(onTap: () => _openSubscribe(context)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                sliver: SliverList.separated(
                  itemCount: BookCatalog.books.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final book = BookCatalog.books[i];
                    return _BookRow(
                      book: book,
                      owned: entitlements.hasFullAccess(book.id),
                      subscribed: entitlements.subscriptionActive,
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
                'Every book, plus 2 new books every month.',
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
            child: Text('All Access is active — enjoy every book!',
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
    required this.owned,
    required this.subscribed,
    required this.onTap,
  });

  final Book book;
  final bool owned;
  final bool subscribed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String status = subscribed
        ? 'Included'
        : owned
            ? 'Owned'
            : book.priceLabel;

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
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (owned || subscribed)
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
