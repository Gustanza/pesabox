import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color teal900 = Color(0xFF0B4A3D);
  static const Color teal800 = Color(0xFF0F5F4C);
  static const Color teal700 = Color(0xFF136B54);

  static const Color green600 = Color(0xFF18A672);
  static const Color green500 = Color(0xFF1FBF82);
  static const Color green100 = Color(0xFFE3F5EC);

  static const Color gold500 = Color(0xFFD9A441);
  static const Color gold100 = Color(0xFFFBF1DE);

  static const Color cream = Color(0xFFF6F8F7);
  static const Color white = Color(0xFFFFFFFF);

  static const Color ink900 = Color(0xFF152420);
  static const Color ink700 = Color(0xFF33423E);
  static const Color ink600 = Color(0xFF4B5A56);
  static const Color ink400 = Color(0xFF8A9895);

  static const Color line = Color(0xFFE4EAE7);
  static const Color danger = Color(0xFFE15454);
  static const Color danger100 = Color(0xFFFCEAEA);
  static const Color blue = Color(0xFF3E7BFA);
}

class AppRadius {
  AppRadius._();

  static const BorderRadius lg = BorderRadius.all(Radius.circular(22));
  static const BorderRadius md = BorderRadius.all(Radius.circular(14));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(10));

  static BorderRadius circular(double r) => BorderRadius.circular(r);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final baseTextTheme = GoogleFonts.interTextTheme();
    final headingTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    final textTheme = baseTextTheme.copyWith(
      displayLarge: headingTextTheme.displayLarge?.copyWith(
        color: AppColors.ink900,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: headingTextTheme.displayMedium?.copyWith(
        color: AppColors.ink900,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: headingTextTheme.displaySmall?.copyWith(
        color: AppColors.ink900,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: headingTextTheme.headlineLarge?.copyWith(
        color: AppColors.ink900,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: headingTextTheme.headlineMedium?.copyWith(
        color: AppColors.ink900,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: headingTextTheme.headlineSmall?.copyWith(
        color: AppColors.ink900,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: headingTextTheme.titleLarge?.copyWith(
        color: AppColors.ink900,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: headingTextTheme.titleMedium?.copyWith(
        color: AppColors.ink900,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: headingTextTheme.titleSmall?.copyWith(
        color: AppColors.ink900,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: AppColors.ink900,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.ink700,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: AppColors.ink600,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        color: AppColors.white,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        color: AppColors.ink600,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        color: AppColors.ink400,
        fontWeight: FontWeight.w500,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal900,
        brightness: Brightness.light,
        primary: AppColors.teal900,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.green100,
        onPrimaryContainer: AppColors.teal900,
        secondary: AppColors.green600,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.green100,
        onSecondaryContainer: AppColors.teal800,
        tertiary: AppColors.gold500,
        onTertiary: AppColors.white,
        tertiaryContainer: AppColors.gold100,
        onTertiaryContainer: AppColors.ink900,
        error: AppColors.danger,
        onError: AppColors.white,
        errorContainer: AppColors.danger100,
        onErrorContainer: AppColors.danger,
        surface: AppColors.white,
        onSurface: AppColors.ink900,
        onSurfaceVariant: AppColors.ink600,
        outline: AppColors.line,
        outlineVariant: AppColors.line,
        shadow: Colors.black26,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.ink900,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.ink900,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink900),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
          side: const BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal900,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.ink400,
          disabledForegroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.md,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.teal900,
          side: const BorderSide(color: AppColors.teal900, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.md,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.teal900,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.sm,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.ink400,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.ink600,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.danger,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.line, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.line, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide:
              const BorderSide(color: AppColors.teal900, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.green100,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.teal800,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.sm,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.teal900,
        unselectedItemColor: AppColors.ink400,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink900,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.ink900,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.ink600,
          fontWeight: FontWeight.w400,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.line,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.teal900,
        unselectedLabelColor: AppColors.ink400,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.teal900, width: 2),
          insets: EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.teal900,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.ink900,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.ink600,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.teal900,
        linearTrackColor: AppColors.line,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
