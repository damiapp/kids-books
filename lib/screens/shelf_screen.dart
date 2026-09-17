import 'package:flutter/material.dart';

import '../data/book_catalog.dart';
import '../models/book.dart';
import '../services/auth_service.dart';
import '../services/entitlement_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: entitlements,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: const Text('Story Shelf'),
                centerTitle: true,
                actions: [
                  if (auth != null)
                    IconButton(
                      icon: const Icon(Icons.logout_rounded),
                      tooltip: 'Sign out',
                      onPressed: () => auth!.signOut(),
                    ),
                ],
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
