import 'package:flutter/material.dart';

/// Brand color system — extracted from `AppColors.kt`.
/// Same identity on iOS and Android (not the default gray Cupertino look).
class AppColors {
  AppColors._();

  static const Color canvas = Color(0xFF181234); // midnight
  static const Color surface = Color(0xFF221A47); // midnight plum
  static const Color surfaceElevated = Color(0xFF2B2256); // cards
  static const Color surfaceAccent = Color(0xFF463399); // royal amethyst (buttons)

  static const Color brand = Color(0xFF9E8FFF); // light amethyst
  static const Color brandStrong = Color(0xFFB7A8FF); // prominent headings

  static const Color textPrimary = Color(0xFFF2EFFA);
  static const Color textSecondary = Color(0xFFCDC7E6); // lilac mist
  static const Color textTertiary = Color(0xFF9990BE);

  static const Color live = Color(0xFFFF5C61); // live / error
  static const Color success = Color(0xFF4FD39A);
  static const Color warning = Color(0xFFFFC766);

  static const Color divider = Color(0x1ACDC7E6); // translucent dividers (~10%)

  // Hero gradient
  static const Color heroTop = Color(0xCC181234);
  static const Color heroBottom = Color(0xF2181234);
}

/// Shared corner radii and paddings — a modern iOS feel (soft rounded cards).
class AppRadii {
  AppRadii._();
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 100;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppTheme {
  AppTheme._();

  /// Thmanyah Sans — the app's primary font.
  static const String fontFamily = 'Thmanyah';

  /// Dark theme — the only one supported (the brand is always dark).
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    // The Thmanyah font is applied across the whole app.
    final textTheme = base.textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.canvas,
        primary: AppColors.brand,
        secondary: AppColors.brandStrong,
        error: AppColors.live,
        onPrimary: AppColors.canvas,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: textTheme.copyWith(
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerColor: AppColors.divider,
      splashColor: AppColors.brand.withValues(alpha: 0.12),
      highlightColor: AppColors.brand.withValues(alpha: 0.08),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardColor: AppColors.surfaceElevated,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    );
  }
}
