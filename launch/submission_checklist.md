# Fade — Play Store submission pack

Everything needed to submit, in order. Store-listing text lives in
`play_store_listing.md`.

## The 4 hard blockers — ALL CLEARED ✅

| # | Blocker | Status |
|---|---------|--------|
| 1 | Live privacy-policy URL | ✅ live (URLs below) |
| 2 | Data Safety form | ✅ answers below |
| 3 | Content rating | ✅ answers below |
| 4 | Google consent screen published | ✅ "In production" |

## LIVE LEGAL URLs (verified 200 — note: NO `.html`)

- Privacy: `https://lively-wood-9165.gulamovmuhammad44.workers.dev/privacy`
- Terms: `https://lively-wood-9165.gulamovmuhammad44.workers.dev/terms`
- Delete account: `https://lively-wood-9165.gulamovmuhammad44.workers.dev/delete-account`

Paste the privacy one into Play's **Privacy policy** field and the delete one into
**Data deletion**. Later, once fade.uz is Active in Cloudflare, attach it as a
custom domain → the URLs become `fade.uz/privacy` etc., and you can update the
Play fields (allowed anytime).

## The Play-ready file
`C:\FadeBuild\build\app\outputs\bundle\release\app-release.aab` (58.8 MB, signed)

---

## Data Safety form (Play Console → App content → Data safety)

**Overview:** collects/shares data = **Yes** · encrypted in transit = **Yes** ·
users can request deletion = **Yes**.

| Data type | Collected | Shared | Optional | Purposes |
|-----------|-----------|--------|----------|----------|
| Name | Yes | Yes (barber) | Required | App functionality, Account management |
| Phone number | Yes | Yes (barber, SMS provider) | Required | App functionality, Account management |
| Email address | Yes | No | Optional | Account management |
| Approximate location | Yes | No | Optional | App functionality |
| Photos | Yes | No | Optional | App functionality |
| In-app messages | Yes | No | Optional | App functionality |
| User content (reviews) | Yes | Yes (public) | Optional | App functionality |
| App activity / diagnostics | Yes | No | — | Analytics, App functionality |

Notes:
- **No precise location** — the app now uses approximate only (manifest matches).
- SMS/AI/auth vendors are **processors** (service providers), so they don't
  count as "sharing" — but Name/Phone go to the **barber** (an independent
  business), which does. Declaring it keeps you consistent with the privacy
  policy; a mismatch is a common rejection cause.
- No advertising ID, no data sold, no data for third-party ads.

## Content rating (Play Console → App content → Content rating → IARC)

- Category: **Utility / Lifestyle** (not a game)
- Violence / sexual / profanity / drugs / gambling → **No**
- Users can communicate with each other → **Yes** (client↔barber chat)
- User-generated content shared publicly → **Yes** (reviews, photos)
- Buying/selling services → **Yes**; in-app digital purchases → **No** (no card
  payments yet)
- **Expected rating: Teen** — normal for a marketplace with messaging + reviews.

## Other App-content declarations
- Ads: **No ads**
- Target audience: 16+ (no children's category)
- Government / financial / health app: **No**
- Data deletion URL: `https://fade.uz/delete-account.html` (after hosting)

---

## Submission order (fastest path)
1. **You:** publish Google consent screen · host `legal/` on fade.uz
2. Play Console → **Create app** (name Fade, free, app not game)
3. **Store listing** — paste `play_store_listing.md`, add your icon + feature
   graphic + screenshots
4. **App content** — Data safety, Content rating, Privacy policy URL, Ads,
   Target audience, Data deletion (all answers above)
5. **Production → Create release** — upload `app-release.aab`, add release notes
6. **Send for review**

## Release notes (first version)
```
First release of Fade — book barbers near you, earn points, and skip the queue.
```

## Assets you provide (I can't generate these)
- App icon 512×512 · Feature graphic 1024×500 · 2–8 phone screenshots
