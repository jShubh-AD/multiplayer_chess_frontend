import 'package:flutter/material.dart';

class GameEndBottomSheet extends StatelessWidget {
  final bool isCheckmate;
  final bool isDraw;
  final String? winner;
  final String? drawReason;
  final VoidCallback onPlayAgain;
  final VoidCallback onFindAnotherPlayer;

  const GameEndBottomSheet({
    Key? key,
    this.isCheckmate = false,
    this.isDraw = false,
    this.winner,
    this.drawReason,
    required this.onPlayAgain,
    required this.onFindAnotherPlayer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F2ED),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFB58863).withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isCheckmate
                  ? const Color(0xFFFF9D4A).withOpacity(0.15)
                  : const Color(0xFFB58863).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCheckmate ? Icons.emoji_events_rounded : Icons.handshake_rounded,
              size: 40,
              color: isCheckmate ? const Color(0xFFFF9D4A) : const Color(0xFFB58863),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            isCheckmate ? 'Checkmate!' : 'Draw!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1A17),
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            isCheckmate
                ? '$winner wins by checkmate'
                : 'Game drawn by $drawReason',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF1C1A17).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),

          // Play Again Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onPlayAgain();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD18B47),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Rematch',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Find Another Player Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                onFindAnotherPlayer();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1C1A17),
                side: const BorderSide(
                  color: Color(0xFFB58863),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Find Another Player',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Static method to show the bottom sheet easily
  static void show(
      BuildContext context, {
        required bool isCheckmate,
        required bool isDraw,
        String? winner,
        String? drawReason,
        required VoidCallback onPlayAgain,
        required VoidCallback onFindAnotherPlayer,
      }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: true,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (context) => GameEndBottomSheet(
        isCheckmate: isCheckmate,
        isDraw: isDraw,
        winner: winner,
        drawReason: drawReason,
        onPlayAgain: onPlayAgain,
        onFindAnotherPlayer: onFindAnotherPlayer,
      ),
    );
  }
}