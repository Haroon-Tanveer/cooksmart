# Google Play release checklist

Status as of 29 September 2026. Everything marked done has been built and
verified on this machine; what remains needs your accounts and your time.

## Build and signing — done

- [x] **App bundle** — `flutter build appbundle --release` produces
      `build/app/outputs/bundle/release/app-release.aab` (68.6 MB), verified as a
      signed ZIP signed by `CN=CookSmart, OU=Apps, O=CookSmart` with SHA256/RSA
      2048. Play requires the `.aab`, not the `.apk`.
- [x] **Upload key** — `android/app/cooksmart-upload.jks` (PKCS12, alias
      `upload`), created with a 28-character random password written to
      `android/key.properties`. Both are in `.gitignore`.
- [x] **R8 minification** with `proguard-rules.pro` keeping Flutter and http.
- [x] **minSdk 24**, Play's floor for new listings.
- [x] **Version** 1.0.0+1.

### Do this today

Copy `android/app/cooksmart-upload.jks` and the passwords from
`android/key.properties` into a password manager, and back the keystore up
outside this project. **If you lose it you can never update the app**, because
every future upload must be signed with the same key.

## Store assets — done

- [x] `store/icon-512.png` — 512×512, Play's required size
- [x] `store/feature-graphic.png` — 1024×500, 24-bit, no alpha
- [x] `store/screenshots/` — 5 screenshots at 864×1920 (9:16), which Play accepts
- [x] `store/listing-copy.md` — name, short and full descriptions, release notes
      and per-screenshot captions
- [x] `store/declarations.md` — content rating, target audience, Data safety,
      ads, app access, with the reasoning for each answer

## Privacy — done except hosting

- [x] In-app policy at **Settings → Privacy policy**
- [x] `privacy.html` — self-contained, verified: 0 script tags, 0 external
      references, so hosting it creates no obligations
- [x] `PRIVACY.md` — the plain-text master copy
- [ ] **Host it and paste the URL** into the listing. Any static host works
      (GitHub Pages, Netlify, your own site). Upload `privacy.html` as
      `index.html`.

## Product behaviour — done

- [x] A fresh install has no endpoint and live generation **off**, so nobody
      lands on a connection error. The 560-recipe library works offline.
- [x] A config written by an older build no longer restores `liveEnabled: true`,
      so upgrading users do not get switched on without asking. Covered by
      `test/release_readiness_test.dart`.
- [x] One permission: `INTERNET`. Cleartext is blocked except on loopback and
      the emulator host alias, so any real deployment must be HTTPS.
- [x] No API key in the app, no analytics, no ads, no purchases.

## Still to do — these need you, not the build

1. **Create the Play developer account** ($25 one-time, with identity
   verification). A new personal account must also complete D-U-N-S.
2. **Closed test with at least 12 testers for 14 days** before a new personal
   account can publish to production. This is the longest lead time, so start it
   first. The app needs nothing special to test: install, browse, cook.
3. **Fill in the listing fields** in the Play Console: support email, contact
   email, and the hosted privacy policy URL.
4. **Paste the answers** from `store/declarations.md` into the content rating and
   Data safety forms.
5. **Upload the bundle** to the internal testing track, walk through the
   declaration, then promote to production after the 14-day test.

## The one open product decision

Live AI has nowhere to live in production. The app talks to a proxy the user
runs on their own machine, and `10.0.2.2` only means anything on an emulator, so
on a real phone the feature cannot work as shipped. Two ways forward:

- **Ship offline-first** (configured now). The 560-recipe library with photos,
  calories and steps is genuinely useful alone, and AI becomes a power-user
  extra. Nothing breaks for anyone who never sets an endpoint.
- **Deploy the proxy** as a hosted service and bake its URL in with
  `--dart-define=GROQ_BASE_URL=https://…`. You would then own an API key, its
  abuse costs, and the data-disclosure answers listed at the end of
  `store/declarations.md`.

Both are publishable. The second is a running cost, not just a build flag.

## Commands

```bash
flutter test                              # 52 tests
flutter build appbundle --release          # signed bundle for Play

# With live generation on, after deploying a proxy
flutter build appbundle --release \
  --dart-define=GROQ_BASE_URL=https://your-proxy.example

node tools/icon/generate_store_assets.js  # regenerate icon + feature graphic
```
