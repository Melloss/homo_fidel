# NOTES

Honest status of the prototype. Updated as work lands — no pretending unfinished parts work.

## What works

- Project scaffold: Flutter app, package `com.melloss.homofidel`, app name **HomoFidel**.
- Targets Android + web. `flutter run -d chrome` boots a shell (no device needed).
- Clean-architecture layout in place, dependencies wired, `get_it` container stubbed.
- Brand palette sampled from the spec PDF, with every pairing contrast-checked;
  light + dark themes applied and verified rendering in a real browser.
- App icon (gold ፊ on navy) generated for Android — legacy, adaptive, and
  Android 13 themed/monochrome — plus web icons and favicon.
- Noto Sans Ethiopic bundled, so fidäl renders on web without depending on a
  host font. Verified present in the built asset bundle, both weights.
- **The engine (spec milestone 1), pure Dart, fully unit-tested:**
  - The four family tables (H, S, Ts', A) as constants, verified against the
    spec's Unicode bases by a dedicated test.
  - `scan()` — walks the runes, flags every family member with its code-unit
    index, family, vowel order, and same-sound siblings.
  - Sibling generation by order arithmetic on `HomophoneFamily`
    (`order = codePoint − base`, sibling = `otherBase + order`).
  - `ScanText` / `SwapLetter` use cases; `SwapLetter` validates the flag is
    fresh and the sibling legal before touching the string.
  - A purity test that fails if `package:flutter` ever leaks into the domain
    layer.
- **The one screen (spec milestones 2–3), the central interaction working
  end-to-end:** paste/type → አረጋግጥ (Check) → highlighted read-only result →
  tap a letter → bottom sheet of same-sound siblings → tap to swap →
  re-scan → አርም (Edit) round-trips the corrected text back into the field →
  ቅዳ (Copy) puts it on the clipboard.
  - `CheckerBloc` (edit mode ⇄ checked mode) wired through `get_it`.
  - `HighlightedText` renders each flagged grapheme as its own tappable
    `TextSpan` (recognizers owned and disposed properly).
  - ናሙና sample button pre-fills a sentence covering all four families in
    both directions (10 choice points).
  - Choice points use the quiet wheat highlight (`AppColors.choicePoint`),
    per the spec §14 noise mitigation; the strong gold stays reserved for
    Mode B likely-errors.
- **Mode B (spec milestone 5) — likely-error weighting over a real corpus:**
  - `assets/word_freq.json` (1.7 MB, ~0.4 MB gzipped): 79,456 word
    frequencies distilled from ~41k articles / 10.3M tokens of "An Amharic
    News Text classification Dataset" (Azime & Mohammed 2021, **CC BY 4.0** —
    redistribution with attribution is allowed; attribution ships in the
    file's meta block). Regenerable via `tool/build_word_freq.py`.
  - `SuggestCorrections` generates same-sound variants per word and fires
    only on lopsided evidence: the variant needs ≥10 corpus hits **and** 20×
    the typed spelling's count. Anything weaker stays a quiet choice point.
  - Likely-slip letters render in full-strength gold (`AppColors.likelyError`)
    over the quiet wheat of ordinary choice points — the two-weight scheme
    the palette reserved from day one. The swap sheet stars the corpus's
    pick and shows the raw counts (`በጸሎት ×0 · በፀሎት ×102`), so the app
    presents evidence rather than issuing verdicts.
  - Degrades cleanly: if the asset is missing or corrupt the repository
    reports unavailable, suggestions are empty, and Mode A is unaffected.
- Flow screenshots of the release web build in `docs/screenshots/`, including
  the Mode B states.
- `flutter analyze` clean; `flutter test` green.

## What's incomplete

- [x] Family tables (the 4 Unicode base sets)
- [x] `scan()` — text → flagged choice points
- [x] `siblings()` — same-sound alternatives via order arithmetic
- [x] Engine unit tests
- [x] The one screen: input, Check, Copy
- [x] Highlighted `RichText` result with tappable letters
- [x] Swap bottom sheet + replace-and-rescan
- [x] Sample-text (ናሙና) button
- [x] Mode B (word-frequency likely-error layer)
- [ ] Android build verified on a real device (web is the demo path; the APK
  builds but has not been exercised by hand)
- [ ] The clipboard Copy button has no automated test (needs a platform-channel
  mock); verified only manually in the browser

**Mode B limitations, stated plainly:**

- The frequency list is **descriptive, not prescriptive** — it counts how
  Ethiopian newsrooms actually spell. In several famous cases modern news
  usage departs from traditional etymological orthography (the corpus has
  ፀሎት 269× vs ጸሎት 2×, and አይን 458× vs ዐይን 7×), so the app will sometimes
  recommend the *newsroom* spelling over the *classical* one. That is a
  property of the corpus, is why the UI shows the raw counts instead of the
  word "wrong", and is the first thing to revisit with the client if a more
  traditional register is wanted.
- The ≥10-hits and 20× dominance thresholds are engineering judgment, not
  linguistics; they were chosen to make false positives expensive and are
  easy to tune in one place (`SuggestCorrections`).
- Frequencies are word-level with no morphological awareness; unseen
  inflections of common stems simply produce no suggestion (safe, but blind).

## How it was tested

Engine, per spec §10 — all deterministic unit tests, no widget harness:

- Known letter → expected siblings for all four families across several vowel
  orders, including both worked examples from spec §5 (ሳ → ሣ; ኃ → ሃ, ሓ).
- Non-Ge'ez input (Latin, digits, punctuation), non-family fidäl, Ethiopic
  punctuation/digits, and empty input → zero flags.
- Boundary: order 6 (`base + 6`) letters ARE flagged; the labiovelar variants
  at `base + 7` (ሇ ሗ ሧ ሷ ኧ ጿ ፇ) and the letters just below each base are NOT.
- Indices are UTF-16 code-unit offsets — verified against mixed Latin/Ge'ez
  text and a surrogate-pair (emoji) prefix — so swaps land on the exact
  character even in messy input.
- Swap: replaces only the targeted occurrence, is reversible, and rejects
  stale flags and non-sibling replacements.

Mode B — deterministic unit tests with a fake corpus, plus an integrity test
on the real asset:

- Dominance rule: suggests for a rare typed variant, stays silent when typed
  dominates or evidence is merely 3:1, handles typed-absent words, requires
  attestation, and picks the best of several attested variants.
- Multi-letter words change only the wrong letter (`ፀሐይ → ፀሀይ` → index 1).
- Word positions are code-unit offsets; each word judged independently.
- Guards: unavailable list → no suggestions; no-family words never looked up;
  empty/Latin input safe; a 3⁸-variant word is skipped, not enumerated.
- The bundled `word_freq.json` is loaded for real in a test: >50k entries,
  ሰላም and ኢትዮጵያ present with plausible counts, no-family words absent.
- A corrupt/missing asset load degrades to `isAvailable == false`.

UI — bloc tests plus full-flow widget tests over the real engine (no mocks
except the swappable fake corpus):

- `CheckerBloc`: check → flags, swap → re-scan (ሰላም → ሠላም stays a choice
  point), swap ignored in edit mode, Edit returns to edit mode.
- Widget flow: boot → sample fill → Check renders the count and highlights;
  zero-flag text says "No choice points found"; tapping a flagged span's
  recognizer opens the sheet with the right sibling; choosing it swaps the
  text; Edit preserves the swapped text in the field.
- Widget flow, Mode B: a dominated spelling is counted in the summary line
  ("1 likely slip in gold"), painted with `AppColors.likelyError`, starred in
  the sheet with the evidence line; ordinary choice points get neither.
- Release web build (`flutter build web --release`) driven in headless Chrome
  over the DevTools protocol: sample → Check showed all 10 highlights with
  **4 likely slips in gold** (ፀሐይ, በጸሎት, የሠራተኛው, ዐይን — all four families,
  from real corpus evidence); tapping ጸ opened the sheet showing
  `በጸሎት ×0 · በፀሎት ×102` with ፀ starred; applying it re-scanned to
  "3 likely slips". Screenshots of each state are in `docs/screenshots/`.

Scaffold-level checks from the previous milestone:

- `flutter analyze` → no issues.
- `flutter test` → passes (asserts the shell renders ፊደል; no logic under test yet).
- `flutter build web --release` → builds; both font weights confirmed in the
  output `FontManifest.json` and asset bundle.
- Served the release build and screenshotted it in headless Chrome under both
  `prefers-color-scheme` values: light renders white/ink, dark renders ink/light,
  and ፊደል rasterises in the bundled font rather than tofu.
- Adaptive icon checked by compositing the *generated* drawable over the plate
  with the launcher's inset applied, then masking to circle and squircle. The
  first attempt put the glyph at 27% of the canvas against a 66% safe zone —
  a speck. Corrected to 54%; see the note in `tool/generate_icon.py`.

No functional testing has happened because there is no functionality. Once the engine exists, testing follows spec §10: known letter → expected siblings across all four families and several vowel orders; non-Ge'ez input (Latin, digits, punctuation) → zero flags; empty input safe; and a boundary check that characters just outside a family's 7-order range are **not** flagged.

## Deviations from the spec

1. **State management: BLoC, not Provider.** Spec §7/§8 specify a single `ChangeNotifier`/Provider and explicitly call BLoC "overkill at this size." This repo uses `flutter_bloc` with a full clean-architecture layering at the client developer's direction. The tradeoff is real: more ceremony and more files than one screen strictly needs, against a structure that's familiar and extends cleanly. Spec §14 flags scope creep as a risk on a fixed-price trial; worth confirming the PDF gets updated so the doc and the code agree.

2. **`amharic_homophones` not used as the data source.** Spec Appendix B proposes reusing it. As of v0.0.2 on pub.dev it (a) depends on the Flutter SDK, which would violate the pure-Dart domain-layer constraint, and (b) does homophone *normalization* rather than family/sibling *mapping*, which is a different operation than `scan()` needs. The four family tables are ~10 lines of constants, so they're better hand-written here. Worth revisiting if the package changes.

## Open decisions

- **Mode A only, or Mode A + attempt Mode B?** Resolved: **both shipped.**
  Mode A remains the deterministic core; Mode B layers corpus evidence on
  top at the client's request (2026-07-17) and degrades to Mode A if its
  asset ever fails to load.
- **Corpus register.** The news corpus favours contemporary newsroom spelling
  over classical orthography (see Mode B limitations above). If the client
  wants the traditional register, the fix is a different/blended corpus in
  `tool/build_word_freq.py`, not code changes.

## What I'd try next

- Blend a second corpus (e.g. literary/religious text) or let the user pick a
  register, to address the newsroom-vs-classical bias.
- Tune the dominance thresholds against a labelled list of known slips.
- A manual UX pass of the APK on a physical Android device.
- A short screen recording of highlight → tap → swap → copy for the delivery.
