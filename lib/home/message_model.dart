class GameMessage {
  final String type;
  final String? message;
  final String? data;
  final String? color;
  final String? turn;
  final bool? gameOver;
  final String? winner;

  GameMessage({
    required this.type,
    this.message,
    this.data,
    this.color,
    this.turn,
    this.gameOver,
    this.winner,
  });

  factory GameMessage.fromJson(Map<String, dynamic> json) => GameMessage(
    type: json['type'],
    message: json['message'],
    data: json['data'],
    color: json['color'],
    turn: json['turn'],
    gameOver: json['game_over'],
    winner: json['winner'],
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'message': message,
    'data': data,
    'color': color,
    'turn': turn,
    'game_over': gameOver,
    'winner': winner,
  };
}
