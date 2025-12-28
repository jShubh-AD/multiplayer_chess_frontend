import 'package:chess_app/core/constants.dart';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import 'capture_pieces.dart';

class LocalGame extends StatefulWidget {
  final PlayMode playMode;

  const LocalGame({super.key, required this.playMode});

  @override
  State<LocalGame> createState() => _LocalGameState();
}

class _LocalGameState extends State<LocalGame> {
  Position position = Chess.initial;
  String fen = kInitialBoardFEN;
  ValidMoves validMoves = makeLegalMoves(Chess.initial);
  NormalMove? promotionMove;
  NormalMove? lastMove;
  Position? lastPos;

  PieceSet pieceSet = PieceSet.gioco;

  late PieceOrientationBehavior pieceOrientationBehavior =
      widget.playMode == PlayMode.offline
      ? PieceOrientationBehavior.opponentUpsideDown
      : PieceOrientationBehavior.facingUser;

  void _onPromotionSelection(Role? role) {
    if (role == null) {
      _onPromotionCancel();
    } else if (promotionMove != null) {
      _playMove(promotionMove!.withPromotion(role));
    }
  }

  void _onPromotionCancel() {
    setState(() {
      promotionMove = null;
    });
  }

  bool isPromotionPawnMove(NormalMove move) {
    return move.promotion == null &&
        position.board.roleAt(move.from) == Role.pawn &&
        ((move.to.rank == Rank.first && position.turn == Side.black) ||
            (move.to.rank == Rank.eighth && position.turn == Side.white));
  }

  void _playMove(NormalMove move, {bool? isDrop, bool? isPremove}) {
    lastPos = position;
    if (isPromotionPawnMove(move)) {
      setState(() {
        promotionMove = move;
      });
    }
    else if (position.isLegal(move)) {
      setState(() {
        position = position.playUnchecked(move);
        lastMove = move;
        fen = position.fen;
        validMoves = makeLegalMoves(position);
        promotionMove = null;
        if (isPremove == true) {
          // preMove = null;
        }
      });
    }
    // 🔥 GAME STATE CHECKS (AFTER MOVE)
    if (position.isCheckmate) {
      Fluttertoast.showToast(
        msg: position.turn == Side.white
            ? "Black wins by checkmate"
            : "White wins by checkmate",
      );
    } else if (position.isStalemate) {
      Fluttertoast.showToast(msg: "Draw by stalemate");
    } else if (position.isInsufficientMaterial) {
      Fluttertoast.showToast(msg: "Draw by insufficient material");
    } else if (position.isGameOver) {
      Fluttertoast.showToast(msg: "Game over");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
      FloatingActionButton(
        onPressed: () => setState(() {
          position = Chess.initial;
          fen = position.fen;
          validMoves = makeLegalMoves(position);
          lastMove = null;
          lastPos = null;
        }),
        child: Icon(Icons.refresh),
      ),
      appBar: AppBar(title: Text('My Chess', style: Get.textTheme.titleLarge)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CapturedPiecesRow(
            position: position,
            side: Side.black,
            isRotate: pieceOrientationBehavior == PieceOrientationBehavior.opponentUpsideDown
                ? true
                : false,
            pieceAssets: PieceSet.gioco.assets,
          ),

          SizedBox(height: 10),
          Chessboard(
            size: Get.width * 1,
            fen: fen,
            lastMove: lastMove,
            orientation: Side.white,
            game: GameData(
              isCheck: position.isCheck,
              playerSide: PlayerSide.both,
              // FREE PLAY
              validMoves: validMoves,
              sideToMove: position.turn,
              onMove: _playMove,
              promotionMove: promotionMove,
              onPromotionSelection: _onPromotionSelection,
            ),
            settings: ChessboardSettings(
              pieceAssets: pieceSet.assets,
              pieceOrientationBehavior: pieceOrientationBehavior,
              dragTargetKind: DragTargetKind.square,
              animationDuration: const Duration(milliseconds: 200),
              dragFeedbackScale: 1.3,
              borderRadius: BorderRadiusGeometry.circular(25),
              border: BoardBorder(width: 16, color: Colors.brown.shade800),
            ),
          ),

          SizedBox(height: 10),

          CapturedPiecesRow(
            position: position,
            side: Side.white,
            isRotate: pieceOrientationBehavior == PieceOrientationBehavior.opponentUpsideDown
                ? false
                : true,
            pieceAssets: pieceSet.assets,
          ),
        ],
      ),
    );
  }
}
