import 'package:flutter/material.dart';

import 'presentation/screens/pos_home_screen.dart';

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0F766E);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Offline POS',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: seed,
              brightness: Brightness.light,
            ).copyWith(
              primary: const Color(0xFF0F766E),
              secondary: const Color(0xFFD97706),
              surface: const Color(0xFFF7F7F2),
              error: const Color(0xFFB42318),
            ),
        scaffoldBackgroundColor: const Color(0xFFF2F4EF),
        appBarTheme: const AppBarTheme(centerTitle: false),
        cardTheme: const CardThemeData(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(),
        ),
      ),
      home: const PosHomeScreen(),
    );
  }
}
