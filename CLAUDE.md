# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Status: scaffold only — no functionality implemented

The Flutter project is initialized (package `com.melloss.homofidel`, app name **HomoFidel**, Android + web) and the clean-architecture tree is laid out, but **every directory under `lib/features/` is empty except for `.gitkeep` markers**. No family tables, no `scan()`, no UI.

`docs/Homofidel_Concept_Spec.pdf` is the source of truth for scope, algorithm, and deliverables — 6 pages, read it before starting. `NOTES.md` tracks honest status and deviations.

The first substantive task is the engine: family tables + `scan()` + siblings, with unit tests, in pure Dart before any UI (spec milestone 1).

Toolchain: Flutter 3.35.7 (stable), Dart 3.9.2, at `/snap/bin/flutter`.

## What this is

**Homofidäl** — an Amharic homophone checker for the Ge'ez script. Amharic writes several *different* base letters that are pronounced *identically*, so writers constantly pick the wrong-but-valid letter. Spell checkers miss this because the result is a real word in the dictionary: it is a real-word → real-word substitution, not a typo.

The app highlights those "choice points" in pasted text and lets the user tap a letter to swap it for its same-sound siblings. Fully offline, no backend, no ML.

Naming: product is **Homofidäl**, ASCII slug is `homofidel` (use for package/repo names), the working directory is `HomoFidel`.

## Commands

```bash
flutter pub get
flutter run -d chrome              # web build — the client is on Linux, no device/emulator needed
flutter test                       # engine unit tests
flutter build apk --release        # → build/app/outputs/flutter-apk/app-release.apk
flutter analyze                    # lints (flutter_lints)
flutter test test/widget_test.dart                        # single test file
flutter test --plain-name 'app shell boots'               # single test by name
```

The client works in Linux and asked for web/Linux run instructions — keep `flutter run -d chrome` working as the primary demo path.

## Architecture

Clean architecture, one feature slice (`lib/features/homophone_checker/`), with `flutter_bloc` in the presentation layer and `get_it` (`lib/injection_container.dart`) wiring it together.

| Layer | Holds |
|---|---|
| **domain** | Entities (`HomophoneFamily`, `FlaggedLetter`), the abstract repository contract, use cases (`ScanText`, `SwapLetter`) |
| **data** | Family-table data source, Mode B word-frequency source, DTOs, repository implementation |
| **presentation** | `CheckerBloc` + events/states, `home_page.dart`, `highlighted_text.dart`, `swap_sheet.dart` |

Dependencies point inward: `presentation → domain ← data`.

**The domain layer must stay pure Dart with zero Flutter imports.** This is the load-bearing constraint (spec §7) — it is what makes the detection logic unit-testable without a widget harness and reusable later (e.g. inside a keyboard/IME). Do not let `package:flutter` leak into `lib/features/homophone_checker/domain/`.

### Deliberate divergence from the spec

Spec §7/§8 specify Provider/`ChangeNotifier` and call BLoC "overkill at this size." This repo uses BLoC + clean architecture anyway, at the developer's explicit direction (2026-07-17). **Follow the code, not the spec, on this point** — but note the PDF is a client-facing deliverable that still says otherwise, and spec §14 names scope creep as a fixed-price-trial risk. Recorded in `NOTES.md`.

## The core insight: it's arithmetic, not a dictionary

Each Ge'ez letter is a single Unicode code point in a highly regular block. Within a family, every base letter's seven vowel orders are **seven consecutive code points**. So:

- `order = codePoint - base`
- a same-sound sibling is `otherBase + order`

No dictionary, no network, no ML needed for the core interaction. Given a character, check whether it sits in a family; if so, it's a choice point.

### The four families (verified against Unicode)

| Family | Sound | Bases |
|---|---|---|
| **H** | /h/ | `0x1200` ሀ, `0x1210` ሐ, `0x1280` ኀ |
| **S** | /s/ | `0x1230` ሰ, `0x1220` ሠ |
| **Ts'** | /ts'/ | `0x1338` ጸ, `0x1340` ፀ |
| **A** | /ʔ ~ a/ | `0x12A0` አ, `0x12D0` ዐ |

