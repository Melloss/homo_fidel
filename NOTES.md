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
- `flutter analyze` clean; `flutter test` green.

## What's incomplete

- [x] Family tables (the 4 Unicode base sets)
- [x] `scan()` — text → flagged choice points
- [x] `siblings()` — same-sound alternatives via order arithmetic
- [x] Engine unit tests
- [ ] The one screen: input, Check, Copy
- [ ] Highlighted `RichText` result with tappable letters
- [ ] Swap bottom sheet + replace-and-rescan
- [ ] Sample-text (አማርኛ) button
- [ ] Mode B (word-frequency likely-error layer) — stretch goal, may not be attempted

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

- **Mode A only, or Mode A + attempt Mode B?** Spec §5 recommends shipping Mode A (choice-point highlighting) as the guaranteed deliverable and attempting Mode B only if time remains. Not yet confirmed.

## What I'd try next

Per spec §13, in order: engine + unit tests (prove the idea in pure Dart before any UI) → the one screen → tap-to-swap → polish, builds, screenshots → Mode B if time allows.
