import 'package:chess_app/home/game.dart';
import 'package:flutter/material.dart';
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
          seedColor: Colors.orange.withOpacity(0.2)
          ),
      ),
      home: FindGame()
    );
  }
}

class FindGame extends StatelessWidget {
  const FindGame({super.key});

  @override
  Widget build(BuildContext context) {
    late WebSocketChannel channel; 
    
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text("My Chess"),
      ),
      body: Center(
      child: ElevatedButton(
        onPressed: (){
          channel = WebSocketChannel.connect(Uri.parse("wss://cljmb8ss-8000.inc1.devtunnels.ms/ws"));
          print("made connection ${channel}");
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (c)=> GamePage(channel: channel)
              )
            );
        },
        child: Text("Find game")
        ),
    )
    );
  }
}