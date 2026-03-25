import 'package:flutter/foundation.dart';

class Config {
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return "http://localhost:5000/api";
      }
      return "${Uri.base.origin}/api";
    }
    // For mobile, default to localhost (use 10.0.2.2 for Android emulator if needed)
    return "http://localhost:5000/api";
  }
}
