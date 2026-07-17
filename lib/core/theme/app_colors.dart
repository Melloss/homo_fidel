import 'package:flutter/material.dart';

/// Brand palette, sampled directly from docs/Homofidel_Concept_Spec.pdf.
///
/// [navy] is the spec's header block and [gold] its accent text — the pairing
/// the document already uses for fidäl on the cover, and the app icon.
///
/// Contrast is load-bearing here, so the numbers are recorded rather than
/// assumed. Gold reads at 8.31:1 on navy but only 1.92:1 on white: it is a
/// background or dark-surface accent, never a foreground colour on a light
/// surface.
abstract final class AppColors {
  const AppColors._();

  // --- Sampled from the spec ---------------------------------------------
  /// Header block. Primary.
  static const navy = Color(0xFF14213D);

  /// Accent text and section numbers on navy. Secondary.
  static const gold = Color(0xFFE4B363);

  /// Page surface behind tables and callouts.
  static const surface = Color(0xFFF5F6F9);

  /// Code-block background; doubles as the dark-mode surface and body ink.
  static const ink = Color(0xFF1F2430);

  /// Secondary/label text. 4.83:1 on white.
  static const muted = Color(0xFF6B7280);

  /// Decorative rules and table borders. Too light for interactive edges.
  static const line = Color(0xFFCFD6E6);

  // --- Derived: the two highlight weights (spec §6, §14) ------------------
  // §14 names Mode A noise as a live risk: ሰ and አ are everywhere, so flagging
  // every choice point can look busy. The mitigation is a weight difference —
  // subtle for "you chose here", saturated for "this is probably wrong".

  /// Mode A — a homophone choice point. Gold at 22% over white; deliberately
  /// quiet. Navy on it reads 13.92:1.
  static const choicePoint = Color(0xFFF9EEDD);

  /// Mode B — a likely error. Full-strength gold; the stronger signal.
  /// Navy on it reads 8.31:1.
  static const likelyError = gold;

  /// Mode A choice point on dark surfaces. Light text on it reads 9.01:1.
  static const choicePointDark = Color(0xFF4A433B);
}
