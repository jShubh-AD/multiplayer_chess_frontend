import 'package:flutter/material.dart';
import 'dart:async';

class GameEndBottomSheet extends StatefulWidget {
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
  State<GameEndBottomSheet> createState() => _GameEndBottomSheetState();

  // Static method to show the bottom sheet easily
  static void show(
      BuildContext context, {
        required bool isCheckmate,
        required bool isDraw,
        String? winner,
        String? drawReason,
        bool isWaiting = false,
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

class _GameEndBottomSheetState extends State<GameEndBottomSheet> {
  Timer? _countdownTimer;
  int _remainingSeconds = 10;
  bool _isWaiting = false;

  @override
  void initState() {
    super.initState();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _handlePlayAgain() {
    setState(() {
      _isWaiting = true;
    });
    _startCountdown(); // Start the countdown
    widget.onPlayAgain(); // Call the callback to send WebSocket message
  }

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
              color: widget.isCheckmate
                  ? const Color(0xFFFF9D4A).withOpacity(0.15)
                  : const Color(0xFFB58863).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isCheckmate
                  ? Icons.emoji_events_rounded
                  : Icons.handshake_rounded,
              size: 40,
              color: widget.isCheckmate
                  ? const Color(0xFFFF9D4A)
                  : const Color(0xFFB58863),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            widget.isCheckmate ? 'Checkmate!' : 'Draw!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1A17),
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            widget.isCheckmate
                ? '${widget.winner} wins by checkmate'
                : 'Game drawn by ${widget.drawReason}',
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
              onPressed: _isWaiting ? null : _handlePlayAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD18B47),
                foregroundColor: Colors.black,
                disabledBackgroundColor:
                const Color(0xFFD18B47).withOpacity(0.5),
                disabledForegroundColor: Colors.black.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isWaiting
                    ? 'Waiting for opponent ($_remainingSeconds s)'
                    : 'Rematch',
                style: const TextStyle(
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
              onPressed: widget.onFindAnotherPlayer,
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
}