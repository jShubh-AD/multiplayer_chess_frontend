import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
        

class GamePage extends StatefulWidget {
  const GamePage({super.key, required this.channel});

  final WebSocketChannel channel;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {

  final ChessBoardController controller = ChessBoardController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chess'),
      ),
      body: Center(
        child: StreamBuilder(stream: widget.channel.stream, builder: (context, snapshot){
          return ChessBoard(
            controller: controller,
            boardColor: BoardColor.orange,
            boardOrientation: PlayerColor.white,
          );
        })
      ),
    );
  }
}