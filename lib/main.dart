import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:chess_app/chess_game/landing_page.dart';
import 'package:chess_app/core/constants.dart';
import 'package:chess_app/home/game.dart';
import 'package:chess_app/home/message_model.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // ✅ Light matte background
        scaffoldBackgroundColor: const Color(0xFF1C1A17),

        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF9D4A),
          secondary: Color(0xFFB58863),
          surface: Color(0xFFFFFFFF),
          background: Color(0xFFF5F2ED),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Color(0xFF1C1A17),
          onBackground: Color(0xFF1C1A17),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD18B47),
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const LandingPage(),
    );
  }
}

