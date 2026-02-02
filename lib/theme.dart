import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusButtonColors extends ThemeExtension<StatusButtonColors> {
  final Color leftSelected;
  final Color leftUnselected;
  final Color rightSelected;
  final Color rightUnselected;
  final Color iconSelected;
  final Color iconUnselected;

  const StatusButtonColors({
    required this.leftSelected,
    required this.leftUnselected,
    required this.rightSelected,
    required this.rightUnselected,
    required this.iconSelected,
    required this.iconUnselected,
  });

  @override
  ThemeExtension<StatusButtonColors> copyWith({
    Color? leftSelected,
    Color? leftUnselected,
    Color? rightSelected,
    Color? rightUnselected,
    Color? iconSelected,
    Color? iconUnselected,
  }) {
    return StatusButtonColors(
      leftSelected: leftSelected ?? this.leftSelected,
      leftUnselected: leftUnselected ?? this.leftUnselected,
      rightSelected: rightSelected ?? this.rightSelected,
      rightUnselected: rightUnselected ?? this.rightUnselected,
      iconSelected: iconSelected ?? this.iconSelected,
      iconUnselected: iconUnselected ?? this.iconUnselected,
    );
  }

  @override
  ThemeExtension<StatusButtonColors> lerp(
    ThemeExtension<StatusButtonColors>? other,
    double t,
  ) {
    if (other is! StatusButtonColors) {
      return this;
    }
    return StatusButtonColors(
      leftSelected: Color.lerp(leftSelected, other.leftSelected, t)!,
      leftUnselected: Color.lerp(leftUnselected, other.leftUnselected, t)!,
      rightSelected: Color.lerp(rightSelected, other.rightSelected, t)!,
      rightUnselected: Color.lerp(rightUnselected, other.rightUnselected, t)!,
      iconSelected: Color.lerp(iconSelected, other.iconSelected, t)!,
      iconUnselected: Color.lerp(iconUnselected, other.iconUnselected, t)!,
    );
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Color(0xFF015C8F),
      // User chat bubble
      cardTheme: CardThemeData(
        color: Color(0xFFA54607),
        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      // Settings buttons colors
      colorScheme: ColorScheme.light(
        primary: Color(0xFF015C8F),
        secondary: Color(0xFF2C3E73),
        tertiary: Color(0xFF2E2E2E),
      ),
      // Status page button colors
      extensions: <ThemeExtension<dynamic>>[
        StatusButtonColors(
          leftSelected: Color(0xFF006D6F),
          leftUnselected: Color(0xFF409193),
          rightSelected: Color(0xFF015C8F),
          rightUnselected: Color.fromARGB(255, 118, 160, 187),
          iconSelected: Colors.white,
          iconUnselected: Color(0xFF9FC2D5),
        ),
      ],
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          elevation: 6,
          padding: EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: GoogleFonts.notoSansTextTheme().copyWith(
        headlineMedium: TextStyle(fontSize: 28.0, color: Colors.black),
        headlineLarge: TextStyle(fontSize: 32.0, color: Colors.black),
        displaySmall: TextStyle(fontSize: 36.0, color: Colors.black),
        displayMedium: TextStyle(fontSize: 45.0, color: Colors.black),
      ),
      iconTheme: IconThemeData(color: Color(0xFF015C8F)),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFF015C8F),
        selectedIconTheme: IconThemeData(color: Colors.white),
        unselectedItemColor: Color.fromARGB(255, 118, 160, 187),
        unselectedIconTheme: IconThemeData(color: Color(0xFF9FC2D5)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF015C8F),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 36.0,
          fontWeight: FontWeight.bold,
          color: Colors.white
        ),
        centerTitle: true,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        backgroundColor: Color(0xFF015C8F),
        textColor: Colors.white,
        collapsedTextColor: Colors.white,
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xFF0086D0),
      // User chat bubble
      cardTheme: CardThemeData(
        color: Color(0xFFA54607),
        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      // Settings buttons colors
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF0086D0), // 06C1C4
        secondary: Color(0xFF7C91CE), 
        tertiary: Color(0xFFBAB2B2),
      ),
      // Status page button colors
      extensions: <ThemeExtension<dynamic>>[
        StatusButtonColors(
          leftSelected: Color(0xFF06C1C4),
          leftUnselected: Color(0xFF0c989a),
          rightSelected: Color(0xFF0086D0),
          rightUnselected: Color(0xFF076CA3),
          iconSelected: Colors.black,
          iconUnselected: Color(0xFF033651),
        ),
      ],
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          elevation: 4,
          padding: EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: GoogleFonts.notoSansTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ).copyWith(
        headlineMedium: TextStyle(fontSize: 28.0, color: Colors.white),
        headlineLarge: TextStyle(fontSize: 32.0, color: Colors.white),
        displaySmall: TextStyle(fontSize: 36.0, color: Colors.white),
        displayMedium: TextStyle(fontSize: 45.0, color: Colors.white),
      ),
      iconTheme: IconThemeData(color: Color(0xFF0086D0)),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFF0086D0),
        selectedIconTheme: IconThemeData(color: Colors.black),
        unselectedItemColor: Color.fromARGB(255, 41, 131, 180),
        unselectedIconTheme: IconThemeData(color: Color(0xFF033651)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF0086D0),
        foregroundColor: Colors.black,
        titleTextStyle: TextStyle(
          fontSize: 36.0,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        centerTitle: true,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        backgroundColor: Color(0xFF0086D0),
        textColor: Colors.black,
        collapsedTextColor: Colors.black,
        iconColor: Colors.black,
        collapsedIconColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: Colors.black,
      ),
    );
  }
}