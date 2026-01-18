import 'package:chess_app/core/constants.dart';

class GameMessage {
  final MessageType? type;
  final String? message;
  final String? color;
  final String? turn;
  final bool? gameOver;
  final String? move;
  final String? board;

  GameMessage({
    this.board,
    this.move,
    this.type,
    this.message,
    this.color,
    this.turn,
    this.gameOver,
  });

  factory GameMessage.fromJson(Map<String, dynamic> json) => GameMessage(
    type: json['type'] != null
        ? MessageType.values.firstWhere((e) => e.value == json['type'])
        : null,
    message: json['message'],
    move: json['move'],
    board: json['board'],
    color: json['color'],
    turn: json['turn'],
    gameOver: json['game_over'],
  );

  Map<String, dynamic> toJson() => {
    'type': type?.value,
    'message': message,
    'color': color,
    'turn': turn,
    "board": board,
    'move': move,
    'game_over': gameOver,
  };
}
