# Release plan

**Goal:** a v1 that passes Google Play review as a children's app, and
that a three-year-old can use without an adult reading the screen to
them.

Worked top to bottom. Each step ships as its own build, so a problem
shows up attached to the change that caused it.

| | Step | Who |
|---|---|---|
| ✅ | **1. Speak everything a child needs to understand.** The app assumed its user can read: learn cards were silent until you found the speaker button, and every instruction ("Which one did you hear?", "Swipe left…", "Great job!") was text only. | me |
| ✅ | **2. No paywall in front of a child.** "Out of energy" mid-session is a meltdown for a three-year-old and reads as predatory to parents. The child gets a kind "come back later"; anything about money sits behind a parent check. | me |
| ✅ | **3. A better voice.** The phone's speech engine varies a lot. Pick the best English voice actually installed, and never fail silently when there isn't one. | me |
| ⏳ | **4. Account deletion.** Google Play requires it for any app that creates accounts — in the app, and on a web page. *In-app: done (menu → For grown-ups → Delete account, behind the grown-up check). Web page: written at `docs/delete-account.md` — needs a contact email filled in, and GitHub Pages switched on so it has a public URL.* | me ✅, then you |
| ⏳ | **5. Privacy policy and store declarations.** Mandatory for a children's app that collects an email address. I draft; you publish and have it read by someone who can sign off on it. *Drafted at `docs/privacy-policy.md`, written against what the code actually does. Needs: your name, a contact email and a date filled in; a read by someone who can sign off on it; and — if v1 ships without payments (step 8) — the Subscriptions section and the RevenueCat row removed. Once it has a URL, I add an in-app link behind the grown-up check.* | me ✅, then you |
| ⬜ | **6. Progress follows the account.** Today everything is on the phone, so the account is friction with no benefit. Sync streak and progress to Firestore. | me, after you switch Firestore on |
| ⬜ | **7. Crash reporting.** Otherwise a crash on someone else's phone is invisible to us. | me |
| ⏳ | **8. Real payments.** "Subscribe" is a demo that charges nothing. Until RevenueCat and Play Billing are connected, the subscription is hidden from release builds so v1 never promises something it doesn't do. *Hidden: done — `kPaymentsLive` in `lib/config.dart`, off by default. Connecting real billing needs your Play Console and RevenueCat accounts.* | me ✅, then you |
| ⏳ | **9. Play Console listing.** Data safety form, target audience, content rating, store text and screenshots. *Drafted at `release/play-console.md`. The store build is the **Release bundle** workflow (Actions → Run workflow): a signed `.aab` with demo accounts compiled out. Needs from you: a Play developer account, a real review account, phone screenshots, and the form answers entered.* | me ✅, then you |
| ⬜ | **10. Watch two or three children use it.** Every speed, size and picture choice so far is a guess. Nothing else on this list replaces this. | you |

**One thing unblocks steps 4 and 5 together:** in the repo's Settings →
Pages, publish from the `main` branch, `/docs` folder. Both pages then
get public URLs — `…/delete-account` and `…/privacy-policy` — which are
exactly what the Play Console asks for.

Steps 1–3 and 7 need nothing from you. Steps 4, 5 and 6 need a few
minutes in the Firebase console or on a web host. Step 8 is the one that
needs real accounts — if it isn't ready, v1 ships free and loses nothing.
