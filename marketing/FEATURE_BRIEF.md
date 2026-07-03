# RepeatLab — Marketing Feature Brief

> **Purpose:** Single source of truth for AI-generated marketing content (landing page copy, SEO pages, ASO store listings, social posts).
> **Extracted from the actual app code** at version **2.0.3 (build 86)**, 2026-07-03. Every claim below is verified against the implementation unless marked otherwise.
> **Rule for content generation: only claim what is in the "VERIFIED" sections. Never claim anything from the "DO NOT CLAIM" section.**

---

## 1. Product identity

| Field | Value |
|---|---|
| App name | **RepeatLab** |
| One-liner (pubspec) | Audio loop studio |
| In-app tagline | "Your Music Loop Station" |
| Core promise (onboarding) | "Master any song by practicing difficult sections by repeating them or slowing them down." |
| Category | Music practice tool / audio looper / slow downer for musicians |
| Platforms | **iOS** and **Android** (a Windows build exists but is not distributed/marketed) |
| Bundle ID | `com.repeatlab.app` |
| Apple App Store ID | `6740175553` (current store slug: `audio-looper-speed-changer`) |
| Google Play | `https://play.google.com/store/apps/details?id=com.repeatlab.app` |
| Landing page | `https://repeatlab.netlify.app` (default Netlify subdomain, no custom domain yet) |
| Design | Dark-mode UI, Nunito Sans / Oswald typography |
| Account required | **No account, no registration, no login** |
| Ads | **None** |
| Internet required | **No — 100% offline**; all files and data stay on the device |

**Target audience:** musicians of all instruments (guitar, bass, piano, drums, vocals…), music students, music teachers, transcribers, people learning songs by ear, dancers/performers practicing to recordings, anyone following video tutorials.

---

## 2. Core features (VERIFIED — safe to market)

### A-B Looping (hero feature)
- Create loops by tapping to set **loop start** and **loop end** at the current position.
- **Millisecond-precision** loop editing: type exact start/end times down to milliseconds (mm:ss.sss).
- Fine-tune loop points by dragging an **interactive waveform** display.
- **Multiple named loops per song** (Pro; free = 1 loop per song), each with a custom name and one of **5 colors**.
- **Loop timeline**: visual overview of all loops in the song; tap a loop to jump straight to it.
- **Navigate between loops** with next/previous — also from the **lock screen, media notification, and Bluetooth controls**.
- Reorder loops via drag-and-drop (Pro).
- Toggle loop mode on/off; auto-play when selecting a loop (optional setting).
- **Repeat full song** seamlessly when no loop is active.

### Speed / tempo control (without changing pitch)
- Slow down or speed up playback from **0.5× to 2.0×** in 0.1 steps — **tempo changes, pitch stays the same**.
- Two modes: **multiplier (×)** or **BPM**.
- **BPM mode**: set the song's original BPM, then dial in an exact target BPM (up to 400 BPM).
- **Tap Tempo**: tap along to detect a song's BPM automatically (detects 40–200 BPM).
- High audio quality at changed speeds (dedicated audio engine; "enormous improvement of audio quality at speed changes" shipped in v1.5.0).

### Video looping (market as "NEW"; Beta label removed as of 2026-07-03)
- Import videos and loop/slow them exactly like audio — for practicing along to **tutorials, lessons, and live performances**.
- Same A-B loops, speed control, and BPM tools work on video.
- Adjustable video preview size (small/medium/large); full-height landscape video view.
- Supported video formats: **MP4, MOV, M4V, MKV, WEBM, AVI**.
- Note: video playback pauses when the app goes to background (background playback is audio-only).

### Waveform
- Visual waveform for every audio song with played/unplayed coloring and loop markers.
- Drag the waveform to scrub/seek precisely.
- **Waveform zoom 0.25×–5×** for pinpoint loop placement (Pro).

### Library & import
- **Unlimited songs, free.** Import via file picker, **multi-select batch import** supported.
- Audio formats: **MP3, WAV, OGG, FLAC, M4A, AAC** (iOS picker additionally allows wma, opus, aiff; non-native formats are automatically converted on import).
- Song metadata (title, artist) read automatically from file tags; editable in-app, plus per-song BPM.
- Drag-and-drop reordering of the song list.
- Note: no playlists/folders and no library search yet — do not claim these.

