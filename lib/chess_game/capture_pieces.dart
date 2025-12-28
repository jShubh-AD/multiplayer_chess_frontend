import 'package:flutter/material.dart';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:get/get.dart';

class CapturedPiecesRow extends StatelessWidget {
  final Position position;
  final Side side;
  final bool isRotate;
  final PieceAssets pieceAssets;

  const CapturedPiecesRow({
    super.key,
    required this.isRotate,
    required this.position,
    required this.side,
    required this.pieceAssets,
  });

  @override
  Widget build(BuildContext context) {
    final captured = _getCaptured();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.start,
      children: captured.entries.expand((e) {
        return List.generate(
          e.value,
              (_) => RotatedBox(
                quarterTurns: isRotate ? 2 : 0,
                child: Image(
                  image: pieceAssets[pieceKind(e.key, side)]!,
                  width: Get.width*0.12,
                ),
              ),
        );
      }).toList(),
    );
  }

  PieceKind pieceKind(Role role, Side side) {
    return PieceKind.values.firstWhere(
          (k) => k.role == role && k.side == side,
    );
  }


  Map<Role, int> _getCaptured() {
    const initial = {
      Role.pawn: 8,
      Role.rook: 2,
      Role.knight: 2,
      Role.bishop: 2,
      Role.queen: 1,
      Role.king: 1,
    };

    final current = {for (final r in Role.values) r: 0};

    for (final sq in Square.values) {
      final piece = position.board.pieceAt(sq);
      if (piece != null && piece.color == side) {
        current[piece.role] = current[piece.role]! + 1;
      }
    }

    return {
      for (final role in initial.keys)
        role: initial[role]! - current[role]!
    };
  }
}
