import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Indigo / violet — feels modern, calm and professional and pairs well
  // with both English and Arabic typography.
  static const _seed = Color(0xFF6366F1);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static SystemUiOverlayStyle overlayFor(Brightness b) => b == Brightness.dark
      ? SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        )
      : SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        );

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;

    final base = ThemeData(brightness: brightness, useMaterial3: true);

    final textTheme = GoogleFonts.cairoTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.cairo(
          textStyle: base.textTheme.displayLarge,
          fontWeight: FontWeight.w800,
          letterSpacing: -1),
      displayMedium: GoogleFonts.cairo(
          textStyle: base.textTheme.displayMedium,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5),
      headlineLarge: GoogleFonts.cairo(
          textStyle: base.textTheme.headlineLarge, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.cairo(
          textStyle: base.textTheme.headlineMedium,
          fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.cairo(
          textStyle: base.textTheme.headlineSmall, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.cairo(
          textStyle: base.textTheme.titleLarge, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.cairo(
          textStyle: base.textTheme.titleMedium, fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.cairo(
          textStyle: base.textTheme.titleSmall, fontWeight: FontWeight.w600),
      labelLarge: GoogleFonts.cairo(
          textStyle: base.textTheme.labelLarge, fontWeight: FontWeight.w600),
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
        systemOverlayStyle: overlayFor(brightness),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withOpacity(0.6)),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        filled: true,
        fillColor:
            isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      tabBarTheme: TabBarTheme(
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: scheme.primary, width: 2.5),
        ),
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withOpacity(0.6),
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: scheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.cairo(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: scheme.outline,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: GoogleFonts.cairo(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        extendedTextStyle:
            GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconColor: scheme.onSurfaceVariant,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            GoogleFonts.cairo(
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
                fontSize: 12)),
      ),
    );
  }
}
