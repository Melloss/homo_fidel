import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Light and dark themes built on the spec's palette.
///
/// The schemes are written out explicitly rather than derived with
/// [ColorScheme.fromSeed]: seeding re-derives every role through M3's tonal
/// palettes, which shifts the brand navy and gold off their sampled values.
/// The point here is to match the document, so the colours are stated.
abstract final class AppTheme {
  const AppTheme._();

  /// Ge'ez text is the entire product surface, so the bundled Ethiopic face is
  /// the app-wide default rather than something opted into per widget.
  static const _fontFamily = 'NotoSansEthiopic';

  static final light = _base(
    const ColorScheme.light(
      primary: AppColors.navy,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      // Gold is only ever a background. Navy on gold reads 8.31:1; gold on
      // white reads 1.92:1 and must never carry text.
      onSecondary: AppColors.navy,
      surface: Colors.white,
      onSurface: AppColors.ink,
      surfaceContainer: AppColors.surface,
      onSurfaceVariant: AppColors.muted,
      // outline is for interactive edges and needs 3:1; AppColors.line is
      // 1.46:1 on white, so it stays decorative-only as outlineVariant.
      outline: AppColors.muted,
      outlineVariant: AppColors.line,
    ),
  );

  static final dark = _base(
    const ColorScheme.dark(
      // Navy is too close to the dark surface to read as an accent, so the
      // roles invert: gold leads (8.07:1 on ink) and navy becomes a container.
      primary: AppColors.gold,
      onPrimary: AppColors.navy,
      secondary: AppColors.gold,
      onSecondary: AppColors.navy,
      surface: AppColors.ink,
      onSurface: AppColors.surface,
      surfaceContainer: AppColors.navy,
      onSurfaceVariant: AppColors.line,
      outline: AppColors.line,
      outlineVariant: AppColors.muted,
    ),
  );

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
