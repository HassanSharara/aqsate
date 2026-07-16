import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Palette — Deep Emerald
  static const Color primary = Color(0xFF00C896);
  static const Color primaryDark = Color(0xFF00A47C);
  static const Color primaryDeep = Color(0xFF007A5C);

  // Accent — Warm Gold
  static const Color accent = Color(0xFFFFB830);
  static const Color accentDark = Color(0xFFE09A10);

  // Semantic
  static const Color danger = Color(0xFFFF4B6E);
  static const Color success = Color(0xFF00C896);
  static const Color warning = Color(0xFFFFB830);
  static const Color info = Color(0xFF4B9EFF);

  // Background — macOS-style deep dark gradient
  static const Color bgDark = Color(0xFF0A1628);
  static const Color bgMid = Color(0xFF0D2137);
  static const Color bgSurface = Color(0xFF0F2847);

  // Glass surfaces
  static const Color glassLight = Color(0x18FFFFFF);
  static const Color glassMid = Color(0x22FFFFFF);
  static const Color glassBorder = Color(0x35FFFFFF);
  static const Color glassBorderLight = Color(0x20FFFFFF);

  // Legacy (kept for compat)
  static const Color background = Color(0xFF0A1628);
  static const Color surface = Color(0xFF132035);
  static const Color sidebar = Color(0xFF0B1E33);
  static const Color textPrimary = Color(0xFFEEF2FF);
  static const Color textSecondary = Color(0xFF8BA5C8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF0099CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFB830), Color(0xFFFF7730)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF4B6E), Color(0xFFCC2952)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient infoGradient = LinearGradient(
    colors: [Color(0xFF4B9EFF), Color(0xFF7B5BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF00A4A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient appBackground = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF0D2137), Color(0xFF0A1A30)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [Color(0xFF071525), Color(0xFF0C1E35)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? borderColor;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.width,
    this.height,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.glassLight,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? AppColors.glassBorder,
          width: 1,
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: child,
    );
  }
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.bgSurface,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
    );

    final textTheme = GoogleFonts.tajawalTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.tajawal(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.glassLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
        shadowColor: Colors.black45,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassMid,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        labelStyle: GoogleFonts.tajawal(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.tajawal(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 14),
        prefixIconColor: AppColors.textSecondary,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppColors.glassMid),
        headingTextStyle: GoogleFonts.tajawal(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          fontSize: 13.5,
        ),
        dataTextStyle: GoogleFonts.tajawal(color: AppColors.textPrimary, fontSize: 13.5),
        dividerThickness: 0.5,
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.glassMid;
          }
          return Colors.transparent;
        }),
      ),
      dividerColor: AppColors.glassBorder,
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF0D2137),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        elevation: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF132035),
        contentTextStyle: GoogleFonts.tajawal(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.glassLight,
        labelStyle: GoogleFonts.tajawal(color: AppColors.textPrimary, fontSize: 12.5),
        side: const BorderSide(color: AppColors.glassBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary;
            return AppColors.glassLight;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return AppColors.textSecondary;
          }),
          side: WidgetStateProperty.all(const BorderSide(color: AppColors.glassBorder)),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.tajawal(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.glassLight,
      ),
    );
  }
}
