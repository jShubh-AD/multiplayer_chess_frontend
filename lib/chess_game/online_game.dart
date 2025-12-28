import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';
import '../home/message_model.dart';
import 'capture_pieces.dart';

class OnlineGame extends StatefulWidget {
  const OnlineGame({super.key});

  @override
  State<OnlineGame> createState() => _OnlineGameState();
}

class _OnlineGameState extends State<OnlineGame> {
  // socket
  late WebSocketChannel chanel;
  StreamSubscription? subs;
  final uri = Uri.parse("wss://cljmb8ss-8000.inc1.devtunnels.ms/ws");

  // chess board variables
  Position position = Chess.initial;
  Position? lastPos;

  String fen = kInitialBoardFEN;
  ValidMoves validMoves = makeLegalMoves(Chess.initial);
  Side mySide = Side.white;

  // moves
  NormalMove? lastMove;
  NormalMove? preMove;
  NormalMove? promotionMove;
  PieceSet pieceSet = PieceSet.gioco;

  // state variables
  bool waiting = true;
  bool connected = false;

  @override
  void initState() {
    super.initState();
    connect();
  }

  // handle connect
  void connect() {
    chanel = WebSocketChannel.connect(uri);
    subs = chanel.stream.listen(
      _socketMessage,
      onDone: _disconnect,
      onError: (e, st) {
        log("Socket Connection Error", error: e, stackTrace: st);
        _disconnect();
      },
    );
  }

  void _socketMessage(dynamic event) {
    final msg = GameMessage.fromJson(jsonDecode(event));

    switch (msg.type){

      case MessageType.waiting:
        setState(() => waiting = true);
        break;

      case MessageType.gameStart:
        setState(() {
          waiting = false;
          mySide = msg.color == "white" ? Side.white : Side.black;
        });
        break;

      case MessageType.move:
        _applyServerMove(msg.move);
        break;

      default:
        Fluttertoast.showToast(msg: 'Socket error');
    }
  }
  // sync moves from server/ other player's move
  void _applyServerMove(String? uci){
    if(uci == null) return;
    final move = NormalMove.fromUci(uci);

    setState(() {
      position = position.playUnchecked(move);
      lastMove = move;
      fen = position.fen;
      validMoves = makeLegalMoves(position);
    });
    _checkGameState();
  }

  // checking game state on every move (e.g: checkmate, draw, game over etc)
  void _checkGameState() {
    if (position.isCheckmate) {
      Fluttertoast.showToast(
        msg: position.turn == Side.white
            ? 'Black wins by checkmate'
            : 'White wins by checkmate',
      );
    } else if (position.isStalemate) {
      Fluttertoast.showToast(msg: 'Draw by stalemate');
    } else if (position.isInsufficientMaterial) {
      Fluttertoast.showToast(msg: 'Draw by insufficient material');
    }else if (position.isGameOver) {
      Fluttertoast.showToast(msg: 'Game over');
    }
  }

  // handle disconnect
  void _disconnect() {
    if (!mounted) return;
    Fluttertoast.showToast(msg: 'Disconnected');
    Navigator.pop(context);
  }

  // local moves/ your moves push them to server
  void _localMove(NormalMove move, {bool? isDrop}){
    if(waiting) return;
    if (position.turn != mySide) return;
    chanel.sink.add(move.uci);
  }

  // promotion moves
  void _onPromotionSelection(Role? role) {
    if (role == null) {
      _onPromotionCancel();
    } else if (promotionMove != null) {
      _localMove(promotionMove!.withPromotion(role));
    }
  }

  void _onPromotionCancel() {
    setState(() {
      promotionMove = null;
    });
  }

  @override
  void dispose(){
    chanel.sink.close();
    subs?.cancel();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1C1A17),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "My Chess",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _playerHeader(
                  highlight: position.turn != mySide,
                  label: "Opponent",
                  captured: CapturedPiecesRow(
                    isRotate: false,
                    position: position,
                    side: mySide == Side.white ? Side.black : Side.white,
                    pieceAssets: pieceSet.assets,
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: Center(
                    child: Chessboard(
                      size: Get.width * 0.95,
                      orientation: mySide,
                      fen: fen,
                      game: GameData(
                        playerSide: mySide == Side.white
                            ? PlayerSide.white
                            : PlayerSide.black,
                        sideToMove: position.turn,
                        validMoves: validMoves,
                        promotionMove: promotionMove,
                        onMove: _localMove,
                        onPromotionSelection: _onPromotionSelection,
                      ),
                      settings: ChessboardSettings(
                        pieceAssets: pieceSet.assets,
                        borderRadius: BorderRadius.circular(24),
                        border: BoardBorder(
                          width: 14,
                          color: Colors.brown.shade800,
                        ),
                        animationDuration:
                        const Duration(milliseconds: 200),
                        dragFeedbackScale: 1.4,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                _playerHeader(
                  label: "You",
                  captured: CapturedPiecesRow(
                    isRotate: false,
                    position: position,
                    side: mySide,
                    pieceAssets: pieceSet.assets,
                  ),
                  highlight: position.turn == mySide,
                ),
              ],
            ),
          ),

          // Waiting overlay
          if (waiting)
            Container(
              color: Colors.black.withOpacity(0.65),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(strokeWidth: 3),
                    SizedBox(height: 12),
                    Text(
                      "Waiting for another player…",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _playerHeader({
    required String label,
    required Widget captured,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: highlight ? Get.theme.primaryColor : Colors.white
            )
          ),
          const SizedBox(width: 12),
          Expanded(child: captured),
        ],
      ),
    );
  }


}
