import 'package:flutter/material.dart';

/// Colors that stay the same in both themes.
class AppColors {
  static const Color primary = Color(0xFF0D47A1);
  static const Color primaryDark = Color(0xFF08306B);
  static const Color primaryLight = Color(0xFF5472D3);
  static const Color accent = Color(0xFFFF7043);
  static const Color background = Color.fromARGB(255, 105, 164, 242);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF1B2430);
  static const Color textMuted = Color(0xFF7A8699);
  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFD32F2F);
}

/// Colors that change between Light and Dark. Read them with `context.pal`.
///
///   Light card:  context.pal.surface   Dark card:  navy
///   Main text:   context.pal.text
///   Small text:  context.pal.muted
///   Blue accent: context.pal.link  (icons, selected items)
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color surface; // cards, sheets, tiles
  final Color text; // main text on a card
  final Color muted; // secondary text on a card
  final Color link; // blue accent on a card (icons, selected item)
  final Color badge; // filled blue circle (step numbers)
  final Color good; // "fresh" green
  final Color bad; // "stale" red
  final Color waterTop; // underwater gradient
  final Color waterMid;
  final Color waterBottom;
  final Color navGlass; // nav bar tint (alpha is applied in the nav bar)
  final Color navBorder; // nav bar outline

  const AppPalette({
    required this.surface,
    required this.text,
    required this.muted,
    required this.link,
    required this.badge,
    required this.good,
    required this.bad,
    required this.waterTop,
    required this.waterMid,
    required this.waterBottom,
    required this.navGlass,
    required this.navBorder,
  });

  static const AppPalette light = AppPalette(
    surface: Colors.white,
    text: Color(0xFF1B2430),
    muted: Color(0xFF7A8699),
    link: Color(0xFF0D47A1),
    badge: Color(0xFF0D47A1),
    good: Color(0xFF2E7D32),
    bad: Color(0xFFD32F2F),
    waterTop: Color(0xFF69A4F2),
    waterMid: Color(0xFF2F6FD0),
    waterBottom: Color(0xFF0D47A1),
    navGlass: Colors.white,
    navBorder: Color(0x99FFFFFF),
  );

  static const AppPalette dark = AppPalette(
    surface: Color(0xFF16253F),
    text: Color(0xFFEAF1FB),
    muted: Color(0xFF9DB0CC),
    link: Color(0xFF8DB8FF),
    badge: Color(0xFF2F6FD0),
    good: Color(0xFF66BB6A),
    bad: Color(0xFFFF6B6B),
    waterTop: Color(0xFF1E4A86),
    waterMid: Color(0xFF123463),
    waterBottom: Color(0xFF071A38),
    navGlass: Color(0xFF0B1B33),
    navBorder: Color(0x26FFFFFF),
  );

  @override
  AppPalette copyWith({
    Color? surface,
    Color? text,
    Color? muted,
    Color? link,
    Color? badge,
    Color? good,
    Color? bad,
    Color? waterTop,
    Color? waterMid,
    Color? waterBottom,
    Color? navGlass,
    Color? navBorder,
  }) {
    return AppPalette(
      surface: surface ?? this.surface,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      link: link ?? this.link,
      badge: badge ?? this.badge,
      good: good ?? this.good,
      bad: bad ?? this.bad,
      waterTop: waterTop ?? this.waterTop,
      waterMid: waterMid ?? this.waterMid,
      waterBottom: waterBottom ?? this.waterBottom,
      navGlass: navGlass ?? this.navGlass,
      navBorder: navBorder ?? this.navBorder,
    );
  }

  // Lets Flutter fade smoothly between Light and Dark.
  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      surface: l(surface, other.surface),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      link: l(link, other.link),
      badge: l(badge, other.badge),
      good: l(good, other.good),
      bad: l(bad, other.bad),
      waterTop: l(waterTop, other.waterTop),
      waterMid: l(waterMid, other.waterMid),
      waterBottom: l(waterBottom, other.waterBottom),
      navGlass: l(navGlass, other.navGlass),
      navBorder: l(navBorder, other.navBorder),
    );
  }
}

extension PaletteContext on BuildContext {
  /// Colors for the current theme. Using it makes the widget rebuild
  /// when the user switches between Light and Dark.
  AppPalette get pal =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

class AppTheme {
  static ThemeData get light => _build(Brightness.light, AppPalette.light);
  static ThemeData get dark => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette pal) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Roboto',
      // Only seen on screens that have no underwater background
      // (for example the scan result screen).
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0F2547)
          : AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: isDark ? pal.link : AppColors.primary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : AppColors.textDark,
      ),
      extensions: [pal],
    );
  }
}
