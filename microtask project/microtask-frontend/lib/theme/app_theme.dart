import 'package:flutter/material.dart'; 
 
 class AppTheme { 
   // Colors 
   static const Color navy = Color(0xFF1E3A5F); 
   static const Color navyDark = Color(0xFF122440); 
   static const Color navyLight = Color(0xFF2C5282); 
   static const Color gold = Color(0xFFC9A84C); 
   static const Color goldLight = Color(0xFFE8C87A); 
   static const Color cream = Color(0xFFFAF8F3); 
   static const Color white = Color(0xFFFFFFFF); 
   static const Color textDark = Color(0xFF1a1a2e); 
   static const Color textMuted = Color(0xFF5a6a7a); 
   static const Color border = Color(0xFFe2e8f0); 
   static const Color success = Color(0xFF28a745); 
   static const Color error = Color(0xFFdc3545); 
   static const Color warning = Color(0xFFf59e0b); 
 
   // Text Styles 
   static const TextStyle heading1 = TextStyle( 
     fontSize: 28, fontWeight: FontWeight.w700, color: navy); 
   static const TextStyle heading2 = TextStyle( 
     fontSize: 22, fontWeight: FontWeight.w700, color: navy); 
   static const TextStyle heading3 = TextStyle( 
     fontSize: 18, fontWeight: FontWeight.w600, color: navy); 
   static const TextStyle body = TextStyle( 
     fontSize: 14, fontWeight: FontWeight.w400, color: textDark); 
   static const TextStyle bodyMuted = TextStyle( 
     fontSize: 13, fontWeight: FontWeight.w400, color: textMuted); 
   static const TextStyle small = TextStyle( 
     fontSize: 11, fontWeight: FontWeight.w400, color: textMuted); 
 
   // Button Styles 
   static ButtonStyle primaryButton = ElevatedButton.styleFrom( 
     backgroundColor: navy, 
     foregroundColor: white, 
     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), 
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
     elevation: 0, 
   ); 
 
   static ButtonStyle goldButton = ElevatedButton.styleFrom( 
     backgroundColor: gold, 
     foregroundColor: white, 
     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), 
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
     elevation: 0, 
   ); 
 
   static ButtonStyle outlineButton = OutlinedButton.styleFrom( 
     foregroundColor: navy, 
     side: const BorderSide(color: navy, width: 1.5), 
     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), 
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
   ); 
 
   // Card decoration 
   static BoxDecoration cardDecoration = BoxDecoration( 
     color: white, 
     borderRadius: BorderRadius.circular(12), 
     border: Border.all(color: border, width: 0.5), 
     boxShadow: [ 
       BoxShadow( 
         color: Colors.black.withOpacity(0.04), 
         blurRadius: 8, 
         offset: const Offset(0, 2), 
       ) 
     ], 
   ); 
 
   // App Theme 
   static ThemeData get theme => ThemeData( 
     primaryColor: navy, 
     scaffoldBackgroundColor: cream, 
     colorScheme: const ColorScheme.light( 
       primary: navy, 
       secondary: gold, 
       surface: white, 
       background: cream, 
       error: error, 
     ), 
     appBarTheme: const AppBarTheme( 
       backgroundColor: navy, 
       foregroundColor: white, 
       elevation: 0, 
       centerTitle: true, 
       titleTextStyle: TextStyle( 
         color: white, 
         fontSize: 18, 
         fontWeight: FontWeight.w700, 
       ), 
     ), 
     elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton), 
     inputDecorationTheme: InputDecorationTheme( 
       filled: true, 
       fillColor: white, 
       border: OutlineInputBorder( 
         borderRadius: BorderRadius.circular(10), 
         borderSide: const BorderSide(color: border), 
       ), 
       enabledBorder: OutlineInputBorder( 
         borderRadius: BorderRadius.circular(10), 
         borderSide: const BorderSide(color: border), 
       ), 
       focusedBorder: OutlineInputBorder( 
         borderRadius: BorderRadius.circular(10), 
         borderSide: const BorderSide(color: navy, width: 1.5), 
       ), 
       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 
       hintStyle: const TextStyle(color: textMuted, fontSize: 13), 
     ), 
   ); 
 } 
