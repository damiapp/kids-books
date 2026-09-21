
# Peekado — a Duolingo-style lesson app for kids 3+ (Android first)

A Flutter app of short listen-then-practice lessons for early learners. Each
lesson teaches a word (picture + sound), then quizzes it back with a
tap-the-match exercise — kids see it, hear it, then try it themselves.
You swipe between steps; a practice step won't let you swipe past until
the right picture is tapped.

Access is **energy**, not per-item purchase: everyone gets a capped pool of
energy that's spent to start a lesson and slowly refills over time; **All
Access** (a subscription via **Google Play Billing**, wrapped by
**RevenueCat**) removes the cap entirely.

It ships in **demo mode**, so you can run it and click through lessons,
energy, and the subscription flow today with no store account.

---

## 1. Run it (demo mode, on Linux/SteamOS)

This folder contains only `lib/` and `pubspec.yaml`. Generate the Android
platform folders, then run:

```bash
cd peekado
flutter create .            # adds android/ (and other platforms) around lib/
flutter pub get
flutter run                 # with an Android device/emulator connected
```

Everything above works on Linux — no Mac needed for Android. (iOS builds will
need macOS/Xcode or a cloud-Mac CI later; we're doing Android first.)

In demo mode, energy and "Subscribe" are tracked with locally-saved state so
you can test the whole lesson/energy/paywall UX with no store account.

---

## 1b. Get an installable APK (no local Flutter needed)

A GitHub Actions workflow (`.github/workflows/build-apk.yml`) builds a real APK
in the cloud:

1. Create a new GitHub repo and push this folder to its `main` branch.
2. The build runs automatically (or trigger it from the **Actions** tab →
   *Build* → *Run workflow*).
3. When it finishes (~2–3 min), open the run and download the
   **peekado-apk** artifact — inside is `app-release.apk`.
4. Copy it to your phone, allow "install unknown apps" for your file manager,
   and tap to install.

This installs the **demo** build (no Play account needed) — energy and
subscription state are tracked locally, exactly like the web preview.

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
   name `app.peekado`, matching the workflow's `--org app --project-name
   peekado`). Add an iOS app with the same id as the bundle id if you're
   building for iPhone too (§1d) — it's a separate registration with its
   own API key and app id.
4. Copy the config values shown (API key, App ID, Messaging sender ID,
   Project ID) into `lib/firebase_options.dart`, replacing the
   `YOUR_FIREBASE_*` placeholders in the `android` (and `ios`)
   `FirebaseOptions`.

Unlike the RevenueCat/Play key elsewhere in this app, Firebase's client
config isn't a secret — it's meant to ship inside the app. Access is
controlled by Firebase Auth and security rules, not by hiding these values,
so it's fine to commit real ones here.

Once signed in, open the left-hand menu and tap **Sign out** to go back
through landing → onboarding → login again.

**Try it now without any Firebase setup** — the login screen has two
"instant" demo accounts (`lib/data/demo_accounts.dart`) that bypass
Firebase entirely and set local entitlements to match:

| Account | Email | Password | Entitlements |
|---|---|---|---|
| 👑 All Access subscriber | `subscriber@demo.peekado.app` | `demo1234` | Subscription active — unlimited energy |
| 🙂 Brand-new user | `newuser@demo.peekado.app` | `demo1234` | Free plan — limited energy, refills over time |

Tap either button on the login screen to sign in instantly, or type the
credentials by hand. These only work for sign-in, not the "create account"
flow, and never touch your Firebase project.

---

## 1d. iPhone builds

The same workflow has an **`ios` job** on a macOS runner that runs
`flutter build ios --release --no-codesign`. macOS runners bill at 10x
the rate of Linux ones, but this repo is public, so those minutes are
free.

**What that job is, and isn't:** it's a compile check. It proves the app
builds for iOS — pods resolve, every plugin has an iOS implementation,
the deployment target lines up — and it uploads a
`peekado-ios-unsigned` artifact. It does **not** produce something you
can install on a phone. iOS has no equivalent of sideloading an APK: an
app must be signed by a registered Apple developer, and the phone checks
that signature at install time.

**To actually get it onto an iPhone** you need an
[Apple Developer Program](https://developer.apple.com/programs/)
membership (**$99/year** — there's no free tier that CI can use). With
one, the path is entirely in CI, no Mac required:

1. In **App Store Connect**, create the app record (bundle id
   `app.peekado`) and an **API key** (Users and Access → Integrations).
2. Create a **distribution certificate** and an **App Store provisioning
   profile**, and export the certificate as a `.p12`.
3. Add them as repo secrets — the certificate (base64), its password,
   the profile (base64), and the API key id/issuer id/`.p8` contents.
4. Swap the `ios` job's `--no-codesign` for an import step
   ([`apple-actions/import-codesign-certs`](https://github.com/apple-actions/import-codesign-certs)),
   `flutter build ipa`, and an upload to TestFlight with
   `xcrun altool`/`fastlane pilot`.
5. Install from the **TestFlight** app on the phone. Builds arrive as
   updates, so — unlike the Android side today — there's no
   uninstall-and-lose-progress step.

**Without the $99:** a free Apple ID can sign an app for your own device
through Xcode or Sideloadly, but it expires after **7 days** and needs a
Mac (or Windows, for Sideloadly) with the phone plugged in. CI can't do
it, so it doesn't fit this workflow.

Also worth knowing before shipping to iOS: the subscription has to go
through **StoreKit / App Store Connect** rather than Google Play —
RevenueCat covers both behind the same `EntitlementService`, but it's a
second set of products to configure (§3).

The `ios` job regenerates `ios/` with `flutter create` on every run, the
same way the Android job does, so
`.github/scripts/ios_deployment_target.py` re-applies the iOS 15
deployment target each time — Flutter's template still writes 13, and
`firebase_core` 4.x refuses to install pods below 15.

---

## 2. What's inside

```
lib/
  models/lesson.dart                      Lesson (title, cover, words) + LessonWord
  data/lesson_catalog.dart                the 14 lessons + the path's units
  data/demo_accounts.dart                 instant-login demo accounts (§1c)
  services/entitlement_service.dart       subscription state + DemoEntitlementService
  services/revenuecat_entitlement_service.dart   production (Google Play Billing)
  services/energy_service.dart            energy pool: spend, regen over time
  services/progress_service.dart          per-lesson step + completion
  services/narration_service.dart         read-aloud / practice-prompt TTS
  services/auth_service.dart              Firebase email/password sign-in
  screens/landing_screen.dart             first screen: app name + tagline
  screens/onboarding_screen.dart          2-slide "what is this app" explainer
  screens/login_screen.dart               email/password sign in & sign up
  screens/path_screen.dart                learning path: units + winding lesson trail
  screens/lesson_screen.dart              lesson player: swipe through learn + practice steps
  screens/paywall_screen.dart             All Access (unlimited energy) upsell
  firebase_options.dart                   Firebase config (placeholder — see §1c)
  main.dart                               swap Demo <-> RevenueCat here
```

**The path:** `LessonCatalog.units` defines the trail — each unit is an
ordered list of lesson ids, closed out by a trophy node. Order is what
gates progression: a lesson unlocks once the one before it is finished,
so the whole path is one flat sequence split into units. The trophy sits
*in* that sequence — it's the last step of its unit, so the next unit
stays locked until the review is finished, not just the lessons before
it. Add a lesson to `lessons` and drop its id into a unit's `lessonIds`
to extend it.

Each unit's banner lives on the map and sticks to the top while that
unit is on screen, until the next unit's banner pushes it out. That's
what `SliverMainAxisGroup` buys: pinned headers sitting directly in the
scroll view would pile up on each other instead. The trophy
plays that unit's **review** — a six-word mix built at runtime by
`_buildReview`, round-robined across every lesson in the unit so all of
them are represented. It's tracked as `review_<unit id>`, seeded by the
unit id so a half-finished review resumes on the right word, and it
counts toward the banner's `n/total` alongside the unit's lessons.

**How access works:** starting a lesson costs energy (`EnergyService`,
`costPerLesson`, default 5 of a 25 cap), which regenerates automatically
over time (default 1 per 10 minutes). An active subscription
(`EntitlementService.subscriptionActive`) skips the cost entirely —
`PathScreen._openLesson` is the one place that decides whether a tap opens
the lesson or shows the "out of energy" dialog. Energy is only spent the
*first* time a lesson is opened; resuming or replaying one already started
is always free. Per-lesson progress (last step, completion) lives in
`ProgressService`.

This is why new lessons ship for free users too: adding one to the catalog
needs no per-lesson wiring — everyone already passes through the same
unlock + energy/subscription check.

---

## 3. Going live with Google Play Billing + RevenueCat

**Google Play Console**
1. Create the app, upload a signed build to a test track.
2. **Subscriptions** → create one subscription (All Access) with a monthly
   base plan (add an annual base plan too if you want). There's nothing to
   sell per lesson — energy is a free, local mechanic, not a product.
3. Add **license testers** so you can subscribe without being charged.

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
> pin. The price shown in the app should come from the store, not the
> `kSubscriptionPriceLabel` placeholder (that's demo-only).

---

## 4. Shipping new lessons without an app update

Right now the catalog is bundled in the app, so a new lesson means a new
release. To publish without going through review each time, move
`lesson_catalog.dart` to a **JSON manifest + images served from Cloudflare R2**
(zero egress fees) and fetch it at startup. Every learner sees new lessons
instantly — access is decided by energy/subscription, not by which lessons
shipped inside the app.

## 5. Replacing the placeholder art

Pages use emoji as stand-in art. For real illustrations, add an `imageUrl`
(R2-hosted) or bundled `imageAsset` to `LessonWord` and render it in
`lesson_screen.dart` instead of the emoji `Text` — both the learn step and
the practice-step choice cards use it.