Worked example: ሳ `U+1233` is S-family, `order = 0x1233 - 0x1230 = 3`, so its sibling is `0x1220 + 3 = 0x1223` → ሣ. Likewise ኃ `U+1283` (H, order 3) → ሃ `U+1203` and ሓ `U+1213`.

### Bound the range at `base + 6`, not `base + 7`

This is the easiest bug to introduce and the spec explicitly calls for a test against it. The 8th slot (`base + 7`) is a **real, assigned, different letter** — the labiovelar variant — for nearly every base:

`0x1207` ሇ HOA · `0x1217` ሗ HHWA · `0x1237` ሷ SWA · `0x12A7` ኧ GLOTTAL WA …

So `base <= cp <= base + 6` is correct and `base + 7` would over-flag. (Curiosity worth knowing: `0x12D7` is *unassigned* — the ዐ row has a hole where the others have a labiovelar.)

## Scope discipline

This is a $20 Upwork fixed-price prototype trial. Scope tightness is the point; resist expanding it.

- **Mode A — choice-point highlighting: the guaranteed deliverable.** Flags every character that *could* be a homophone slip, offers swaps on tap. Deterministic, instant, offline, zero data risk. This alone satisfies the agreed interaction.
- **Mode B — likely-error correction: stretch goal only.** Checks word variants against a bundled offline frequency JSON to surface a *suggested* correction. Attempt only if time remains.

**Open decision, to confirm before building: Mode A only, or Mode A + attempt Mode B?**

Explicitly out of scope: full dictionary/grammar checker, one-click autocorrect, system-wide keyboard/IME, accounts, cloud sync, analytics, iOS/Play Store, polish pass.

Framing matters: the app is an **assist, not an authority**. Without a dictionary it cannot say which spelling is correct — it only offers the options. Say so plainly in NOTES.md.

## Known trap: `amharic_homophones` is not a drop-in

Spec Appendix B proposes reusing the author's own `amharic_homophones` package as the engine's data source. Verify before adopting — as of v0.0.2 on pub.dev it has two problems:

1. **It depends on the Flutter SDK** (`dependencies: {flutter: {sdk: flutter}}`), which directly violates the pure-Dart engine constraint above.
2. **It does normalization**, not family/sibling mapping — "convert Amharic text with homophones to a normalized form" is a different operation than what `scan()` needs.

Hand-writing the four family tables is ~10 lines of constants (they're all above, verified). Prefer that over the dependency unless the package changes.

## The one genuinely tricky Flutter bit

You cannot easily make individual characters inside a live `TextField` both colored and tappable while editing. The prototype's pattern:

- **Edit mode** = a normal `TextField`.
- Pressing **Check** renders a read-only `RichText` where each flagged grapheme is its own `TextSpan` with a `TapGestureRecognizer` (or a `WidgetSpan` for larger tap targets).
- Tapping a sibling mutates the underlying string and re-renders/re-scans.

Iterate with `runes` — every fidäl is a single code point, so no grapheme-cluster handling is required.

## Testing

The engine is deterministic, which makes it pleasant to test. Cover:

- Known letter → expected siblings, for all four families and several vowel orders.
- Non-Ge'ez text (Latin, digits, punctuation) → zero flags; empty input is safe.
- **Boundary**: characters just outside a family's 7-order range are not flagged (see `base + 6` above).
- Manual UX pass on the sample text: highlight → tap → swap → copy, on both the Android and web builds.

## Deliverables

Source via git (clean commit history), the working highlight → tap → swap flow on Android + web, a README with exact `flutter` run instructions, screenshots/short demo, and a `NOTES.md` stating honestly what works / what's incomplete / how it was tested / what's next. No pretending unfinished parts work.

## Structure

Spec §9 describes a flat `engine/state/ui` layout; the repo uses the clean-architecture tree below instead. Each empty directory carries a `.gitkeep` naming the files that belong there.

```
lib/
├── main.dart                         # boots DI, then HomofidelApp
├── injection_container.dart          # get_it — registration slots stubbed
├── core/{error,usecases}/
└── features/homophone_checker/
    ├── domain/{entities,repositories,usecases}/     # pure Dart
    ├── data/{datasources,models,repositories}/
    └── presentation/{bloc,pages,widgets}/
assets/word_freq.json                 # Mode B only (asset entry commented out
                                      # in pubspec until the file exists)
test/features/homophone_checker/…     # mirrors lib/
```
