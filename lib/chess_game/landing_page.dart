import 'dart:async';
import 'dart:math';

import 'package:chess_app/chess_game/local_game.dart';
import 'package:chess_app/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:fast_immutable_collections/src/imap/imap.dart';


class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  Position position = Chess.initial;
  NormalMove? lastMove;
  String fen = kInitialBoardFEN;
  ValidMoves validMoves = makeLegalMoves(Chess.initial);
  NormalMove? promotionMove;
  Position? lastPos;
  NormalMove? preMove;
  PieceSet pieceSet = PieceSet.gioco;

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

  void _onUserMoveAgainstBot(NormalMove move, {isDrop}) async {
    lastPos = position;
    if (isPromotionPawnMove(move)) {
      setState(() {
        promotionMove = move;
      });
    } else {
      setState(() {
        position = position.playUnchecked(move);
        lastMove = move;
        fen = position.fen;
        validMoves = IMap(const {});
        promotionMove = null;
      });
      await _playBlackMove();
      _tryPlayPremove();

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
  }

  void _tryPlayPremove() {
    if (preMove != null) {
      Timer.run(() {
        _playMove(preMove!, isPremove: true);
      });
    }
  }

  Future<void> _playBlackMove() async {
    Future.delayed(const Duration(milliseconds: 100)).then((value) {
      setState(() {});
    });
    if (position.isGameOver) return;

    final random = Random();
    await Future.delayed(Duration(milliseconds: random.nextInt(1000) + 500));
    final allMoves = [
      for (final entry in position.legalMoves.entries)
        for (final dest in entry.value.squares)
          NormalMove(from: entry.key, to: dest)
    ];
    if (allMoves.isNotEmpty) {
      NormalMove mv = (allMoves..shuffle()).first;
      // Auto promote to a random non-pawn role
      if (isPromotionPawnMove(mv)) {
        final potentialRoles =
        Role.values.where((role) => role != Role.pawn).toList();
        final role = potentialRoles[random.nextInt(potentialRoles.length)];
        mv = mv.withPromotion(role);
      }

      setState(() {
        position = position.playUnchecked(mv);
        lastMove = NormalMove(from: mv.from, to: mv.to, promotion: mv.promotion);
        fen = position.fen;
        validMoves = makeLegalMoves(position);
      });
      lastPos = position;
    }
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
    } else if (position.isLegal(move)) {
      setState(() {
        position = position.playUnchecked(move);
        lastMove = move;
        fen = position.fen;
        validMoves = makeLegalMoves(position);
        promotionMove = null;
        if (isPremove == true) {
          preMove = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // refresh game
          FloatingActionButton(
              onPressed: () => setState(() {
                position = Chess.initial;
                fen = position.fen;
                validMoves = makeLegalMoves(position);
                lastMove = null;
                lastPos = null;
              }),
              child:Icon(Icons.refresh)
          ),
          const SizedBox(height: 10),
          // undo move
          FloatingActionButton(
              onPressed: lastPos != null
                  ? () => setState(() {
                    position = lastPos!;
                    fen = position.fen;
                    validMoves = makeLegalMoves(position);
                    lastMove = null;
                    lastPos = null;
                  }) : null,
              child:Icon(Icons.undo)
          ),
        ],
      ),
      appBar: AppBar(
          title: Text(
              'My Chess',
              style: Get.textTheme.titleLarge
          )
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // chess board
          Chessboard(
            size: Get.width*1,
            fen: fen,
            lastMove: lastMove,
            orientation: Side.white,
            game: GameData(
              isCheck: position.isCheck,
              playerSide: PlayerSide.both, // FREE PLAY
              validMoves: validMoves,
              sideToMove: position.turn,
              onMove: _onUserMoveAgainstBot,
              promotionMove: promotionMove,
              onPromotionSelection: _onPromotionSelection,
            ),
            settings: ChessboardSettings(
              pieceAssets: pieceSet.assets,
              dragTargetKind: DragTargetKind.square,
              animationDuration: const Duration(milliseconds: 200),
              dragFeedbackScale:  1.5,
              borderRadius: BorderRadiusGeometry.circular(25),
              border:  BoardBorder(width: 16, color: Colors.brown.shade800)
            ),
          ),
          SizedBox(height: Get.height*0.1),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Get.to(()=> LocalGame(playMode: PlayMode.offline));
                  },
                  child: Text(
                    'Offline',
                    style: Get.textTheme.titleMedium,
                  ),
                ),

                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Fluttertoast.showToast(msg: "Will be added soon.");
                  },
                  child: Text(
                    'Multiplayer',
                    style: Get.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
