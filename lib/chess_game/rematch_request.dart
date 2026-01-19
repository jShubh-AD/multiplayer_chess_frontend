import 'package:flutter/material.dart';
import 'dart:async';

class RematchRequestSheet {
  static Timer? _countdownTimer;
  static ValueNotifier<int>? _countdown;

  static void show(
      BuildContext context, {
        required VoidCallback onJoinNow,
        required VoidCallback onDecline,
        int autoJoinSeconds = 10,
      }) {
    _countdown = ValueNotifier<int>(autoJoinSeconds);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _RematchRequestContent(
        countdown: _countdown!,
        onJoinNow: () {
          _cancelTimer();
          onJoinNow();
        },
        onDecline: () {
          _cancelTimer();
          onDecline();
        },
      ),
    ).whenComplete(() {
      _cancelTimer();
    });

    // Start countdown
    _startCountdown(context, onJoinNow);
  }

  static void _startCountdown(BuildContext context, VoidCallback onJoinNow) {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown!.value > 0) {
        _countdown!.value--;
      } else {
        timer.cancel();
        if (context.mounted) {
          Navigator.pop(context);
          onJoinNow();
        }
      }
    });
  }

  static void _cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdown?.dispose();
    _countdown = null;
  }
}

class _RematchRequestContent extends StatelessWidget {
  final ValueNotifier<int> countdown;
  final VoidCallback onJoinNow;
  final VoidCallback onDecline;

  const _RematchRequestContent({
    required this.countdown,
    required this.onJoinNow,
    required this.onDecline,
  });

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
              color: const Color(0xFFFF9D4A).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.refresh_rounded,
              size: 40,
              color: Color(0xFFFF9D4A),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Rematch Request',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1A17),
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Opponent wants a rematch',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF1C1A17).withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),

          // Countdown
          ValueListenableBuilder<int>(
            valueListenable: countdown,
            builder: (context, value, child) {
              return Text(
                'Auto joining in $value seconds',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFFFF9D4A).withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Join Now Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (){
                Navigator.pop(context);
                onJoinNow();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD18B47),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Join Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Decline Text Button
          TextButton(
            onPressed: onDecline,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1C1A17).withOpacity(0.6),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Decline Request',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}