### Playback
- **Background playback** (audio) with **lock-screen and notification media controls** — keeps playing when the app is closed to background.
- Skip back/forward **10 seconds**; double-tap previous to jump to the previous loop.
- Play/pause/seek from Bluetooth devices and the media notification.

### Loop export (free)
- Export any loop as a standalone **WAV file (lossless)** at **44.1 kHz or 48 kHz**, saved wherever the user chooses.
- ⚠️ WAV only in the current build — **do not claim MP3 export** (the ASO draft `appstore_v2.md` mentions MP3/WAV; MP3 is not implemented).

### Backup & restore (Pro)
- Export the **entire library — songs, videos, loops, and settings — into a single `.rlbackup` file** and restore it on another device.
- Selectable content (audio / video / loops & settings); **Merge** or **Replace** import modes.
- Local file via OS share sheet — no cloud, no account needed.

### Learning & UX
- Interactive **guided tutorial** on the first song (coach marks for waveform, loops, speed); re-openable anytime.
- 3-slide onboarding; "What's New" changelog dialog; in-app feedback & bug reporting; feature-voting board.

### Localization
- **App fully localized in 16 languages:** English, German, Spanish, French, Italian, Portuguese, Dutch, Polish, Swedish, Russian, Turkish, Arabic, Hindi, Japanese, Korean, Chinese.
- In-app language switcher (independent of system language).

### Privacy (a real differentiator — market it)
- 100% offline; files never leave the device.
- No account, no registration.
- Analytics strictly **opt-in** (GDPR-conscious consent screen in onboarding); EU-hosted analytics.
- No ads.

---

## 3. Free vs Pro (exact gating from code)

Entitlement: RevenueCat **"Pro"**. Products: weekly `repeatlab_full_weekly`, yearly `repeatlab_full_yearly`, lifetime `repeatlab_full_extended`.
Pricing (from ASO doc, verify in store before publishing): **Weekly €0.99 (3-day free trial), Yearly €5.99 (3-day free trial), Lifetime €19.99 one-time**.

| Capability | Free | Pro |
|---|---|---|
| Songs (audio + video import) | ✅ Unlimited | ✅ Unlimited |
| Loops per song | **1** | **Unlimited** |
| Millisecond loop editing, waveform scrub | ✅ | ✅ |
| Speed control (0.5×–2×, multiplier & BPM, tap tempo) | ❌ (paywall) | ✅ |
| Waveform zoom (0.25×–5×) | ❌ (paywall) | ✅ |
| Reorder loops | ❌ | ✅ |
| Backup & restore library | ❌ (paywall) | ✅ |
| Export loop to WAV | ✅ | ✅ |
| Background playback + lock-screen controls | ✅ | ✅ |
| Full-song repeat, 10s skip, loop navigation | ✅ | ✅ |
| No ads | ✅ | ✅ |

In-app paywall headline (reuse tone): *"Master Your Favorite Songs like a Pro with Tempo Control, Zoom & Unlimited Loops!"*
Free-tier framing used in-app: "Unlimited Songs + One Loop per Song", "Export Loops", "No Ads".

---

## 4. DO NOT CLAIM (code-verified as absent or unshipped)

- **Pitch shifting / transpose (±12 semitones)** — exists as dead code, **no UI, not functional for audio**. (Internal `FEATURES.md` incorrectly lists it — ignore that doc on this point.)
- **MP3 loop export** — export is WAV-only.
- Playlists, folders, tags, or library **search** — none exist.
- **Cloud sync / accounts** — backup is a local file only (this is a privacy plus, phrase it that way).
- Spotify / Apple Music / streaming import — not possible (files only).
- YouTube looping — not available ("working on it" per FAQ; fine as roadmap teaser, not as a feature).
- Background playback **for video** — audio only.
- macOS / Linux / web versions.

---

## 5. Exact numbers cheat-sheet (for copy accuracy)

