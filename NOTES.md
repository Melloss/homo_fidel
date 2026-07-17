# NOTES

Honest status of the prototype. Updated as work lands — no pretending unfinished parts work.

## What works

- Project scaffold: Flutter app, package `com.melloss.homofidel`, app name **HomoFidel**.
- Targets Android + web. `flutter run -d chrome` boots an empty shell (no device needed).
- Clean-architecture layout in place, dependencies wired, `get_it` container stubbed.
- `flutter analyze` clean; `flutter test` green (one shell smoke test).

## What's incomplete

**Everything functional.** Nothing in the concept spec is implemented yet:

- [ ] Family tables (the 4 Unicode base sets)
- [ ] `scan()` — text → flagged choice points
- [ ] `siblings()` — same-sound alternatives via order arithmetic
- [ ] Engine unit tests
- [ ] The one screen: input, Check, Copy
- [ ] Highlighted `RichText` result with tappable letters
- [ ] Swap bottom sheet + replace-and-rescan
- [ ] Sample-text (አማርኛ) button
- [ ] Mode B (word-frequency likely-error layer) — stretch goal, may not be attempted

## How it was tested

At this stage: only that the scaffold builds and boots.

- `flutter analyze` → no issues.
- `flutter test` → passes (asserts the app shell renders; no logic under test yet).
- Web build launched via `flutter run -d chrome`.

No functional testing has happened because there is no functionality. Once the engine exists, testing follows spec §10: known letter → expected siblings across all four families and several vowel orders; non-Ge'ez input (Latin, digits, punctuation) → zero flags; empty input safe; and a boundary check that characters just outside a family's 7-order range are **not** flagged.

## Deviations from the spec

1. **State management: BLoC, not Provider.** Spec §7/§8 specify a single `ChangeNotifier`/Provider and explicitly call BLoC "overkill at this size." This repo uses `flutter_bloc` with a full clean-architecture layering at the client developer's direction. The tradeoff is real: more ceremony and more files than one screen strictly needs, against a structure that's familiar and extends cleanly. Spec §14 flags scope creep as a risk on a fixed-price trial; worth confirming the PDF gets updated so the doc and the code agree.

2. **`amharic_homophones` not used as the data source.** Spec Appendix B proposes reusing it. As of v0.0.2 on pub.dev it (a) depends on the Flutter SDK, which would violate the pure-Dart domain-layer constraint, and (b) does homophone *normalization* rather than family/sibling *mapping*, which is a different operation than `scan()` needs. The four family tables are ~10 lines of constants, so they're better hand-written here. Worth revisiting if the package changes.

## Open decisions

- **Mode A only, or Mode A + attempt Mode B?** Spec §5 recommends shipping Mode A (choice-point highlighting) as the guaranteed deliverable and attempting Mode B only if time remains. Not yet confirmed.

## What I'd try next

Per spec §13, in order: engine + unit tests (prove the idea in pure Dart before any UI) → the one screen → tap-to-swap → polish, builds, screenshots → Mode B if time allows.
