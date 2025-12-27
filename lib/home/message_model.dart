import 'package:chess_app/core/constants.dart';

class GameMessage {
  final MessageType? type;
  final String? message;
  final String? data;
  final Color? color;
  final Color? turn;
  final bool? gameOver;
  final String? winner;

  GameMessage({
    this.type,
    this.message,
    this.data,
    this.color,
    this.turn,
    this.gameOver,
    this.winner,
  });

  factory GameMessage.fromJson(Map<String, dynamic> json) => GameMessage(
    type: json['type'] != null
        ? MessageType.values.firstWhere((e) => e.value == json['type'])
        : null,
    message: json['message'],
    data: json['data'],
    color: json['color'] != null
        ? Color.values.firstWhere((e) => e.value == json['color'])
        : null,
    turn: json['turn'] != null
        ? Color.values.firstWhere((e) => e.value == json['turn'])
        : null,
    gameOver: json['game_over'],
    winner: json['winner'],
  );

  Map<String, dynamic> toJson() => {
    'type': type?.value,
    'message': message,
    'data': data,
    'color': color?.value,
    'turn': turn?.value,
    'game_over': gameOver,
    'winner': winner,
  };
}