- Speed: **0.5×–2.0×**, 0.1 steps · BPM mode up to **400 BPM** · Tap tempo detects **40–200 BPM**
- Waveform zoom: **0.25×–5×**
- Loop precision: **milliseconds** · Loop colors: 5 · Skip: 10 s
- Export: WAV lossless, **44.1/48 kHz**
- Audio: MP3, WAV, OGG, FLAC, M4A, AAC · Video: MP4, MOV, M4V, MKV, WEBM, AVI
- Languages: **16** · Version: **2.0.3**

---

## 6. SEO / ASO raw material

### High-intent keyword themes (from ASO draft + verified features)
- slow down music (without changing pitch), music slow downer, slow downer app
- audio looper, A-B loop, loop sections of songs, song looper, repeat song sections
- video looper for musicians, loop video tutorials, slow down video
- music practice app, practice tool for musicians, play along, learn songs by ear, transcribe music
- BPM changer, tempo changer, tap tempo, metronome-adjacent terms
- instrument modifiers: guitar practice, bass, piano, drums, violin, vocals, riff, solo, tabs
- attribute modifiers: offline, no ads, no subscription (lifetime option), no account

### Current Apple ASO draft (from `repeatlab_app/docs/appstore_v2.md`)
- Title (30): `RepeatLab: Audio Video Looper`
- Subtitle (30): `Slow Down Music & Loop Songs`
- Keywords (100): `practice,guitar,tabs,bpm,tempo,pitch,trainer,transcribe,riff,solo,rehearsal,speed,player,ear` ⚠️ remove `pitch` (feature not shipped)
- Promo text: "NEW: Video looping is here! Import tutorials or live videos, loop any section, and slow it down — practice along at your own pace."

### Reusable in-app copy (already user-tested wording, localized in 16 languages)
- "Your Music Loop Station"
- "Master any song by practicing difficult sections by repeating them or slowing them down."
- "Create Precise Loops — simply tap to mark the start and end of a section you want to practice. Adjust and fine-tune with our intuitive waveform display."
- "Master Your Favorite Songs like a Pro with Tempo Control, Zoom & Unlimited Loops!"

---

## 7. Current landing page gaps (work list for the marketing AI)

Landing page (`landingpage/`, Astro on Netlify) still reflects audio-only v1. Missing content:

1. **Video looping** — the newest headline differentiator, absent from the page.
2. **"Slow down without changing pitch"** — highest-intent SEO phrase, currently just "slow down or speed up".
3. **BPM mode + tap tempo**, **waveform zoom**, **loop export (WAV)**, **backup & restore**, **background playback**, **16 languages** — all absent.
4. Free-vs-Pro comparison exists only buried in FAQ.

Technical SEO gaps:
- No Open Graph / Twitter cards, no canonical URLs, no JSON-LD (use `SoftwareApplication` / `MobileApplication` schema with ratings), no sitemap.xml, no robots.txt, referenced `favicon.svg` file is missing.
- One shared meta description across all pages; title tags carry no high-intent keywords.
- English only, `lang="en"` hard-coded — no localized pages / hreflang despite a 16-language app.
- Domain is default `repeatlab.netlify.app`; App Store slug (`audio-looper-speed-changer`) is off-brand.
- Only 2 screenshots and store badges in `public/images/`; no OG share image, no video-feature screenshots.

Existing verified page copy (keep tone): H1 "Master Your Music Practice with RepeatLab"; sub "Create perfect practice loops, adjust music speed and improve your musical skills with our intuitive looping tool."

---

## 8. Source files (for future re-verification)

- Feature logic: `repeatlab_app/lib/features/song/cubit/song/song_cubit.dart`, `lib/features/speed_control/`, `lib/features/song/widgets/wave_form_soloud.dart`
- Gating/paywall: `lib/features/paywall/`, `lib/data/models/repeatlab_feature.dart`
- Strings (16 languages): `repeatlab_app/lib/l10n/arb/app_*.arb`
- Backup: `lib/data/repositories/backup/`
- ASO drafts: `repeatlab_app/docs/appstore_v2.md` (v1 in `appstore_v1.md`), release notes `repeatlab_app/release_notes.json`
- Landing page: `landingpage/src/pages/index.astro`, `landingpage/src/layouts/Layout.astro`
