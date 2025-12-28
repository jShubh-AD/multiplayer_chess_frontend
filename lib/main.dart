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


final StreamController<GameMessage> gameStream = StreamController<GameMessage>.broadcast();

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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1C1A17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD18B47),
          secondary: Color(0xFFB58863),
          surface: Color(0xFF1E1E1E),
          background: Color(0xFF121212),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        textTheme: GoogleFonts.poppinsTextTheme().apply(
            bodyColor: const Color(0xFF000000),
            displayColor: const Color(0xFF000000)
        ).copyWith(
          bodyLarge: const TextStyle(fontWeight: FontWeight.w400),
          bodyMedium: const TextStyle(fontWeight: FontWeight.w500),
          titleLarge: const TextStyle(fontWeight: FontWeight.w600),
          headlineSmall: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFD18B47),
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

class FindGame extends StatefulWidget {
  const FindGame({super.key});

  @override
  State<FindGame> createState() => _FindGameState();
}

bool isWaiting = false;
late WebSocketChannel channel;
  StreamSubscription? subscription;

class _FindGameState extends State<FindGame> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(title: Text("My Chess")),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)
          ),
          onPressed: () async {
            try {
              channel = WebSocketChannel.connect(
                Uri.parse("wss://cljmb8ss-8000.inc1.devtunnels.ms/ws"),
              );
              setState(() => isWaiting = true);
              subscription = channel.stream.listen((message) {

                 final json = jsonDecode(message);
                GameMessage gameMsg = GameMessage.fromJson(json);
                gameStream.add(gameMsg);
                log("${gameMsg.toJson()}");

                if (gameMsg.type == MessageType.waiting) {
                  Fluttertoast.showToast(
                    msg: gameMsg.message ?? "Waiting for another player to join.",
                  );
                }
                if (gameMsg.type == MessageType.gameStart) {
                  setState(() => isWaiting = false);
                  Fluttertoast.showToast(msg: gameMsg.message ?? "Starting Game.");
                  // Navigator.push(
                  //   context,
                  //   // MaterialPageRoute(
                  //   //   builder: (c) => GamePage(channel: channel, clr: gameMsg.color!,),
                  //   // ),
                  // );
                }
              });
            } catch (e, st) {
              log("channel connection error", error: e, stackTrace: st);
              Fluttertoast.showToast(msg: "An error occured please try again");
            }
          },
          child: isWaiting
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color:Colors.orange
                      ),
                  ),
                )
              : Text("Find game"),
        ),
      ),
    );
  }
}
