# Play Console declarations for CookSmart

Answers to the questionnaires, worked out from the actual build. Read each one
against the app before submitting — if you enable live generation by shipping
with a `GROQ_BASE_URL`, the Data safety answers change and are marked below.

## App category

**Food & Drink**

## Tags

Optional. `Food & Drink` is the only one Google offers for this app type, so no
extra tags.

## Content rating questionnaire

| Question | Answer | Why |
|---|---|---|
| Violence | No | No violence, threats, or references to it |
| Sexuality | No | No sexual content or references |
| Language | No | No profanity or crude humour in the app's own text |
| Controlled substances | No | Food and cooking only. Alcohol and tobacco are not sold, promoted, or depicted |
| Gambling | No | Not present |
| User-generated content | No | Nobody can post, comment, or share content |
| Location sharing | No | No location features |
| Personal info sharing | No | No account, no sharing, no third-party SDK that collects |
| Dating / relationships | No | Not applicable |
| Unrestricted internet access | No | The app has no web view, no browser, and no link that opens arbitrary pages |
| User can be charged | No | No purchases, no subscriptions, no billing of any kind |

**Resulting rating:** Everyone / suitable for all ages. The app carries no ads
and no IAP, so Play's "Designed for Families" programme does not apply and there
is no need to opt out of the ads declaration.

## Target audience

- **Age groups selected:** 13 and over, and 18 and over.
- **Not directed at children.** The content is food and cooking. Declaring it as
  a general-audience app means none of the Families policy requirements apply.

## Data safety

As shipped, with live generation **off** (the default):

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | Not applicable — no data is transmitted |
| Do you provide a way for users to request that their data be deleted? | Not applicable — no data is collected. App data is erased by clearing storage or uninstalling |

Why "no data collected" is accurate: the app has no account system, no
analytics or crash-reporting SDK, no advertising SDK, and no in-app purchases.
Ingredient lists, favourites and settings are written to the device's private
app storage by `shared_preferences` and never transmitted.

### If you ship a build with a live proxy

Enabling live generation changes one answer. Ingredients and any dish name the
user types are sent to your server and on to the AI provider, so declare it:

- **Data type: App info / Other user-generated content** — the text the user
  types, purpose *App functionality*, **not** shared with third parties for their
  own purposes, but **collected by you** and by your AI processor.
- **Data type: Photos and videos** — only if you keep the food photographs the
  proxy returns; the app itself only caches them locally, so this is optional.
- Provide a **data deletion** mechanism, because once declared, Play requires a
  way for users to request deletion.

This is the concrete cost of deploying a proxy, and the reason the default build
ships offline.

## Ads

- Contains ads: **No**
- Contains in-app purchases: **No**

## Government / financial / health

Not applicable. CookSmart is a recipe library; it does not give medical,
financial, or legal advice, and the calorie figures are estimates for planning,
not dietary prescriptions. The settings copy avoids any health claim.

## App access

Every feature is available without registration, so select
**"All functionality is available without special access"**. No credentials are
needed to review the app.

## News app / COVID-19 / Data safety declarations

Not applicable.

## Store listing checklist

- [x] App icon, 512x512 — `store/icon-512.png`
- [x] Feature graphic, 1024x500 — `store/feature-graphic.png`
- [x] Phone screenshots, 5 at 864x1920 (9:16) — `store/screenshots/`
- [x] App name and descriptions — `store/listing-copy.md`
- [ ] Support email and website — **you supply these**
- [ ] Privacy policy URL — **you host `privacy.html` and paste the address**
- [ ] Contact email for the listing
