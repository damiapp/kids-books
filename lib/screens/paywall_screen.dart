import 'package:flutter/material.dart';

import '../data/book_catalog.dart';
import '../models/book.dart';
import '../services/entitlement_service.dart';

/// Two ways to unlock: buy this one book, or subscribe to everything.
/// Pass [book] to show the single-book option; omit it for a subscribe-only screen.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, required this.entitlements, this.book});

  final EntitlementService entitlements;
  final Book? book;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _busy = false;

  Future<void> _run(Future<bool> Function() action) async {
    setState(() => _busy = true);
    try {
      final ok = await action();
      if (ok && mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Scaffold(
      appBar: AppBar(title: const Text('Unlock')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // ── All-access subscription (the headline option) ──
            _OptionCard(
              highlight: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📚  All Access',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text(
                    'Every book, plus 2 brand-new books every month — '
                    'unlocked automatically as soon as they arrive.',
                    style: TextStyle(fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Text(kSubscriptionPriceLabel,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _run(widget.entitlements.subscribe),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    child: const Text('Subscribe'),
                  ),
                ],
              ),
            ),

            // ── Single book ──
            if (book != null) ...[
              const SizedBox(height: 16),
              _OptionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${book.coverEmoji}  ${book.title}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Buy this book once, keep it forever.',
                        style: TextStyle(fontSize: 15)),
                    const SizedBox(height: 16),
                    Text(book.priceLabel,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          _run(() => widget.entitlements.purchaseBook(book)),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50)),
                      child: Text('Buy ${book.title}'),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => _run(() async {
                  await widget.entitlements.restore();
                  return false; // stay on screen; state updates if anything restored
                }),
                child: const Text('Restore purchases'),
              ),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.child, this.highlight = false});

  final Widget child;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlight ? scheme.primaryContainer : scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlight ? scheme.primary : scheme.outlineVariant,
          width: highlight ? 2 : 1,
        ),
      ),
      child: child,
    );
  }
}
