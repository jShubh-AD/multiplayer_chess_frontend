import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:chess_app/chess_game/game_end_sheet.dart';
import 'package:chess_app/chess_game/landing_page.dart';
import 'package:chess_app/chess_game/rematch_request.dart';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' hide MessageType;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';
import '../core/voice_service.dart';
import '../home/message_model.dart';
import 'capture_pieces.dart';

class OnlineGame extends StatefulWidget {
  const OnlineGame({super.key});

  @override
  State<OnlineGame> createState() => _OnlineGameState();
}

class _OnlineGameState extends State<OnlineGame> {


  // webrtc variables
  VoiceService? voice;
  bool voiceStarted = false;

  bool micMuted = false;
  bool speakerOff = false;




  // socket
  late WebSocketChannel chanel;
  StreamSubscription? subs;
  final uri = Uri.parse("wss://my-chess-pp9f.onrender.com/ws");
  // final uri = Uri.parse("ws://cljmb8ss-8000.inc1.devtunnels.ms/ws");

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

    final data = jsonDecode(event);

    // Handle WebRTC first
    if (data['type'] == 'offer') {
      voice?.onOffer(data['sdp']);
      return;
    }

    if (data['type'] == 'answer') {
      voice?.onAnswer(data['sdp']);
      return;
    }

    if (data['type'] == 'ice' && data['candidate'] != null) {
      voice?.onIce(Map.from(data['candidate']));
      return;
    }

    final msg = GameMessage.fromJson(data);

    switch (msg.type){

      case MessageType.waiting:
        setState(() => waiting = true);
        break;

      case MessageType.gameStart:
        setState(() {
          waiting = false;
          position = Chess.initial;
          fen = kInitialBoardFEN;
          validMoves = makeLegalMoves(Chess.initial);
          promotionMove = null;
          preMove = null;
          lastMove = null;
          lastPos = null;
          mySide = msg.color == "white" ? Side.white : Side.black;
          _startVoice();
        });
        break;

      case MessageType.move:
        _applyServerMove(msg.move);
        break;

      case MessageType.rematchRequest:
      // show bottom sheet and ask for rematch
      Get.back();
      RematchRequestSheet.show(
          context,
          onJoinNow: (){
            chanel.sink.add(jsonEncode({
              "type":MessageType.rematchAccept.value,
            }));
          },
          onDecline: () => Get.offAll(() => const LandingPage())
      );
      break;

      case MessageType.rematchAccept:
        // rematch accepted start new game
        Fluttertoast.showToast(msg: "Get ready for rematch");
        Get.back(closeOverlays: true);

        setState(() {
          waiting = false;
          position = Chess.initial;
          fen = kInitialBoardFEN;
          validMoves = makeLegalMoves(Chess.initial);
          promotionMove = null;
          preMove = null;
          lastMove = null;
          lastPos = null;
          mySide = msg.color == "white" ? Side.white : Side.black;
        });
        break;

      case MessageType.disconnect:
        Fluttertoast.showToast(msg: msg.message ?? "Please find a new opponent");
        Get.offAll(() => const LandingPage());
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
      GameEndBottomSheet.show(
        context,
        isCheckmate: true,
        isDraw: false,
        winner: position.turn == Side.white ? 'Black' : 'White',
        onPlayAgain: _playAgain,
        onFindAnotherPlayer: _findAnotherPlayer,
      );
    } else if (position.isStalemate) {
      GameEndBottomSheet.show(
        context,
        isCheckmate: false,
        isDraw: true,
        drawReason: 'Stalemate',
        onPlayAgain: _playAgain,
        onFindAnotherPlayer: _findAnotherPlayer,
      );
    } else if (position.isInsufficientMaterial) {
      GameEndBottomSheet.show(
        context,
        isCheckmate: false,
        isDraw: true,
        drawReason: 'Insufficient Material',
        onPlayAgain: _playAgain,
        onFindAnotherPlayer: _findAnotherPlayer,
      );
    } else if (position.isGameOver) {
      GameEndBottomSheet.show(
        context,
        isCheckmate: false,
        isDraw: true,
        drawReason: 'Game Over',
        onPlayAgain: _playAgain,
        onFindAnotherPlayer: _findAnotherPlayer,
      );
    }
  }


  void _findAnotherPlayer(){
    Get.back();
    chanel.sink.add(jsonEncode({
      "type":MessageType.challenge.value,
      "message":"Player has left the game"
    }));
  }

  void _playAgain(){
    chanel.sink.add(jsonEncode({
      "type":MessageType.rematchRequest.value,
    }));
  }

  // handle disconnect
  void _disconnect() {
    if (!mounted) return;
  }

  // local moves/ your moves push them to server
  void _localMove(NormalMove move, {bool? isDrop}){
    if(waiting) return;
    if (position.turn != mySide) return;
    chanel.sink.add(jsonEncode({
      "type": MessageType.move.value,
      "move": move.uci,
    }));
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
    voice?.dispose();
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
                Row(
                  children: [
                    Expanded(
                      flex:1,
                      child: _playerHeader(
                        turnText: "Their turn",
                        highlight: position.turn != mySide,
                        label: "Opponent",
                      ),
                    ),
                    IconButton(onPressed: (){
                      setState(() => speakerOff = !speakerOff);
                      speaker(!speakerOff);
                    },
                        icon: Icon(
                          speakerOff
                              ? Icons.volume_off
                              : Icons.volume_up,
                          color: Colors.white,
                        )
                    ),
                    IconButton(
                        onPressed: (){
                          setState(() => micMuted = !micMuted);
                          voice?.mute(micMuted);
                          },
                        icon: Icon(
                          micMuted
                              ? Icons.mic_off
                              : Icons.mic,
                      color: Colors.white,
                    )
                    )
                  ],
                ),

                const SizedBox(height: 16),
                CapturedPiecesRow(
                  isRotate: false,
                  position: position,
                  side: mySide,
                  pieceAssets: pieceSet.assets,
                ),

                Expanded(
                  child: Center(
                    child: Chessboard(
                      lastMove: lastMove,
                      size: Get.width * 1,
                      orientation: mySide,
                      fen: fen,
                      game: GameData(
                        isCheck: position.isCheck,
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
                        dragTargetKind: DragTargetKind.square,
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

                CapturedPiecesRow(
                  isRotate: false,
                  position: position,
                  side: mySide == Side.white ? Side.black : Side.white,
                  pieceAssets: pieceSet.assets,
                ),

                const SizedBox(height: 16),

                _playerHeader(
                  turnText: "Your turn",
                  label: "You",
                  highlight: position.turn == mySide,
                ),
              ],
            ),
          ),

          // Waiting overlay
          if (waiting)
            Container(
              color: Colors.black.withOpacity(0.65),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(strokeWidth: 3),
                    const SizedBox(height: 12),
                    Text(
                      "Waiting for another player…",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16
                      ),
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
    required String turnText,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlight ? Get.theme.primaryColor : Colors.grey
              )
            ),
            child: Icon(Icons.person),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: highlight ? Get.theme.primaryColor : Colors.white
                )
              ),
              Text(
                  turnText,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: highlight ? Get.theme.primaryColor : Colors.grey
                  )
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future _requestMic() async {
    await Permission.microphone.request();
  }

  void speaker(bool on) {
    Helper.setSpeakerphoneOn(on);
  }


  Future _startVoice() async {
    if (voiceStarted) return;

    _requestMic();

    voice = VoiceService(chanel);
    await voice?.init();

    voiceStarted = true;

    if (mySide == Side.white) {
      await voice?.start();
    }
  }

}
