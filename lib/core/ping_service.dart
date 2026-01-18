import 'dart:async';
import 'package:dio/dio.dart';

class PingService {
  static Timer? _timer;
  static final Dio dio = Dio();

  static Future<void> start() async {
    await _callApi(); // call on app start

    _timer = Timer.periodic(
      const Duration(minutes: 5), (_) => _callApi(),
    );
  }

  static Future<void> _callApi() async {
    try {
      await dio.get(
        "https://my-chess-pp9f.onrender.com/",
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

    } catch (_) {
      // silently ignore
    }
  }

  static void stop() {
    _timer?.cancel();
  }
}
