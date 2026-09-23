
# Peekado — a Duolingo-style lesson app for kids 3+ (Android first)

A Flutter app of short listen-then-practice lessons for early learners. Each
lesson teaches a word (picture + sound), then quizzes it back with a
tap-the-match exercise — kids see it, hear it, then try it themselves.
You swipe left between steps, forward only — a practice step won't let
you past until the right picture is tapped, and nothing lets you swipe
back to a question you've already answered.

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

The app opens with a **landing page → a 2-slide "what is this app"
explainer → an email/password sign-in screen**, backed by **Firebase
Authentication**.

The project is **`peekadoo-6529c`**, on the free **Spark** plan, and
`lib/firebase_options.dart` now carries its real config. Check
**Build → Authentication → Sign-in method** has **Email/Password**
enabled (leave "Email link (passwordless)" off — nothing here uses it);
if it isn't on, sign-in reports "Email sign-in isn't switched on for
this app yet."

**Known mismatch — package name.** The Firebase project registers two
Android apps, `com.peekadoo` and `com.peekadoo.peekadoo`. CI builds
this app as **`app.peekado`** (the workflow's `--org app --project-name
peekado`), so neither registration matches what installs on a phone.
Email/password still works, because Firebase Auth validates the **API
key**, not the app id. What breaks later is anything that binds an app
to its package: **App Check / Play Integrity**, and per-app **Android
restrictions on the API key** — the moment that key is restricted to
`com.peekadoo` + a SHA-1, every request from this build is rejected.

Two ways to close it, and the choice is permanent once the app is
published, because a Play Store package name can never be changed:

- **Register `app.peekado`** as a third Android app in the project and
  put its app id in `firebase_options.dart`. Nothing about the app
  changes; the installed build keeps its identity.
- **Rebuild as `com.peekadoo`** by changing the workflow to `--org com
  --project-name peekadoo`. That matches what's registered, but bakes
  the "Peekadoo" spelling into the app's permanent identity, and the
  package change makes it a *different app* to Android — a fresh
  install, not an update.

The spare `com.peekadoo.peekadoo` registration can be deleted either
way.

`storageBucket` is `peekadoo-6529c.firebasestorage.app`, **not**
`.appspot.com` — projects created since late 2024 use the newer domain,
and guessing the old one silently breaks any future Storage use.

**Email enumeration protection is on** (the default for projects created
after Sept 2023). A wrong password and an unknown account both come back
as `invalid-credential`, on purpose, so nobody can probe which emails
have accounts. `AuthService._friendlyMessage` maps that to one message
that doesn't say which half was wrong — keep it that way if you edit it,
or the protection is undone from the client side.

Email/password auth is free and unlimited on Spark. Note for §7: Cloud
Functions needs the pay-as-you-go **Blaze** plan, so the AI-teacher
backend would mean leaving the free tier.

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
  data/achievements.dart                  badge list + the stats they're judged on
  services/entitlement_service.dart       subscription state + DemoEntitlementService
  services/revenuecat_entitlement_service.dart   production (Google Play Billing)
  services/energy_service.dart            energy pool: spend, regen over time
  services/progress_service.dart          steps, completion, streak, daily goal, missed words
  services/narration_service.dart         read-aloud / practice-prompt TTS
  services/auth_service.dart              Firebase email/password sign-in
  screens/landing_screen.dart             first screen: app name + tagline
  screens/onboarding_screen.dart          2-slide "what is this app" explainer
  screens/login_screen.dart               email/password sign in & sign up
  screens/path_screen.dart                learning path: units + winding lesson trail
  screens/lesson_screen.dart              lesson player: swipe through learn + practice steps
  screens/profile_screen.dart             progress, daily goal, tricky words, achievements
  screens/word_bank_screen.dart           every word learned, tap to hear again
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

**Progress:** `ProfileScreen` (drawer → Progress, or the ⭐ in the top
bar) is derived from the catalog and `ProgressService` — steps finished
out of the whole path, distinct words met, today's goal and streak,
what's up next, a bar per unit, tricky words, and the achievement grid.
Words are counted by the word itself, not per lesson, since a unit
review re-uses words its unit already taught.

**Streaks and the daily goal** live in `ProgressService` rather than a
service of their own, because they're written at the same moment
completion is — the end of a lesson. A day counts once a lesson is
finished, so the streak reads 0 on a fresh day and only ever goes up by
doing something; yesterday continues a streak, anything older starts a
new one. Replays count toward the goal (`dailyGoal`, 2) but not toward
lessons completed — the point of a goal is showing up. It's deliberately
gentle: a missed day resets quietly, with no nagging, since streak
pressure aimed at a three-year-old lands on whoever holds the phone.

**Missed words** are what make practice mean anything. A wrong tap calls
`recordMiss`, and two things spend that: a unit's trophy review fills
its six slots with the unit's missed words first (round-robin only fills
what's left), and the **Tricky words** drill on the profile screen plays
the worst offenders from anywhere in the catalog. Answering right in
that drill calls `forgiveMiss`, so the list empties as words are learned
— inside a normal lesson it doesn't, because there the right answer is
the only way past the question, and forgiving it would erase the miss
just recorded. The drill costs no energy: charging to practise the hard
words would price the most useful thing in the app.

**Achievements** (`data/achievements.dart`) are pure functions of an
`AchievementStats` record, computed on the fly. Nothing about them is
stored, so there's no earned-badge state to drift or migrate, and a
locked badge shows what it takes rather than a mystery.

**The word bank** is every word from finished lessons, tappable to hear
again through the same TTS the lessons use. It's the one screen a
preschooler can use unaided — no reading, nothing to get wrong, no way
to lose progress.

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

---

## 6. Revenue beyond the subscription (plan, nothing built yet)

All Access is the only thing sold today. This is the shortlist for what
comes next, and what each would cost in this codebase.

**The principle:** the user is three, so there is no monetising the free
*user* — there's monetising the parent, by removing a limit they feel or
answering a question they have. That's the test each idea below has to
pass.

**Ruled out, on purpose:**

- **Ads, including rewarded video.** Built once (0950b23) and reverted.
  An ad is a "watch this instead" button inside a learning app: the
  revenue comes from a third party and the distraction lands on the
  child. Google Play's Families policy would allow it with certified
  SDKs, non-personalised requests and no advertising ID — the objection
  isn't compliance, it's that it works against the thing the app is for.
- **Paying to refill energy.** Ad-free, but it monetises the same
  interruption ads did, and teaches a four-year-old that being stopped
  is solved by money.

**1. Lifetime unlock — one-time purchase.** Plenty of parents won't take
a subscription on a kids' app at any price, and today they don't convert
at all. Attach a second, non-consumable product to the *same*
`all_access` entitlement in RevenueCat (§3): `EntitlementService` already
hides which product granted access, so nothing outside `PaywallScreen`
changes. Usually priced at 5–8x the monthly. Smallest change here, and
the one that opens a segment that currently spends nothing.

**2. Per-unit packs.** The catalog is already unit-shaped
(`LessonCatalog.units`), so "first unit free, buy the rest or subscribe"
is an entitlement per unit, a price on locked path nodes, and a check in
`PathScreen._openLesson` next to the energy one. Gives free users a
purchase that isn't a commitment. The cost is aesthetic and real: the
learning path starts reading as a shop.

**3. Sell the parent something new.** A parent view — words learned,
which ones keep coming back wrong, time spent — plus the multiple child
profiles from the original roadmap. `ProgressService` already holds the
raw material; it would need per-profile keys and a screen. This is the
only option that *adds* something rather than gating it, and it's what
makes All Access worth renewing rather than merely unlocking.

**4. Preschools and daycares.** One licence covering a room of children,
sold to an adult with a budget — far higher ARPU, no consumer friction.
Needs real accounts, an admin view and a sales motion, so it's a later
move, not a next one.

**Suggested order:** 1, then 3. The first captures buyers who are
already interested and currently bounce; the second gives the
subscription a reason to renew past the point where the child has
finished the catalogue.

---

## 7. AI teacher (idea, costed, nothing built)

A tutor the child talks to: it asks for a word, listens, answers back in
speech, and drills the unit they're on. Sketched here so the shape and
the price are on record — none of it exists yet.

**Shape.** Flutter -> your server -> the Claude API. The API key can
never ship inside the APK (anyone can unzip one and read it), so a small
backend isn't a tax, it's where the feature lives: the safety prompt,
the per-child spend cap and the transcript log all have to be
server-side or they're client-editable. The app already has Firebase
Auth, so the client sends its ID token and the server knows whose budget
it's spending. The Flutter side is one screen.

**Voice costs nothing extra.** On-device speech-to-text in, `flutter_tts`
(already a dependency, see `narration_service.dart`) out — so every cent
is tokens. The catch isn't price, it's accuracy: speech recognition on
three-to-five-year-olds is far worse than on adults. A tutor built
around "can you find the red one?" with a tap fallback degrades
gracefully; one that needs a sentence transcribed won't.

**What it would cost.** Per turn: a ~1,500-token cached system prompt
(persona + safety rules + the child's current unit), ~600 tokens of
trimmed history, a ~25-token utterance, a ~70-token spoken reply. A
session is ~25 turns, about 8–10 minutes. At Anthropic first-party
prices (checked 2026-06-24 — re-check before pricing anything):

| Model | per session | 15 sessions/mo | 60 (2/day) | 120 (4/day) |
|---|---|---|---|---|
| Haiku 4.5 | $0.030 | $0.45 | $1.80 | $3.60 |
| Sonnet 5 | $0.060 | $0.90 | $3.60 | $7.20 |
| Opus 5 | $0.150 | $2.25 | $9.00 | $18.00 |

Google Play takes 15%, so a $20/month tier nets $17. Even on Opus 5 —
the best model — two sessions a day lands at $9 against $17. Break-even
is ~113 sessions a month, roughly four every day; on Haiku it's ~567.

**So the model price isn't the risk — unbounded use is.** One child who
leaves it talking all afternoon, or one login shared around a family,
is what eats the margin. That's a hard per-profile daily turn budget
enforced on the server, not a cheaper model.

**Levers, in the order they pay:** cache the system prompt (reads ~0.1x
input, write 1.25x, so it pays from the second turn); keep a rolling
history window instead of the whole conversation; cap `max_tokens` low,
since a four-year-old doesn't want paragraphs; then the daily budget.
Anything not live — a weekly "here's what they learned" summary for the
parent — goes through the Batch API at 50%.

**Safety is what decides whether this ships, not cost.** Ads were
dropped here for distracting from learning (§6); an open-ended chatbot
aimed at a three-year-old is a far bigger surface than an ad was. What
makes it defensible is scoping it as a *teacher* and not a *companion*:
it drills the current unit's words, the system prompt is server-owned
and never client-supplied, refusals (`stop_reason: "refusal"`) are
handled, and every transcript is visible to the parent. COPPA consent
and Google Play's generative-AI and Families requirements both need
reading before any code is written.

**If it gets built:** smallest honest version first — one endpoint, one
screen, hardcoded to Unit 1's words, metered per child — and measure
real token counts from `usage` before committing to a price.
