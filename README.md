
# Story Shelf — kids' books platform (Android first)

A Flutter app where you publish picture books. Readers can **buy a single book**
or **subscribe for all books + every new release**. Payments go through
**Google Play Billing**, wrapped by **RevenueCat**.

It ships in **demo mode**, so you can run it and click the whole buy/subscribe
flow today with no store account.

---

## 1. Run it (demo mode, on Linux/SteamOS)

This folder contains only `lib/` and `pubspec.yaml`. Generate the Android
platform folders, then run:

```bash
cd kids_books
flutter create .            # adds android/ (and other platforms) around lib/
flutter pub get
flutter run                 # with an Android device/emulator connected
```

Everything above works on Linux — no Mac needed for Android. (iOS builds will
need macOS/Xcode or a cloud-Mac CI later; we're doing Android first.)

In demo mode, "Buy" and "Subscribe" just flip a locally-saved flag so you can
test the reading/paywall UX.

---

## 1b. Get an installable APK (no local Flutter needed)

A GitHub Actions workflow (`.github/workflows/build-apk.yml`) builds a real APK
in the cloud:

1. Create a new GitHub repo and push this folder to its `main` branch.
2. The build runs automatically (or trigger it from the **Actions** tab →
   *Build APK* → *Run workflow*).
3. When it finishes (~2–3 min), open the run and download the
   **kids-books-apk** artifact — inside is `app-release.apk`.
4. Copy it to your phone, allow "install unknown apps" for your file manager,
   and tap to install.

This installs the **demo** build (no Play account needed) — the buy/subscribe
buttons flip a local flag, exactly like the web preview.

*Building locally instead (Linux/SteamOS):* SteamOS has an immutable root, so
install the toolchain inside a container — `distrobox create -n flutter -i
archlinux`, enter it, install `jdk17-openjdk`, the Android command-line tools,
and Flutter (all in your home dir), then run
`flutter create --platforms=android . && flutter pub get && flutter build apk`.
The APK lands in `build/app/outputs/flutter-apk/`.

---

## 1c. Turning on real sign-in (Firebase Authentication)

The app now opens with a **landing page → a 2-slide "what is this app"
explainer → an email/password sign-in screen**, backed by **Firebase
Authentication**. It ships with placeholder Firebase config, so it builds
and runs today — sign-in/sign-up will just fail with an "API key not
valid" error until you plug in a real project:

1. Create a project at https://console.firebase.google.com.
2. **Build → Authentication → Get started → Sign-in method** → enable
   **Email/Password**.
3. **Project settings → General → Your apps** → add an Android app (package
   name `rs.stasa.kids_books`, matching the workflow's `--org rs.stasa`).
4. Copy the config values shown (API key, App ID, Messaging sender ID,
   Project ID) into `lib/firebase_options.dart`, replacing the
   `YOUR_FIREBASE_*` placeholders in the `android` `FirebaseOptions`.

Unlike the RevenueCat/Play key elsewhere in this app, Firebase's client
config isn't a secret — it's meant to ship inside the app. Access is
controlled by Firebase Auth and security rules, not by hiding these values,
so it's fine to commit real ones here.

Once signed in, tap the sign-out icon in the shelf's app bar to go back
through landing → onboarding → login again.

**Try it now without any Firebase setup** — the login screen has two
"instant" demo accounts (`lib/data/demo_accounts.dart`) that bypass
Firebase entirely and set local entitlements to match:

| Account | Email | Password | Entitlements |
|---|---|---|---|
| 👑 All Access subscriber | `subscriber@demo.storyshelf.app` | `demo1234` | Subscription active — every book unlocked |
| 🙂 Brand-new user | `newuser@demo.storyshelf.app` | `demo1234` | Nothing owned, no subscription |

Tap either button on the login screen to sign in instantly, or type the
credentials by hand. These only work for sign-in, not the "create account"
flow, and never touch your Firebase project.

---

## 2. What's inside

```
lib/
  models/book.dart                        Book (+ ageRange, genres) + BookPage
  data/book_catalog.dart                  the 3 sample books (+ sub price label)
  data/demo_accounts.dart                 instant-login demo accounts (§1c)
  services/entitlement_service.dart       access rules + DemoEntitlementService
  services/revenuecat_entitlement_service.dart   production (Google Play Billing)
  services/auth_service.dart              Firebase email/password sign-in
  screens/landing_screen.dart             first screen: app name + tagline
  screens/onboarding_screen.dart          2-slide "what is this app" explainer
  screens/login_screen.dart               email/password sign in & sign up
  screens/shelf_screen.dart               home shelf + subscribe banner
  screens/reader_screen.dart              page reader + paywall wall
  screens/paywall_screen.dart             buy-book vs subscribe
  firebase_options.dart                   Firebase config (placeholder — see §1c)
  main.dart                               swap Demo <-> RevenueCat here
```

**Access rule (one place, `entitlement_service.dart`):**
`full access to a book = active subscription OR that book was bought`.
Preview pages are always free.

This is why "all upcoming books" is free: adding a book to the catalog needs
no per-book wiring — subscribers already pass the `subscriptionActive` check.

---

## 3. Going live with Google Play Billing + RevenueCat

**Google Play Console**
1. Create the app, upload a signed build to a test track.
2. **In-app products** → one *managed (non-consumable)* product per book, using
   each book's `playProductId` (`book_animals`, `book_colours`, `book_numbers`).
3. **Subscriptions** → create one subscription with a monthly base plan
   (add an annual base plan too if you want).
4. Add **license testers** so you can buy without being charged.

**RevenueCat**
1. Add your Android app + Play service-account credentials.
2. Create entitlement **`all_access`** and attach the subscription product to it.
3. Create an **Offering** whose current package is that subscription.
4. Copy your public Android SDK key (`goog_…`).

**Switch the app to production** — in `main.dart`, comment out the demo line and
use:
```dart
final EntitlementService entitlements = RevenueCatEntitlementService(
  apiKey: 'goog_YOUR_ANDROID_PUBLIC_KEY',
);
```
Also uncomment the RevenueCat import at the top.

> `purchases_flutter`'s API shifts between major versions — check method
> signatures in `revenuecat_entitlement_service.dart` against the version you
> pin. Prices shown in the app should come from the store, not the
> `priceLabel`/`kSubscriptionPriceLabel` placeholders (those are demo-only).

---

## 4. Shipping "2 new books a month" without an app update

Right now the catalog is bundled in the app, so a new book means a new release.
To publish without going through review each time, move `book_catalog.dart` to a
**JSON manifest + images served from Cloudflare R2** (zero egress fees) and fetch
it at startup. Subscribers unlock new books instantly; buyers see them for sale.
That's the point where your earlier Cloudflare instinct pays off.

## 5. Replacing the placeholder art

Pages use emoji as stand-in art. For real illustrations, add an `imageUrl`
(R2-hosted) or bundled `imageAsset` to `BookPage` and render it in
`reader_screen.dart` instead of the emoji `Text`.
