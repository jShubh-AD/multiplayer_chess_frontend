import 'dart:developer';

import 'package:chess_app/home/game.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Chess',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange.withOpacity(0.2),
        ),
      ),
      home: FindGame(),
    );
  }
}

class FindGame extends StatefulWidget {
  const FindGame({super.key});

  @override
  State<FindGame> createState() => _FindGameState();
}

bool isWaiting = false;

class _FindGameState extends State<FindGame> {
  @override
  Widget build(BuildContext context) {
    late WebSocketChannel channel;

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
              channel.stream.listen((message) {
                if (message == "waiting") {
                  Fluttertoast.showToast(
                    msg: "Waiting for another player to join.",
                  );
                }
                if (message == "game_start") {
                  setState(() => isWaiting = false);
                  Fluttertoast.showToast(msg: "Starting Game.");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => GamePage(channel: channel),
                    ),
                  );
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
