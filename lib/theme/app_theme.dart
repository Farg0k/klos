import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The light and dark klos themes, built from the brand colour.
///
/// The brand blue is the primary colour in both modes, so buttons, switches,
/// links, selections and the app bar stay recognizably klos. Every corner has
/// an 8 px radius so buttons, cards and fields do not turn into pills.
class AppTheme {
  AppTheme._();

  /// The klos brand colour.
  ///
  /// It defines the app theme and matches the launcher icon, the splash
  /// screen and the favicon the Kindle browser receives.
  static const Color brand = Color(0xFF0D8BD0);

  /// The radius of every rounded corner in the interface.
  static final BorderRadius borderRadius = BorderRadius.circular(8);

  static final ThemeData lightTheme = _buildTheme(Brightness.light);
  static final ThemeData darkTheme = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    const lightBackground = Color(0xFFF6F4EE);
    final base = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final scheme = base.copyWith(
      primary: brand,
      onPrimary: Colors.white,
      primaryContainer: brightness == Brightness.light
          ? const Color(0xFFCDEAF8)
          : const Color(0xFF08415C),
      onPrimaryContainer: brightness == Brightness.light
          ? const Color(0xFF063247)
          : const Color(0xFFCDEAF8),
    );
    final shape = RoundedRectangleBorder(borderRadius: borderRadius);
    final outline = OutlineInputBorder(borderRadius: borderRadius);

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? lightBackground
          : scheme.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: brand,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        shape: shape,
      ),
      dialogTheme: DialogThemeData(shape: shape),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(shape: shape),
      chipTheme: ChipThemeData(shape: shape),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: brand),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: brand,
        selectionHandleColor: brand,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: shape),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(shape: shape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: shape),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: shape),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: outline,
        enabledBorder: outline,
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: brand, width: 2),
        ),
      ),
    );
  }
}
