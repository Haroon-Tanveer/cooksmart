# Uploading CookSmart to Google Play — every step

Everything in this document uses the values from your project. Where a step needs
something only you can do, it says so.

**Your artefacts**

| What | Where |
|---|---|
| Signed bundle | `C:\Anti-Gravity\release\app-release.aab` (71.6 MB) |
| Package name | `com.cooksmart.cooksmart` |
| Version | 1.0.0, version code 1 |
| Store icon | `store\icon-512.png` |
| Feature graphic | `store\feature-graphic.png` |
| Screenshots (5) | `store\screenshots\01-home.png` … `05-settings.png` |
| Listing copy | `store\listing-copy.md` |
| Questionnaire answers | `store\declarations.md` |
| Privacy policy to host | `privacy.html` |

---

## 0. Before you start

**Back up the upload key.** This is the one step that, if skipped, permanently
ends your ability to update the app.

- Keystore: `android\app\cooksmart-upload.jks`
- Passwords: `android\key.properties`

Copy both somewhere outside this project — a password manager with an attachment,
or cloud storage you control. Every future upload must be signed with the same
key. Lose it and Play will reject your updates with no recovery path.

**Install the Play Console app on a test device.** Not optional: Google requires
at least 12 people to install your app from Play before it can go to production.

---

## 1. Create the developer account

1. Go to <https://play.google.com/console>
2. Sign in with a Google account you will keep using for this app.
3. Pay the one-off $25 registration fee.
4. Complete identity verification. Google asks for legal name, address, phone,
   and a government ID or D-U-N-S number for new personal accounts.
5. Choose your account type:
   - **Personal** — free, but has the 12-tester/14-day closed test requirement
     (section 6) and a 20-app per year cap.
   - **Organisation** — $25 one-off, needs a D-U-N-S number, and **skips the
     closed test requirement** entirely.

   If you can get a D-U-N-S number for a company or organisation, choose that.
   It is the single biggest time saver in this whole process.

---

## 2. Create the app

1. **Create app** → type **App**, name **CookSmart**.
2. Default language: English (United States).
3. App or game: **App**.
4. Free or paid: **Free**.
5. Accept the declarations and **Create app**.

The app is created with the package name inferred from your upload, so do not
upload anything yet.

---

## 3. Turn on the privacy policy (do this early)

Google gates a lot of the console behind a privacy policy URL, and a 404 here
stalls the whole process.

1. Enable GitHub Pages on <https://github.com/Haroon-Tanveer/cooksmart-privacy/settings/pages>:
   Source **Deploy from a branch**, branch **main**, folder **/(root)**, Save.
2. Wait a minute and check <https://haroon-tanveer.github.io/cooksmart-privacy/>
   loads. It should show the dark policy page with "Privacy Policy" at the top.
3. Keep that URL alive permanently. Play caches it, and a dead link gets the app
   removed.

---

## 4. Fill in the store listing

**Main store listing** (left nav → Grow → Store presence → Main store listing):

| Field | Value |
|---|---|
| App name | `CookSmart: 560 Recipes & Calorie Kitchen` (exactly 30 chars) |
| Short description | `Cook what you already have. 560 recipes, real photos, calories for every ingredient.` (78 chars) |
| Full description | paste the long description from `store\listing-copy.md` |
| App icon | upload `store\icon-512.png` (512×512 PNG, 32-bit, max 1 MB) |
| Feature graphic | upload `store\feature-graphic.png` (1024×500) |
| Phone screenshots | upload all five from `store\screenshots\` (864×1920, 9:16) |
| Privacy policy URL | `https://haroon-tanveer.github.io/cooksmart-privacy/` |

Also set:
- **App or game details** → category **Food & Drink**
- **Contact details** → support email, support website, and a marketing email if
  you have one. These must be addresses you actually read; Google emails you
  there about rejections and policy issues.

Per-screenshot captions are listed at the bottom of `store\listing-copy.md`.

---

## 5. Complete App content (the questionnaires)

