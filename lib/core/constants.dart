enum GameColor {
  black('black'),
  white('white');

  final String value;
  const GameColor(this.value);
}

enum MessageType {
  waiting('waiting'),
  gameStart('game_start'),
  move('move'),
  gameOver('game_over'),
  checkMate('checkmate'),
  draw('draw'),
  illegalMove('illegal_move'),
  whiteWins('white'),
  blackWins('black'),
  timeout('timeout');

  final String value;
  const MessageType(this.value);
}

enum PlayMode {
  offline,
  bot,
}

