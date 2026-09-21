
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
   *Build APK* → *Run workflow*).
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
   peekado`).
4. Copy the config values shown (API key, App ID, Messaging sender ID,
   Project ID) into `lib/firebase_options.dart`, replacing the
   `YOUR_FIREBASE_*` placeholders in the `android` `FirebaseOptions`.

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

## 2. What's inside

```
lib/
  models/lesson.dart                      Lesson (title, cover, words) + LessonWord
  data/lesson_catalog.dart                the 14 lessons + the path's units
  data/demo_accounts.dart                 instant-login demo accounts (§1c)
  services/entitlement_service.dart       subscription state + DemoEntitlementService
  services/revenuecat_entitlement_service.dart   production (Google Play Billing)
  services/energy_service.dart            energy pool: spend, regen over time
  services/progress_service.dart          per-lesson step/completion + favorites
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
so the whole path is one flat sequence split into units. Add a lesson to
`lessons` and drop its id into a unit's `lessonIds` to extend it.

Each unit's banner lives on the map and sticks to the top while that
unit is on screen, until the next unit's banner pushes it out. That's
what `SliverMainAxisGroup` buys: pinned headers sitting directly in the
scroll view would pile up on each other instead. The trophy
plays that unit's **review** — a six-word mix built at runtime by
`_reviewLesson`, round-robined across every lesson in the unit so all of
them are represented. It's tracked as `review_<unit id>`, seeded by the
unit id so a half-finished review resumes on the right word.

**How access works:** starting a lesson costs energy (`EnergyService`,
`costPerLesson`, default 5 of a 25 cap), which regenerates automatically
over time (default 1 per 10 minutes). An active subscription
(`EntitlementService.subscriptionActive`) skips the cost entirely —
`PathScreen._openLesson` is the one place that decides whether a tap opens
the lesson or shows the "out of energy" dialog. Energy is only spent the
*first* time a lesson is opened; resuming or replaying one already started
is always free. Per-lesson progress (last step, completion) and favorites
live in `ProgressService`.

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
