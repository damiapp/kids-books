import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';

/// The single source of truth for "what can this person read?".
/// The UI never talks to a billing SDK directly — it only asks this.
///
/// Access rule:
///   full access to a book  =  active subscription  OR  that book was bought.
///   preview pages          =  always free.
abstract class EntitlementService extends ChangeNotifier {
  /// True while an all-access subscription is active.
  bool get subscriptionActive;

  /// Ids of books bought individually.
  Set<String> get ownedBookIds;

  bool hasFullAccess(String bookId) =>
      subscriptionActive || ownedBookIds.contains(bookId);

  /// Whether a specific page is readable right now.
  bool canRead(Book book, int pageIndex) =>
      hasFullAccess(book.id) || pageIndex < book.previewPages;

  Future<void> init();

  /// Buy a single book. Returns true if it's now owned.
  Future<bool> purchaseBook(Book book);

  /// Start the all-access subscription. Returns true if now active.
  Future<bool> subscribe();

  /// Restore past purchases — required to be available on both stores.
  Future<void> restore();
}

/// Runs with zero store setup so you can click the entire flow today.
/// Persists locally. NOT real money.
class DemoEntitlementService extends EntitlementService {
  static const _subKey = 'demo_subscription_active';
  static const _ownedKey = 'demo_owned_book_ids';

  bool _sub = false;
  final Set<String> _owned = {};

  @override
  bool get subscriptionActive => _sub;

  @override
  Set<String> get ownedBookIds => Set.unmodifiable(_owned);

  @override
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _sub = prefs.getBool(_subKey) ?? false;
    final raw = prefs.getString(_ownedKey);
    if (raw != null) {
      _owned
        ..clear()
        ..addAll((jsonDecode(raw) as List).cast<String>());
    }
    notifyListeners();
  }

  @override
  Future<bool> purchaseBook(Book book) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _owned.add(book.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ownedKey, jsonEncode(_owned.toList()));
    notifyListeners();
    return true;
  }

  @override
  Future<bool> subscribe() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _sub = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subKey, true);
    notifyListeners();
    return true;
  }

  @override
  Future<void> restore() => init();
}
