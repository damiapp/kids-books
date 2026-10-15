# Play Console — what to enter

Drafts for the forms Google Play asks for before a children's app can be
listed (RELEASE_PLAN.md step 9). Everything here is written against what
the app actually does in this repo; if the code changes — especially
sign-in, crash reporting, or payments — re-check the Data safety answers
before submitting.

---

## The file to upload

Actions tab → **Release bundle** → **Run workflow**. When it's green,
download the `peekadoo-aab` artifact and upload the `.aab` inside it to
a testing track first (Internal testing), then Production.

The bundle is signed with the Peekadoo key (the same one in Proton
Pass). On first upload, accept **Play App Signing**: Google then holds
the key that signs what users download, and yours becomes the "upload
key". Keep it safe all the same — losing it means asking Google for a
reset.

Each upload needs a higher build number than the last (the `+N` in
`pubspec.yaml`), which every push already bumps.

---

## Main store listing

**App name:** Peekadoo

**Short description** (80 characters max):

> Learn first words by listening and tapping. Made for little ones 3 and up.

**Full description:**

> Peekadoo helps young children learn their first words — by listening, not
> reading.
>
> Every word is shown with a picture and read aloud. Then your child hears
> a word and taps the picture that matches. Get it right and there's a
> burst of sparkles; get it wrong and they simply try again. No reading
> needed at any point — every instruction is spoken.
>
> WHAT'S INSIDE
> • 58 short lessons and 341 words, from colours and animals to feelings,
>   opposites and good manners
> • A learning path that unlocks one step at a time
> • Unit reviews that bring back the words your child found hardest
> • A word bank of everything they've learned, to tap and hear again
> • Daily goals and gentle streaks — no nagging, no pressure
>
> MADE FOR CHILDREN, AND THE GROWN-UPS AROUND THEM
> • No ads. No in-app chat. No tracking.
> • Your child never types or shares anything.
> • Account settings sit behind a grown-up check.
> • Built-in rest breaks keep sessions short.

**Category:** Education
**Tags:** Language learning, Educational games, Preschool

---

## App access

Sign-in is required, so reviewers need a working account. The demo
accounts are **compiled out of the store build** (the Release bundle
workflow sets `DEMO_ACCOUNTS=false`), so they won't work for a reviewer.

Before submitting, create a real account for review: install the store
build (or the CI APK), tap **Sign up**, and use an address you control,
e.g. `peekadoo.review@<your domain>`. Don't delete it afterwards —
Google re-reviews every update with the same credentials.

Choose **"All or some functionality is restricted"** and give:

| | |
|---|---|
| Username | the review account's email |
| Password | its password |
| Notes | Sign in from the login screen with these details. No other setup is needed. The grown-up area (menu → Progress → Delete account) asks a simple number question first; the answer is shown in words on screen. |

---

## Ads

**Does your app contain ads?** No.

---

## Target audience and content

- **Target age groups:** 5 and under. (Optionally 6–8 as well — the
  content suits early readers too. Both are child age groups, so the
  Families policy applies either way.)
- **Could the app unintentionally appeal to children?** Not applicable —
  it's designed for them.
- Because the audience is children only, Google Play requires: no
  advertising ID, no ads SDKs that aren't Families-certified, a privacy
  policy, and that the app meets the Families policy. The app currently
  has no ads or analytics SDKs.

---

## Content rating (IARC questionnaire)

Answer **No** to every question about violence, fear, sexuality,
language, controlled substances, gambling and user interaction. There is
no user-generated content, no chat, no sharing, and no location
sharing. Expected result: **Everyone / PEGI 3**.

---

## Data safety

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (HTTPS only) |
| Do you provide a way for users to request that their data is deleted? | **Yes** — the account-deletion URL (step 4) |

**Data types collected:**

| Type | Collected | Shared | Optional? | Purpose |
|---|---|---|---|---|
| Personal info → **Email address** | Yes | No | Required | Account management |

Everything else is **not collected**: no location, no contacts, no photos,
no audio, no app activity, no device or advertising IDs, no crash logs
(yet — if crash reporting is added in step 7, add *App info and
performance → Crash logs*, collected, not shared, for analytics).

Learning progress is stored **only on the device** and never transmitted,
which Google Play does not count as "collected".

**Before submitting, check one thing we couldn't verify from here:**
Google publishes data-disclosure guidance for each Firebase product, for
exactly this form. Read the Firebase Authentication entry and make sure
nothing it lists is missing above.

---

## Privacy policy

URL: the published `docs/privacy-policy.md` (step 5).
