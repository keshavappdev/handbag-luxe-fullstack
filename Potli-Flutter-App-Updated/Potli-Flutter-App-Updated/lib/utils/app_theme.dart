import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class KColors {
  static const black = Color(0xFF0A0A0A);
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF5F3EE);
  static const porcelain = Color(0xFFEAE6DE);
  static const charcoal = Color(0xFF1B1B1B);
  static const gray = Color(0xFF74716C);
  static const line = Color(0xFFD8D3CA);
}

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final body = GoogleFonts.montserratTextTheme(base.textTheme).apply(
      bodyColor: KColors.black,
      displayColor: KColors.black,
    );
    return base.copyWith(
      scaffoldBackgroundColor: KColors.offWhite,
      colorScheme: const ColorScheme.light(
        primary: KColors.black,
        secondary: KColors.charcoal,
        surface: KColors.offWhite,
        onPrimary: KColors.white,
        onSurface: KColors.black,
      ),
      textTheme: body,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: KColors.offWhite,
        foregroundColor: KColors.black,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: KColors.line,
      splashColor: KColors.black.withValues(alpha: .04),
      highlightColor: Colors.transparent,
      inputDecorationTheme: const InputDecorationTheme(
        filled: false,
        border: UnderlineInputBorder(borderSide: BorderSide(color: KColors.black)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: KColors.line)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: KColors.black, width: 1.4)),
        labelStyle: TextStyle(fontSize: 9, letterSpacing: 1.8, color: KColors.gray),
        contentPadding: EdgeInsets.symmetric(vertical: 16),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}

extension LuxuryText on TextTheme {
  TextStyle get micro => GoogleFonts.montserrat(
    fontSize: 9,
    height: 1.35,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.2,
  );

  TextStyle get editorial => GoogleFonts.cormorantGaramond(
    fontSize: 70,
    height: .82,
    fontWeight: FontWeight.w400,
    letterSpacing: -2.0,
  );

  TextStyle get editorialSmall => GoogleFonts.cormorantGaramond(
    fontSize: 50,
    height: .9,
    fontWeight: FontWeight.w400,
    letterSpacing: -1.2,
  );

  TextStyle get productTitle => GoogleFonts.cormorantGaramond(
    fontSize: 20,
    height: 1.05,
    fontWeight: FontWeight.w500,
    letterSpacing: -.2,
  );
}
