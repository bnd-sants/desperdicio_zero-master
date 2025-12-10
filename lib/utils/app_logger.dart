import 'dart:developer' as developer;

class AppLogger {
  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? 'AppLogger',
      level: 800, // INFO level
    );
  }

  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? 'AppLogger',
      error: error,
      stackTrace: stackTrace,
      level: 1200, // ERROR level
    );
  }

  static void debug(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? 'AppLogger',
      level: 700, // DEBUG level
    );
  }
}