Go through each section in the left nav under **Policy → App content**. The
answers are written out with reasoning in `store\declarations.md`; copy them
across.

| Section | What to answer |
|---|---|
| Privacy policy | URL from section 3 |
| Ads | No ads |
| App access | All functionality is available without special access |
| Content ratings | The questionnaire in `declarations.md`; expected result **Everyone** |
| Target audience | 13+ and 18+, not directed at children |
| News app | No |
| COVID-19 contact | No |
| Data safety | **No data collected, no data shared.** Accurate because live generation ships off and there is no analytics, ads or IAP |
| Government apps | No |
| Financial features | No |
| Health | No |
| Target SDK | Confirm it shows API 35 or higher. If it shows lower, stop and tell me |

**Data safety is the one to double-check.** If you ever ship a build with
`--dart-define=GROQ_BASE_URL=…`, the answers change: you would be collecting and
transmitting what the user types, and would need a deletion mechanism.
`declarations.md` lists the exact declarations for that case.

---

## 6. Closed testing (new personal accounts only)

Skip this whole section if you registered as an **Organisation**.

1. Left nav → **Testing → Closed testing** → **Create track**.
2. Name it something plain, e.g. `alpha`.
3. **Testers tab** → Create Google Group or email list → add **at least 12 real
   people**. Use a Google Group; it is the only way to add people in bulk.
4. Set your own account as the track tester and opt in.
5. Publish the release to this track.
6. Each tester installs from <https://play.google.com/apps/testing> using the
   link you share, then leaves a short review. A review is required, not optional.
7. **Wait 14 days.** The clock starts when 12 testers have opted in, and Google
   counts 12 continuous days.

The timeline is the real constraint here. If you need to ship sooner, use an
organisation account instead.

---

## 7. Upload the bundle

1. Left nav → **Release → Production** (or Internal testing for a first pass).
2. **Create new release**.
3. **App bundle** → upload `C:\Anti-Gravity\release\app-release.aab`.
4. **Version code** `1`, **Version name** `1.0.0`.
5. Release name: something like `1.0.0 (1)` — anything that helps you identify
   the build.
6. Release notes: paste the release notes block from `store\listing-copy.md`.
7. **Save**, then **Start rollout to Internal testing**.

Watch the warning panel. The usual ones:

- **"App has been uploaded with a debug certificate"** — you uploaded the APK
  rather than the AAB, or lost `key.properties`. Check you used the `.aab`.
- **"Target SDK below requirement"** — tell me and I'll raise it.
- **Missing Data safety or privacy policy** — go back to section 5; the console
  will not let you submit without them.

---

## 8. Test before production

1. Install from Play: <https://play.google.com/apps/testing>
2. Check first launch: the home screen loads, the library browses, a recipe
   opens, hold a photo for the full-screen viewer, swipe the gallery.
3. Turn airplane mode on and repeat. The app is offline-first by design, so
   everything must still work with no network.

---

## 9. Go to production

**Organisation account:** after section 7, Promote the release → Production.

**Personal account:** after the 14 days in section 6, Testing → Closed testing
shows the green bar. Promote: Production → Create new release → Promote the
existing release → **Start rollout to Production**.

Rollout options:
- **20%** then raise it, or
- **100%** straight away.

Once live, Play reviews can take hours to a few days. If a device category is
rejected, Play Console emails you with the specific reason.

---

## 10. After launch

- **Keep the keystore and passwords.** You need them for every update, forever.
- **Keep the privacy policy URL alive.** A dead link gets the app removed.
- **Version codes must always increase.** Next build is `2`, then `3`. Reusing a
  number is rejected.
- Keep an eye on the Play Console dashboard for review messages.

---

## Things that commonly cause rejections

- A privacy policy URL that 404s, or that contradicts the Data safety form.
- Missing content rating, which blocks every release.
- Uploading an APK with a debug signature instead of the AAB.
- Screenshots that are too small or the wrong aspect ratio. Ours are 864×1920,
  which Play accepts.
- Declaring "no data collected" while shipping a build that phones home. Ours
  ships offline-first, so this is accurate.
