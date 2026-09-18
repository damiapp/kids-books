import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'entitlement_service.dart';

/// Production entitlements via RevenueCat (which runs on Google Play Billing).
///
/// SETUP (see README for the full walkthrough):
///  1. Play Console → create one Subscription with a monthly base plan.
///  2. RevenueCat → add your Android app + Play credentials.
///  3. RevenueCat → create entitlement `all_access`, attach it to the subscription.
///  4. RevenueCat → create an Offering whose current package is that subscription.
///  5. main.dart → use this class with your public `goog_…` key.
///
/// Subscribers get unlimited energy (see EnergyService); everyone else
/// spends energy per lesson, tracked purely locally — there's nothing to
/// buy per lesson, so there's nothing else to sync from the store.
class RevenueCatEntitlementService extends EntitlementService {
  RevenueCatEntitlementService({
    required this.apiKey,
    this.allAccessEntitlementId = 'all_access',
  });

  final String apiKey;
  final String allAccessEntitlementId;

  bool _sub = false;

  @override
  bool get subscriptionActive => _sub;

  @override
  Future<void> init() async {
    await Purchases.setLogLevel(LogLevel.info);
    await Purchases.configure(PurchasesConfiguration(apiKey));
    Purchases.addCustomerInfoUpdateListener(_apply);
    _apply(await Purchases.getCustomerInfo());
  }

  void _apply(CustomerInfo info) {
    _sub = info.entitlements.active.containsKey(allAccessEntitlementId);
    notifyListeners();
  }

  @override
  Future<bool> subscribe() async {
    final offerings = await Purchases.getOfferings();
    final package = offerings.current?.availablePackages.firstOrNull;
    if (package == null) return false;
    try {
      await Purchases.purchasePackage(package);
    } on PlatformException {
      _apply(await Purchases.getCustomerInfo());
      return _sub;
    }
    _apply(await Purchases.getCustomerInfo());
    return _sub;
  }

  @override
  Future<void> restore() async {
    _apply(await Purchases.restorePurchases());
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
