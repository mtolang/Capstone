import 'package:flutter/material.dart';

/// Kindora App Theme - Centralized styling and colors
class AppTheme {
  // Primary Colors
  static const Color primaryTeal = Color(0xFF006A5B);
  static const Color primaryTealLight = Color(0xFF67AFA5);
  static const Color primaryTealDark = Color(0xFF004D40);
  
  // Accent Colors
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentOrangeLight = Color(0xFFFFB74D);
  
  // Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningAmber = Color(0xFFFFC107);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);
  
  // Neutral Colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color cardWhite = Colors.white;
  static const Color textDark = Color(0xFF212121);
  static const Color textGrey = Color(0xFF757575);
  static const Color divider = Color(0xFFE0E0E0);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryTeal, primaryTealLight],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentOrange, accentOrangeLight],
  );
  
  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
  
  // Border Radius
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(20));
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  
  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textDark,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textDark,
    letterSpacing: -0.3,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textDark,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textDark,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textDark,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textGrey,
    height: 1.4,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  // App Bar Style
  static AppBarTheme get appBarTheme => const AppBarTheme(
    backgroundColor: primaryTeal,
    elevation: 0,
    centerTitle: false,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  );
  
  // Elevated Button Style
  static ButtonStyle get elevatedButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryTeal,
    foregroundColor: Colors.white,
    elevation: 2,
    shadowColor: primaryTeal.withOpacity(0.3),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
    textStyle: buttonText,
  );
  
  // Outlined Button Style
  static ButtonStyle get outlinedButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primaryTeal,
    side: const BorderSide(color: primaryTeal, width: 2),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
    textStyle: buttonText,
  );
  
  // Text Button Style
  static ButtonStyle get textButtonStyle => TextButton.styleFrom(
    foregroundColor: primaryTeal,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    textStyle: buttonText,
  );
  
  // Input Decoration
  static InputDecoration inputDecoration({
    required String hint,
    String? label,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: bodyMedium.copyWith(color: textGrey.withOpacity(0.6)),
      labelStyle: bodyMedium.copyWith(color: textGrey),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: divider, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: divider, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: const BorderSide(color: primaryTeal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: const BorderSide(color: errorRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: const BorderSide(color: errorRed, width: 2),
      ),
    );
  }
  
  // Card Decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardWhite,
    borderRadius: cardRadius,
    boxShadow: cardShadow,
  );
  
  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
    color: cardWhite,
    borderRadius: cardRadius,
    boxShadow: elevatedShadow,
  );
  
  // Chip Style
  static ChipThemeData get chipTheme => ChipThemeData(
    backgroundColor: primaryTealLight.withOpacity(0.1),
    labelStyle: bodySmall.copyWith(color: primaryTeal),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: const RoundedRectangleBorder(borderRadius: chipRadius),
  );
  
  // Loading Indicator
  static Widget loadingIndicator({Color? color}) {
    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(color ?? primaryTeal),
      strokeWidth: 3,
    );
  }
  
  // Snackbar
  static SnackBar successSnackbar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: successGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: buttonRadius),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
  
  static SnackBar errorSnackbar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: errorRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: buttonRadius),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    );
  }
  
  static SnackBar infoSnackbar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.info, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: infoBlue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: buttonRadius),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
}
