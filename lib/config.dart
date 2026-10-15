/// Build-time switches. Set with `--dart-define=NAME=true` on
/// `flutter build`; everything defaults to off.
library;

/// Whether the subscription is real.
///
/// Off until RevenueCat and Google Play Billing are connected (README §3,
/// RELEASE_PLAN.md step 8). While it's off, nothing in the app offers a
/// subscription — the demo purchase flow charges nothing, and a release
/// must never promise something it doesn't do. The paywall and the
/// purchase code stay in place; only the ways to reach them disappear.
///
/// The demo subscriber account still works with this off, so unlimited
/// energy can be tested without it.
const bool kPaymentsLive = bool.fromEnvironment('PAYMENTS_LIVE');
